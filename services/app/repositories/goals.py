from __future__ import annotations
from typing import Sequence, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.goal import Goal
from .base import RepoHelper

class GoalRepository:
    @staticmethod
    async def create(db: AsyncSession, *, user_id: int, contents: str) -> Goal:
        g = Goal(user_id=user_id, contents=contents)  # status default: 'progress'
        return await RepoHelper.save(db, g)

    @staticmethod
    async def get_latest_for_user(db: AsyncSession, user_id: int) -> Optional[Goal]:
        res = await db.execute(select(Goal).where(Goal.user_id == user_id).order_by(Goal.id.desc()).limit(1))
        return res.scalar_one_or_none()

    @staticmethod
    async def list_for_user(db: AsyncSession, user_id: int, limit: int = 20) -> Sequence[Goal]:
        res = await db.execute(select(Goal).where(Goal.user_id == user_id).order_by(Goal.id.desc()).limit(limit))
        return res.scalars().all()

    @staticmethod
    async def update_status(db: AsyncSession, goal: Goal, status: str) -> Goal:
        goal.status = status
        await db.commit()
        await db.refresh(goal)
        return goal
