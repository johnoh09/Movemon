# app/db/session.py
from __future__ import annotations

from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

from app.core.config import settings

# --- Engine ---
# 운영: 기본 풀, 개발/테스트: NullPool(연결 누수 방지)
engine = create_async_engine(
    settings.database_url,
    echo=settings.sql_echo,               # bool, 설정에서 관리
    pool_pre_ping=True,
    poolclass=NullPool if settings.env in {"test"} else None,
)

# --- Session factory ---
SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# --- FastAPI dependency ---
async def get_session() -> AsyncGenerator[AsyncSession, None]:
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