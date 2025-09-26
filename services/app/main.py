from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1.routes import api as v1_api
from .db.session import init_models

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Dev convenience: auto-create tables if they don't exist
    if settings.app_env == "dev":
        try:
            await init_models()
        except Exception:
            # If DB isn't up, app will still start; use Alembic for real migrations
            pass
    yield

app = FastAPI(title=settings.app_name, lifespan=lifespan)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health", tags=["health"])
async def root_health():
    return {"status": "ok", "service": settings.app_name, "env": settings.app_env}

app.include_router(v1_api, prefix="/v1")
