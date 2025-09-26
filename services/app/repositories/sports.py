from __future__ import annotations
from typing import Sequence, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.sport import Sport
from .base import RepoHelper

class SportRepository:
    @staticmethod
    async def list_all(db: AsyncSession) -> Sequence[Sport]:
        res = await db.execute(select(Sport).order_by(Sport.id))
        return res.scalars().all()

    @staticmethod
    async def get_by_id(db: AsyncSession, sport_id: int) -> Optional[Sport]:
        res = await db.execute(select(Sport).where(Sport.id == sport_id))
        return res.scalar_one_or_none()

    @staticmethod
    async def create(db: AsyncSession, name: str) -> Sport:
        s = Sport(name=name)
        return await RepoHelper.save(db, s)
