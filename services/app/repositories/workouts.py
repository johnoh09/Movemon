from __future__ import annotations
from datetime import datetime
from typing import Sequence, Optional
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.workout import Workout
from .base import RepoHelper

class WorkoutRepository:
    @staticmethod
    async def create(
        db: AsyncSession,
        *,
        user_id: int,
        sports_id: int,
        duration_sec: int,
        workout_at: datetime,
    ) -> Workout:
        w = Workout(
            user_id=user_id,
            sports_id=sports_id,
            duration_sec=duration_sec,
            workout_at=workout_at,
        )
        return await RepoHelper.save(db, w)

    @staticmethod
    async def get_by_id_for_user(db: AsyncSession, workout_id: int, user_id: int) -> Optional[Workout]:
        res = await db.execute(select(Workout).where(and_(Workout.id == workout_id, Workout.user_id == user_id)))
        return res.scalar_one_or_none()

    @staticmethod
    async def list_for_user(
        db: AsyncSession,
        *,
        user_id: int,
        from_: Optional[datetime] = None,
        to_: Optional[datetime] = None,
        limit: int = 50,
    ) -> Sequence[Workout]:
        stmt = select(Workout).where(Workout.user_id == user_id).order_by(Workout.workout_at.desc()).limit(limit)
        if from_:
            stmt = stmt.where(Workout.workout_at >= from_)
        if to_:
            stmt = stmt.where(Workout.workout_at < to_)
        res = await db.execute(stmt)
        return res.scalars().all()

    @staticmethod
    async def delete_for_user(db: AsyncSession, workout: Workout) -> None:
        await db.delete(workout)
        await db.commit()
