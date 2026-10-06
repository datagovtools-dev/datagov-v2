from typing import Annotated, Any
from functools import lru_cache

from fastapi import Depends, HTTPException, status

from app.core.deps import CurrentUser
from app.models.user import User

# Maximum concurrent sessions per role (0 / absent = unlimited)
ROLE_SESSION_LIMITS: dict[str, int] = {
    "viewer": 2,
}

# Permission registry: role -> set of allowed actions
# Format: "<module>:<action>"
_ROLE_PERMISSIONS: dict[str, set[str]] = {
    "super_admin": {"*"},  # wildcard — all permissions
    "compliance_officer": {
        # Full operational access across every module — no system/user-management access
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:create", "dq:approve",
        "user:read",
        "audit:read",
    },
    "dpo": {
        # Data Protection Officer — same as compliance_officer
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:create", "dq:approve",
        "user:read",
        "audit:read",
    },
    "data_governance_officer": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve", "dsr:reject",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update", "ropa:approve",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:run", "dq:create",
        "user:read",
        "audit:read",
    },
    "project_manager": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve", "dsr:reject",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read",
        "user:read",
        "audit:read",
    },
    "data_steward": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve", "dsr:reject",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read", "dq:run", "dq:create",
        "user:read",
        "audit:read",
    },
    "data_owner": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update", "dsr:approve", "dsr:reject",
        "dpia:read", "dpia:create", "dpia:update", "dpia:approve",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update", "bapd:approve",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read",
        "user:read",
        "audit:read",
    },
    "requester": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update",
        "dpia:read", "dpia:create", "dpia:update",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read",
        "user:read",
    },
    "regular_user": {
        "project:read", "project:create", "project:update",
        "dsr:read", "dsr:create", "dsr:update",
        "dpia:read", "dpia:create", "dpia:update",
        "ropa:read", "ropa:create", "ropa:update",
        "bapd:read", "bapd:create", "bapd:update",
        "metadata:read", "metadata:create", "metadata:update",
        "dq:read",
        "user:read",
    },
    "auditor": {
        "audit:read",
        "dsr:read",
        "dpia:read",
        "ropa:read",
        "bapd:read",
        "metadata:read",
        "dq:read",
        "project:read",
        "user:read",
    },
    "viewer": {
        "dsr:read",
        "dsr:create",
        "dpia:read",
        "ropa:read",
        "bapd:read",
        "metadata:read",
        "dq:read",
        "project:read",
        "user:read",
    },
}


def get_effective_permissions_for_role(role_name: str, custom_permissions: list[str] | None = None) -> set[str]:
    """Get the set of active permissions for a role, using custom permissions if defined, else defaults."""
    if role_name == "super_admin":
        return {"*"}
    if custom_permissions is not None:
        return set(custom_permissions)
    return set(_ROLE_PERMISSIONS.get(role_name, set()))


def _role_has_permission(role: str, permission: str, custom_permissions: list[str] | None = None) -> bool:
    if role == "super_admin":
        return True
    allowed = get_effective_permissions_for_role(role, custom_permissions)
    return "*" in allowed or permission in allowed


def _user_has_permission(user: User, permission: str) -> bool:
    """Check roles stored on the user object (loaded via joined eager load)."""
    if getattr(user, "is_super_admin", False):
        return True
    for upr in getattr(user, "project_roles", []):
        if upr.revoked_at is None and upr.role:
            role_obj = upr.role
            r_name = getattr(role_obj, "name", None)
            c_perms = getattr(role_obj, "permissions", None)
            if r_name == "super_admin":
                return True
            if r_name and _role_has_permission(r_name, permission, c_perms):
                return True
    return False


def require_permission(permission: str):
    """FastAPI dependency factory. Usage: Depends(require_permission('dsr:approve'))"""
    async def _check(current_user: CurrentUser) -> User:
        if not _user_has_permission(current_user, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: '{permission}' required",
            )
        return current_user
    return _check


def require_any_permission(*permissions: str):
    """Pass if user has at least one of the given permissions."""
    async def _check(current_user: CurrentUser) -> User:
        for perm in permissions:
            if _user_has_permission(current_user, perm):
                return current_user
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Permission denied: one of {permissions} required",
        )
    return _check


def require_super_admin():
    """FastAPI dependency for operations restricted to the Super Administrator."""
    async def _check(current_user: CurrentUser) -> User:
        if not getattr(current_user, "is_super_admin", False):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Super Administrator permission required",
            )
        return current_user
    return _check


# ── Navigation Menus & Business Activities Taxonomy ───────────────────────────

