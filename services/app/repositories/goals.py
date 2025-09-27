from __future__ import annotations
from typing import Sequence, Optional
from datetime import date
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.goal import Goal
from .base import RepoHelper

class GoalRepository:
    @staticmethod
    async def create(
        db: AsyncSession,
        *,
        user_id: int,
        contents: str,
        start_date: date,
        end_date: date,
        weekly_sessions: int,
        session_minutes: int
    ) -> Goal:
        """
        새 목표를 생성합니다. contents는 요약 설명이고, start_date/end_date,
        weekly_sessions, session_minutes는 구조화된 목표 정보입니다.
        """
        g = Goal(
            user_id=user_id,
            contents=contents,
            start_date=start_date,
            end_date=end_date,
            weekly_sessions=weekly_sessions,
            session_minutes=session_minutes,
        )  # status는 기본값 'progress'
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
