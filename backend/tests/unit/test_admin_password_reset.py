import asyncio
import unittest
from unittest.mock import AsyncMock, Mock, patch
from uuid import uuid4

from passlib.context import CryptContext
from pydantic import SecretStr, ValidationError

from app.core.rbac import require_super_admin
from app.core.security import create_access_token, create_refresh_token, decode_token, hash_password, verify_password
from app.models.user import User
from app.routers.rbac import reset_user_password
from app.schemas.rbac import AdminPasswordResetRequest
from fastapi import HTTPException


def _run(coro):
    try:
        previous = asyncio.get_event_loop()
    except RuntimeError:
        previous = None
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()
        if previous is not None and not previous.is_closed():
            asyncio.set_event_loop(previous)
        else:
            asyncio.set_event_loop(asyncio.new_event_loop())


class AdminPasswordResetSchemaTests(unittest.TestCase):
    def test_accepts_a_strong_enough_password(self):
        request = AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!"))
        self.assertEqual(request.password.get_secret_value(), "Testing-password-2026!")

    def test_accepts_max_length_and_hashes_long_password_without_truncation(self):
        password = "A" * 128
        request = AdminPasswordResetRequest(password=SecretStr(password))
        hashed = hash_password(password)
        self.assertTrue(hashed.startswith("bcrypt-sha256$"))
        self.assertEqual(len(request.password.get_secret_value()), 128)
        self.assertTrue(verify_password(password, hashed))
        self.assertFalse(verify_password("B" * 128, hashed))
        with self.assertRaises(ValidationError):
            AdminPasswordResetRequest(password=SecretStr("A" * 129))

    def test_legacy_unmarked_hash_requires_password_reset(self):
        password = "A" * 128
        legacy_hash = CryptContext(schemes=["bcrypt"], deprecated="auto").hash(password)
        self.assertFalse(verify_password(password, legacy_hash))
        self.assertFalse(verify_password("A" * 72, legacy_hash))

    def test_rejects_a_short_password(self):
        with self.assertRaises(ValidationError):
            AdminPasswordResetRequest(password=SecretStr("short"))

    def test_token_session_version_claim_is_persisted(self):
        access = decode_token(create_access_token(str(uuid4()), session_version=3))
        refresh = decode_token(create_refresh_token(str(uuid4()), session_version=3))
        self.assertEqual(access["sv"], 3)
        self.assertEqual(refresh["sv"], 3)

    def test_super_admin_dependency_rejects_regular_user(self):
        regular_user = User(
            id=uuid4(), full_name="Regular User", email="regular@example.test",
            password_hash="admin-hash", is_active=True,
        )
        with self.assertRaises(HTTPException) as error:
            _run(require_super_admin()(regular_user))
        self.assertEqual(error.exception.status_code, 403)

    def test_non_super_admin_is_rejected(self):
        target = User(
            id=uuid4(),
            full_name="Target User",
            email="target@example.test",
            password_hash="old-hash",
            is_active=True,
        )
        admin = User(
            id=uuid4(),
            full_name="Regular User",
            email="regular@example.test",
            password_hash="admin-hash",
            is_active=True,
        )
        role_result = type("RoleResult", (), {"scalars": lambda self: type("ScalarResult", (), {"all": lambda self: ["compliance_officer"]})()})()
        db = type("FakeDB", (), {"execute": AsyncMock(return_value=role_result), "add": Mock(), "commit": AsyncMock()})()
        with self.assertRaises(HTTPException) as error:
            _run(reset_user_password(
                target.id,
                AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!")),
                db,
                admin,
            ))
        self.assertEqual(error.exception.status_code, 403)
        db.commit.assert_not_awaited()

    def test_reset_updates_hash_without_recording_plaintext(self):
        target = User(
            id=uuid4(),
            full_name="Target User",
            email="target@example.test",
            password_hash="old-hash",
            is_active=True,
        )
        admin = User(
            id=uuid4(),
            full_name="Admin User",
            email="admin@example.test",
            password_hash="admin-hash",
            is_active=True,
        )
        role_result = type("RoleResult", (), {"scalars": lambda self: type("ScalarResult", (), {"all": lambda self: ["super_admin"]})()})()
        target_result = type("TargetResult", (), {"scalar_one_or_none": lambda self: target})()
        version_result = type("VersionResult", (), {"scalar_one_or_none": lambda self: 1})()
        db = type("FakeDB", (), {
            "execute": AsyncMock(side_effect=[role_result, target_result, version_result]),
            "add": Mock(),
            "commit": AsyncMock(),
        })()
        with patch("app.routers.rbac.get_active_session_jtis", new=AsyncMock(return_value=[])), \
             patch("app.routers.rbac.deny_token", new=AsyncMock()), \
             patch("app.routers.rbac.remove_user_session", new=AsyncMock()):
            result = _run(reset_user_password(
                target.id,
                AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!")),
                db,
                admin,
            ))
        self.assertIsNone(result)
        self.assertTrue(verify_password("Testing-password-2026!", target.password_hash))
        self.assertFalse("Testing-password-2026!" in repr(db.add.call_args))
        db.commit.assert_awaited_once()
    def test_reset_invalidation_does_not_depend_on_redis(self):
        target = User(
            id=uuid4(), full_name="Target User", email="target@example.test",
            password_hash="old-hash", is_active=True,
        )
        admin = User(
            id=uuid4(), full_name="Admin User", email="admin@example.test",
            password_hash="admin-hash", is_active=True,
        )
        role_result = type("RoleResult", (), {"scalars": lambda self: type("ScalarResult", (), {"all": lambda self: ["super_admin"]})()})()
        target_result = type("TargetResult", (), {"scalar_one_or_none": lambda self: target})()
        version_result = type("VersionResult", (), {"scalar_one_or_none": lambda self: 1})()
        db = type("FakeDB", (), {
            "execute": AsyncMock(side_effect=[role_result, target_result, version_result]),
            "add": Mock(),
            "commit": AsyncMock(),
        })()
        with patch("app.routers.rbac.get_active_session_jtis", new=AsyncMock(side_effect=RuntimeError("redis unavailable"))):
            result = _run(reset_user_password(
                target.id,
                AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!")),
                db,
                admin,
            ))
        self.assertIsNone(result)
        self.assertTrue(verify_password("Testing-password-2026!", target.password_hash))
        self.assertEqual(target.session_version, 1)
        db.commit.assert_awaited_once()

    def test_reset_survives_partial_redis_cleanup_failure(self):
        target = User(
            id=uuid4(), full_name="Target User", email="target@example.test",
            password_hash="old-hash", is_active=True,
        )
        admin = User(
            id=uuid4(), full_name="Admin User", email="admin@example.test",
            password_hash="admin-hash", is_active=True,
        )
        role_result = type("RoleResult", (), {"scalars": lambda self: type("ScalarResult", (), {"all": lambda self: ["super_admin"]})()})()
        target_result = type("TargetResult", (), {"scalar_one_or_none": lambda self: target})()
        version_result = type("VersionResult", (), {"scalar_one_or_none": lambda self: 1})()
        db = type("FakeDB", (), {
            "execute": AsyncMock(side_effect=[role_result, target_result, version_result]),
            "add": Mock(),
            "commit": AsyncMock(),
        })()
        with patch("app.routers.rbac.get_active_session_jtis", new=AsyncMock(return_value=["jti-1", "jti-2"])), \
             patch("app.routers.rbac.deny_token", new=AsyncMock(side_effect=RuntimeError("redis unavailable"))), \
             patch("app.routers.rbac.remove_user_session", new=AsyncMock()):
            result = _run(reset_user_password(
                target.id,
                AdminPasswordResetRequest(password=SecretStr("Testing-password-2026!")),
                db,
                admin,
            ))
        self.assertIsNone(result)
        self.assertTrue(verify_password("Testing-password-2026!", target.password_hash))
        self.assertEqual(target.session_version, 1)
        db.commit.assert_awaited_once()


if __name__ == "__main__":
    unittest.main()
