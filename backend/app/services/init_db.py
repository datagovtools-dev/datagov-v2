import asyncio
import logging
import uuid
from datetime import date, datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.user import Role, User, UserProjectRole
from app.models.project import Project
from app.models.dsr import DataSharingRequest, DSRApproval, AIChecklistApproval, AIComplianceChecklist
from app.models.dpia import DPIARecord, DPIAApproval
from app.models.bapd import BAPDRecord, BAPDApproval, RetentionPolicy
from app.models.metadata import MetadataRecord

logger = logging.getLogger(__name__)

# `position` is the job title in the company (used e.g. for DSR sign-off), not the role in a project
TRIAL_USERS = [
    {"full_name": "Super Administrator", "email": "admin@governance.local", "role": "super_admin", "password": "Admin1234!", "position": "Chief Data & AI Officer"},
    {"full_name": "Eko Prasetyo", "email": "eko.prasetyo@company.com", "role": "regular_user", "password": "User1234!", "position": "Data Analyst"},
    {"full_name": "Budi Santoso", "email": "budi.santoso@company.com", "role": "compliance_officer", "password": "User1234!", "position": "Data Compliance Manager"},
    {"full_name": "Ahmad Fauzi", "email": "ahmad.fauzi@company.com", "role": "project_manager", "password": "User1234!", "position": "Delivery Manager"},
    {"full_name": "Dewi Rahayu", "email": "dewi.rahayu@company.com", "role": "data_steward", "password": "User1234!", "position": "Head of Business Analytics"},
    {"full_name": "Anisa Putri", "email": "anisa.putri@company.com", "role": "data_owner", "password": "User1234!", "position": "Data Governance Manager"},
    {"full_name": "Fitri Handayani", "email": "fitri.handayani@company.com", "role": "compliance_officer", "password": "User1234!", "position": "Data Protection Officer (DPO)"},
    {"full_name": "Bagas Adi Nugraha", "email": "bagas.nugraha@company.com", "role": "project_manager", "password": "User1234!", "position": "Lead Project Manager"},
]

DEFAULT_ROLES = [
    ("super_admin", "Full access to all modules and settings"),
    ("data_governance_officer", "Manages governance policies and approvals"),
    ("compliance_officer", "Reviews and approves compliance-related items"),
    ("data_owner", "Owns datasets and approves DSRs and BAPDs"),
    ("data_steward", "Manages metadata and data quality for assigned domains"),
    ("dpo", "Data Protection Officer — reviews DPIAs"),
    ("auditor", "Read-only access to audit logs and reports"),
    ("regular_user", "Basic access for project members"),
    ("project_manager", "Project delivery and milestone approvals"),
    ("viewer", "Read-only access across platform"),
]


async def seed_initial_data_if_needed(db: AsyncSession) -> None:
    """Ensure database has all standard roles and trial users on startup."""
    # 1. Seed Roles
    role_map: dict[str, Role] = {}
    for role_name, desc in DEFAULT_ROLES:
        res = await db.execute(select(Role).where(Role.name == role_name))
        r = res.scalar_one_or_none()
        if not r:
            r = Role(name=role_name, description=desc)
            db.add(r)
            await db.flush()
        role_map[role_name] = r

    # 2. Seed Users
    user_map: dict[str, User] = {}
    for u in TRIAL_USERS:
        res = await db.execute(select(User).where(User.email == u["email"]))
        user = res.scalar_one_or_none()
        if not user:
            user = User(
                id=uuid.uuid4(),
                full_name=u["full_name"],
                email=u["email"],
                position=u.get("position"),
                password_hash=hash_password(u["password"]),
                is_active=True,
            )
            db.add(user)
            await db.flush()
            
            # Assign global role
            r = role_map.get(u["role"])
            if r:
                db.add(UserProjectRole(
                    user_id=user.id,
                    role_id=r.id,
                    project_id=None,
                    assigned_by=user.id,
                ))
        else:
            # Ensure password hash is valid
            user.password_hash = hash_password(u["password"])
            user.is_active = True
            user.position = u.get("position")
            
        user_map[u["email"]] = user

    # 3. Seed Sample Project PRJ-2026-001 if none exists
    proj_res = await db.execute(select(Project).where(Project.project_code == "PRJ-2026-001"))
    proj = proj_res.scalar_one_or_none()
    if not proj:
        admin_u = user_map.get("admin@governance.local")
        budi_u = user_map.get("budi.santoso@company.com")
        ahmad_u = user_map.get("ahmad.fauzi@company.com")
        dewi_u = user_map.get("dewi.rahayu@company.com")
        anisa_u = user_map.get("anisa.putri@company.com")
        bagas_u = user_map.get("bagas.nugraha@company.com")
        
        proj = Project(
            id=uuid.uuid4(),
            project_code="PRJ-2026-001",
            project_name="AI-Powered Customer Analytics Platform",
            customer_name="Telco Nusantara Group",
            project_category="AI / ML",
            project_year=2026,
            line_of_business="Enterprise Digital",
            use_case="Predictive customer churn and cross-sell recommendation engine",
            start_date=date(2026, 1, 1),
            end_date=date(2026, 12, 31),
            is_monetized=True,
            created_by=admin_u.id if admin_u else uuid.uuid4(),
            pic_data_compliance_id=budi_u.id if budi_u else None,
            delivery_manager_id=ahmad_u.id if ahmad_u else None,
            project_manager_id=bagas_u.id if bagas_u else None,
            sme_id=dewi_u.id if dewi_u else None,
            dgo_id=anisa_u.id if anisa_u else None,
        )
        db.add(proj)
        await db.flush()

    await db.commit()
