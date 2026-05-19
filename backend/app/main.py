from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from app.config import get_settings
from app.core.redis_client import close_redis, get_redis
from app.routers import auth, rbac, projects, dashboard, dsr, dpia, ropa, bapd, dq, metadata, audit, notifications

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_redis()
    yield
    await close_redis()


app = FastAPI(
    title="AI Governance Tools API",
    version="1.0.0",
    debug=settings.debug,
    docs_url="/api/v1/docs" if settings.environment != "production" else None,
    redoc_url="/api/v1/redoc" if settings.environment != "production" else None,
    openapi_url="/api/v1/openapi.json" if settings.environment != "production" else None,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if settings.environment == "production":
    app.add_middleware(TrustedHostMiddleware, allowed_hosts=["*"])

app.include_router(auth.router,      prefix="/api/v1")
app.include_router(rbac.router,      prefix="/api/v1")
app.include_router(projects.router,  prefix="/api/v1")
app.include_router(dashboard.router, prefix="/api/v1")
app.include_router(dsr.router,       prefix="/api/v1")
app.include_router(dpia.router,      prefix="/api/v1")
app.include_router(ropa.router,      prefix="/api/v1")
app.include_router(bapd.router,      prefix="/api/v1")
app.include_router(dq.router,        prefix="/api/v1")
app.include_router(metadata.router,  prefix="/api/v1")
app.include_router(audit.router,         prefix="/api/v1")
app.include_router(notifications.router, prefix="/api/v1")


@app.get("/health", tags=["health"])
async def health_check() -> dict:
    return {"status": "ok", "environment": settings.environment}