MENU_DEFINITIONS = [
    {
        "id": "dashboard",
        "label": "Executive Dashboard",
        "href": "/dashboard",
        "group": "EXECUTIVE",
        "icon": "LayoutDashboard",
        "description": "Ringkasan metrik kepatuhan data, KPI governance, dan antrean persetujuan.",
        "required_permission": None,  # Accessible to all active users
    },
    {
        "id": "projects",
        "label": "Data Assets Catalog",
        "href": "/projects",
        "group": "DISCOVER",
        "icon": "FolderOpen",
        "description": "Katalog aset data, metadata pemilik, dan informasi proyek.",
        "required_permission": "project:read",
    },
    {
        "id": "metadata",
        "label": "Metadata Management",
        "href": "/metadata",
        "group": "DISCOVER",
        "icon": "Database",
        "description": "Kamus data, struktur skema, dan klasifikasi sensitivitas informasi.",
        "required_permission": "metadata:read",
    },
    {
        "id": "dsr",
        "label": "Data Sharing (DSR)",
        "href": "/dsr",
        "group": "GOVERN",
        "icon": "Share2",
        "description": "Manajemen permohonan berbagi data pihak internal dan eksternal.",
        "required_permission": "dsr:read",
    },
    {
        "id": "ai_checklist",
        "label": "AI/ML Checklist (AICK)",
        "href": "/ai-checklist",
        "group": "GOVERN",
        "icon": "Bot",
        "description": "Daftar uji kepatuhan etika, transparansi, dan mitigasi risiko AI/ML.",
        "required_permission": "dsr:read",
    },
    {
        "id": "dpia",
        "label": "Privacy Impact (DPIA)",
        "href": "/dpia",
        "group": "GOVERN",
        "icon": "ShieldCheck",
        "description": "Penilaian dampak privasi data pribadi dan analisis risiko mitigasi.",
        "required_permission": "dpia:read",
    },
    {
        "id": "ropa",
        "label": "ROPA Records",
        "href": "/ropa",
        "group": "GOVERN",
        "icon": "ClipboardList",
        "description": "Catatan Aktivitas Pemrosesan Data (Record of Processing Activities).",
        "required_permission": "ropa:read",
    },
    {
        "id": "dq",
        "label": "Data Quality Control",
        "href": "/dq",
        "group": "QUALITY",
        "icon": "BarChart2",
        "description": "Profiling kualitas data, rule scoring, dan deteksi anomali data.",
        "required_permission": "dq:read",
    },
    {
        "id": "bapd",
        "label": "Extermination (BAPD)",
        "href": "/bapd",
        "group": "CONTROL",
        "icon": "Trash2",
        "description": "Berita Acara Pemusnahan Data dan pencatatan masa retensi.",
        "required_permission": "bapd:read",
    },
    {
        "id": "audit",
        "label": "Audit Telemetry",
        "href": "/audit",
        "group": "CONTROL",
        "icon": "History",
        "description": "Jejak audit keamanan, pencatatan aktivitas, dan log pengguna.",
        "required_permission": "audit:read",
    },
    {
        "id": "settings_ai",
        "label": "AI Setup & Ollama",
        "href": "/settings/ai",
        "group": "SYSTEM",
        "icon": "Sparkles",
        "description": "Konfigurasi LLM lokal, endpoint Ollama, dan parameter AI.",
        "required_permission": "user:read",
    },
    {
        "id": "settings",
        "label": "Settings & Access",
        "href": "/settings",
        "group": "SYSTEM",
        "icon": "Settings",
        "description": "Manajemen pengguna, alokasi role RBAC, dan notifikasi sistem.",
        "required_permission": "user:read",
    },
]

