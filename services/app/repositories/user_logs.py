from __future__ import annotations
from datetime import datetime
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user_log import UserLog
from .base import RepoHelper

class UserLogRepository:
    @staticmethod
    async def create(
        db: AsyncSession,
        *,
        user_id: int,
        weight_kg: float,
        height_cm: float,
        created_at: datetime | None = None,
    ) -> UserLog:
        log = UserLog(
            user_id=user_id,
            weight_kg=weight_kg,
            height_cm=height_cm,
            created_at=created_at or datetime.utcnow(),
        )
        return await RepoHelper.save(db, log)

    @staticmethod
    async def list_for_user(db: AsyncSession, user_id: int, limit: int = 30) -> Sequence[UserLog]:
        res = await db.execute(
            select(UserLog).where(UserLog.user_id == user_id).order_by(UserLog.created_at.desc()).limit(limit)
        )
        return res.scalars().all()
