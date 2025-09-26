# app/routers/reports.py
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_session
from app.models.workout import Workout
from app.models.user_log import UserLog
from app.deps.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/reports", tags=["reports"])

@router.get("/summary")
async def summary(
    range: str = Query("week", pattern="^(week|month)$"),
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    now = datetime.utcnow()
    if range == "week":
        start = (now - timedelta(days=now.weekday())).replace(hour=0, minute=0, second=0, microsecond=0)
    else:
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    q = await db.execute(
        select(
            func.count(Workout.id),
            func.coalesce(func.sum(Workout.duration_sec), 0),
        ).where(Workout.user_id == user.id, Workout.workout_at >= start)
    )
    count, total_sec = q.first()
    return {"sessions": int(count), "total_minutes": int(total_sec) // 60, "since": start.isoformat()}

@router.get("/weight")
async def weight(
    limit: int = 30,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    res = await db.execute(
        select(UserLog).where(UserLog.user_id == user.id).order_by(UserLog.created_at.desc()).limit(limit)
    )
    items = res.scalars().all()
    return [
        {"ts": x.created_at.isoformat(), "weight_kg": float(x.weight_kg), "height_cm": float(x.height_cm)}
        for x in items
    ]