ACTIVITY_DEFINITIONS = [
    # Discover
    {
        "id": "project_read",
        "name": "Lihat Katalog Aset Data",
        "group": "DISCOVER",
        "category": "read",
        "description": "Membuka dan melihat rincian katalog aset data dan informasi proyek.",
        "required_permission": "project:read",
    },
    {
        "id": "project_create",
        "name": "Daftarkan Aset Data Baru",
        "group": "DISCOVER",
        "category": "create",
        "description": "Menambahkan entri aset data / proyek baru ke dalam katalog.",
        "required_permission": "project:create",
    },
    {
        "id": "project_update",
        "name": "Ubah Rincian & PIC Proyek",
        "group": "DISCOVER",
        "category": "update",
        "description": "Memperbarui metadata proyek dan menugaskan data owner/stewards.",
        "required_permission": "project:update",
    },
    {
        "id": "metadata_create",
        "name": "Buat Kamus & Skema Metadata",
        "group": "DISCOVER",
        "category": "create",
        "description": "Mendefinisikan skema tabel, tipe data kolom, dan aturan klasifikasi data.",
        "required_permission": "metadata:create",
    },
    {
        "id": "metadata_update",
        "name": "Edit Tag & Kamus Metadata",
        "group": "DISCOVER",
        "category": "update",
        "description": "Memperbarui kamus data dan deskripsi metadata yang telah terdaftar.",
        "required_permission": "metadata:update",
    },

    # Govern
    {
        "id": "dsr_create",
        "name": "Buat Permohonan Data Sharing (DSR)",
        "group": "GOVERN",
        "category": "create",
        "description": "Membuat draf permohonan pembagian data dengan pihak ketiga.",
        "required_permission": "dsr:create",
    },
    {
        "id": "dsr_update",
        "name": "Edit Draf DSR & Isi AICK",
        "group": "GOVERN",
        "category": "update",
        "description": "Mengisi pertanyaan kepatuhan AI dan memperbarui rincian DSR.",
        "required_permission": "dsr:update",
    },
    {
        "id": "dsr_approve",
        "name": "Setujui Permohonan DSR & AICK",
        "group": "GOVERN",
        "category": "approve",
        "description": "Melakukan peninjauan dan persetujuan multi-level (PIC, DM, SME, Client).",
        "required_permission": "dsr:approve",
    },
    {
        "id": "dpia_create",
        "name": "Inisiasi Penilaian DPIA",
        "group": "GOVERN",
        "category": "create",
        "description": "Membuat dokumen penilaian dampak privasi dan identifikasi risiko.",
        "required_permission": "dpia:create",
    },
    {
        "id": "dpia_update",
        "name": "Edit Rencana Mitigasi DPIA",
        "group": "GOVERN",
        "category": "update",
        "description": "Memperbarui langkah mitigasi dan scoring risiko privasi.",
        "required_permission": "dpia:update",
    },
    {
        "id": "dpia_approve",
        "name": "Validasi & Setujui DPIA",
        "group": "GOVERN",
        "category": "approve",
        "description": "Menyetujui hasil evaluasi dampak privasi oleh DPO / Compliance Officer.",
        "required_permission": "dpia:approve",
    },
    {
        "id": "ropa_create",
        "name": "Catat Aktivitas ROPA Baru",
        "group": "GOVERN",
        "category": "create",
        "description": "Mendaftarkan alur pemrosesan data pribadi baru dalam ROPA.",
        "required_permission": "ropa:create",
    },
    {
        "id": "ropa_update",
        "name": "Perbarui Catatan ROPA",
        "group": "GOVERN",
        "category": "update",
        "description": "Memperbarui tujuan pemrosesan dan masa simpan data dalam ROPA.",
        "required_permission": "ropa:update",
    },

    # Quality
    {
        "id": "dq_create",
        "name": "Buat Rule Data Quality",
        "group": "QUALITY",
        "category": "create",
        "description": "Menyusun aturan kelengkapan, konsistensi, validitas, dan akurasi data.",
        "required_permission": "dq:create",
    },
    {
        "id": "dq_run",
        "name": "Jalankan Profiling DQ",
        "group": "QUALITY",
        "category": "run",
        "description": "Mengeksekusi engine profiling kualitas data pada dataset target.",
        "required_permission": "dq:run",
    },
    {
        "id": "dq_approve",
        "name": "Review & Setujui Skor DQ",
        "group": "QUALITY",
        "category": "approve",
        "description": "Meninjau temuan kualitas data dan mengonfirmasi hasil penilaian.",
        "required_permission": "dq:approve",
    },

    # Control
    {
        "id": "bapd_create",
        "name": "Inisiasi Berita Acara BAPD",
        "group": "CONTROL",
        "category": "create",
        "description": "Membuat dokumen permohonan pemusnahan dataset kadaluarsa.",
        "required_permission": "bapd:create",
    },
    {
        "id": "bapd_update",
        "name": "Edit Rincian Pemusnahan",
        "group": "CONTROL",
        "category": "update",
        "description": "Menyesuaikan parameter penghancuran data dan bukti pendukung.",
        "required_permission": "bapd:update",
    },
    {
        "id": "bapd_approve",
        "name": "Persetujuan Multi-Step BAPD",
        "group": "CONTROL",
        "category": "approve",
        "description": "Menyetujui dan memverifikasi sertifikat eksekusi pemusnahan data.",
        "required_permission": "bapd:approve",
    },
    {
        "id": "audit_read",
        "name": "Akses Jejak Audit Telemetri",
        "group": "CONTROL",
        "category": "read",
        "description": "Melihat dan mengunduh rekaman aktivitas keamanan sistem dan audit log.",
        "required_permission": "audit:read",
    },

    # System
    {
        "id": "user_manage",
        "name": "Kelola Pengguna & Alokasi Role",
        "group": "SYSTEM",
        "category": "admin",
        "description": "Menugaskan atau mencabut role akses pengguna pada platform.",
        "required_permission": "user:read",
    },
    {
        "id": "role_manage",
        "name": "Konfigurasi Role RBAC",
        "group": "SYSTEM",
        "category": "admin",
        "description": "Melihat dan mengonfigurasi definisi role serta hak akses sistem.",
        "required_permission": "user:read",
    },
]


