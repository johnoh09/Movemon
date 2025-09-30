# app/db/session.py
from __future__ import annotations
import os, ssl
 
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.config import settings


# --- SSL 컨텍스트: Neon은 TLS 필수 ---
ssl_ctx = None
if "neon.tech" in settings.DATABASE_URL or os.getenv("DB_SSL", "false").lower() in ("1", "true", "yes"):
    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = True
    ssl_ctx.verify_mode = ssl.CERT_REQUIRED

connect_args = {}
if ssl_ctx is not None:
    connect_args["ssl"] = ssl_ctx
    # NeonDB의 cold start를 대비해 연결 타임아웃을 30초로 늘립니다.
    connect_args["timeout"] = 30

# --- Engine ---
# 운영: 기본 풀, 개발/테스트: NullPool(연결 누수 방지)
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=settings.sql_echo,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
    connect_args=connect_args,
)


# --- Session factory ---
SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)

# --- FastAPI dependency ---
async def get_session():
    async with SessionLocal() as session:
        yield session

# --- (선택) 개발 전용 테이블 생성 ---
async def init_models() -> None:
    """
    개발 편의용. Alembic 미사용 시에만 호출.
    주의: DB에 필요한 ENUM 타입(gender, goal_status)이 먼저 존재해야 함.
    """
    # Base.metadata가 모든 모델을 인지하도록 import
    from app.models import (  # noqa: F401
        user, character, sport, goal, user_log, workout, user_character, enums
    )
    from app.db.base import Base

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

async def dispose_engine() -> None:
    await engine.dispose()

