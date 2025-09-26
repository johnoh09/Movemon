# app/routers/workouts.py
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from app.db.session import get_session
from app.models.workout import Workout
from app.deps.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/workouts", tags=["workouts"])

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_workout(
    payload: dict,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    # 기대 payload: { "sports_id": int, "duration_sec": int, "workout_at": ISO8601 }
    w = Workout(
        user_id=user.id,
        sports_id=payload["sports_id"],
        duration_sec=payload["duration_sec"],
        workout_at=datetime.fromisoformat(payload["workout_at"]),
    )
    db.add(w)
    await db.commit()
    await db.refresh(w)
    return {
        "id": w.id,
        "user_id": w.user_id,
        "sports_id": w.sports_id,
        "duration_sec": w.duration_sec,
        "workout_at": w.workout_at.isoformat(),
        "created_at": w.created_at.isoformat(),
    }

@router.get("")
async def list_workouts(
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
    from_: datetime | None = Query(default=None, alias="from"),
    to_: datetime | None = Query(default=None, alias="to"),
    limit: int = 50,
):
    stmt = select(Workout).where(Workout.user_id == user.id).order_by(Workout.workout_at.desc()).limit(limit)
    if from_:
        stmt = stmt.where(Workout.workout_at >= from_)
    if to_:
        stmt = stmt.where(Workout.workout_at < to_)
    res = await db.execute(stmt)
    items = res.scalars().all()
    return [
        {
            "id": w.id,
            "sports_id": w.sports_id,
            "duration_sec": w.duration_sec,
            "workout_at": w.workout_at.isoformat(),
        }
        for w in items
    ]

@router.get("/{workout_id}")
async def get_workout(
    workout_id: int,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    res = await db.execute(select(Workout).where(and_(Workout.id == workout_id, Workout.user_id == user.id)))
    w = res.scalar_one_or_none()
    if not w:
        raise HTTPException(status_code=404, detail="Workout not found")
    return {
        "id": w.id,
        "sports_id": w.sports_id,
        "duration_sec": w.duration_sec,
        "workout_at": w.workout_at.isoformat(),
    }

@router.delete("/{workout_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_workout(
    workout_id: int,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    res = await db.execute(select(Workout).where(and_(Workout.id == workout_id, Workout.user_id == user.id)))
    w = res.scalar_one_or_none()
    if not w:
        raise HTTPException(status_code=404, detail="Workout not found")
    await db.delete(w)
    await db.commit()