def resolve_permissions_from_capabilities(
    accessible_menu_ids: list[str] | None = None,
    permitted_activity_ids: list[str] | None = None,
) -> list[str]:
    """Resolve low-level permissions list from selected menu and activity IDs."""
    perms: set[str] = set()

    if accessible_menu_ids:
        menu_lookup = {m["id"]: m.get("required_permission") for m in MENU_DEFINITIONS}
        for mid in accessible_menu_ids:
            req = menu_lookup.get(mid)
            if req:
                perms.add(req)

    if permitted_activity_ids:
        act_lookup = {a["id"]: a.get("required_permission") for a in ACTIVITY_DEFINITIONS}
        for aid in permitted_activity_ids:
            req = act_lookup.get(aid)
            if req:
                perms.add(req)

    return sorted(perms)


def get_menu_access_for_role(role_name: str, custom_permissions: list[str] | None = None) -> list[dict]:
    """Calculate which menus a specific role can access."""
    results = []
    is_super = role_name == "super_admin"
    for menu in MENU_DEFINITIONS:
        req = menu["required_permission"]
        has_access = (req is None) or is_super or _role_has_permission(role_name, req, custom_permissions)
        results.append({
            "id": menu["id"],
            "label": menu["label"],
            "href": menu["href"],
            "group": menu["group"],
            "icon": menu["icon"],
            "description": menu["description"],
            "is_accessible": has_access,
        })
    return results


def get_activities_for_role(role_name: str, custom_permissions: list[str] | None = None) -> list[dict]:
    """Calculate which business activities a specific role can perform."""
    results = []
    is_super = role_name == "super_admin"
    for act in ACTIVITY_DEFINITIONS:
        req = act["required_permission"]
        has_perm = is_super or (req is not None and _role_has_permission(role_name, req, custom_permissions))
        results.append({
            "id": act["id"],
            "name": act["name"],
            "group": act["group"],
            "category": act["category"],
            "description": act["description"],
            "required_permission": req,
            "is_permitted": has_perm,
        })
    return results


def get_user_capabilities_from_roles(role_info_list: list[Any]) -> dict:
    """Aggregate accessible menus and permitted activities across multiple roles for a user."""
    normalized: list[tuple[str, list[str] | None]] = []
    for item in role_info_list:
        if isinstance(item, tuple):
            normalized.append(item)
        elif isinstance(item, str):
            normalized.append((item, None))
        elif hasattr(item, "name"):
            normalized.append((getattr(item, "name"), getattr(item, "permissions", None)))
        else:
            normalized.append((str(item), None))

    is_super = any(r_name == "super_admin" for r_name, _ in normalized)

    # Accessible menus
    menus = []
    for menu in MENU_DEFINITIONS:
        req = menu["required_permission"]
        accessible = (req is None) or is_super or any(
            _role_has_permission(r_name, req, c_perms) for r_name, c_perms in normalized
        )
        menus.append({
            "id": menu["id"],
            "label": menu["label"],
            "href": menu["href"],
            "group": menu["group"],
            "icon": menu["icon"],
            "description": menu["description"],
            "is_accessible": accessible,
        })

    # Permitted activities
    activities = []
    for act in ACTIVITY_DEFINITIONS:
        req = act["required_permission"]
        permitted = is_super or any(
            _role_has_permission(r_name, req, c_perms) for r_name, c_perms in normalized
        )
        activities.append({
            "id": act["id"],
            "name": act["name"],
            "group": act["group"],
            "category": act["category"],
            "description": act["description"],
            "required_permission": req,
            "is_permitted": permitted,
        })

    accessible_menu_ids = [m["id"] for m in menus if m["is_accessible"]]
    permitted_activity_ids = [a["id"] for a in activities if a["is_permitted"]]

    return {
        "menus": menus,
        "activities": activities,
        "accessible_menu_count": len(accessible_menu_ids),
        "permitted_activity_count": len(permitted_activity_ids),
    }

