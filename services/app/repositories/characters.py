from __future__ import annotations
from typing import Optional, Sequence
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user_character import UserCharacter

class CharacterRepository:
    @staticmethod
    async def latest_for_user(db: AsyncSession, user_id: int) -> Optional[UserCharacter]:
        res = await db.execute(
            select(UserCharacter).where(UserCharacter.user_id == user_id).order_by(desc(UserCharacter.created_at)).limit(1)
        )
        return res.scalar_one_or_none()

    @staticmethod
    async def list_for_user(db: AsyncSession, user_id: int) -> Sequence[UserCharacter]:
        res = await db.execute(
            select(UserCharacter).where(UserCharacter.user_id == user_id).order_by(UserCharacter.created_at.desc())
        )
        return res.scalars().all()
