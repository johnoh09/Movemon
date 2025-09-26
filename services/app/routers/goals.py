# app/routers/goals.py
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_session
from app.models.goal import Goal
from app.models.workout import Workout
from app.deps.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/goals", tags=["goals"])

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_goal(
    payload: dict,  # { "contents": "Work out 3 times a week" }
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    g = Goal(contents=payload["contents"], user_id=user.id)
    db.add(g)
    await db.commit()
    await db.refresh(g)
    return {"id": g.id, "contents": g.contents, "status": g.status}

@router.get("/current")
async def get_current_goal(
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    # 가장 최근 goal을 current로 간주
    res = await db.execute(select(Goal).where(Goal.user_id == user.id).order_by(Goal.id.desc()).limit(1))
    g = res.scalar_one_or_none()
    if not g:
        return {"exists": False}

    # 단순 규칙: 이번 주(월~일) 운동 횟수 / 목표치
    now = datetime.utcnow()
    week_start = now - timedelta(days=now.weekday())
    week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
    week_end = week_start + timedelta(days=7)

    # 목표 치환 규칙 (예: "3 times" → 3). 아주 단순 파서.
    import re
    m = re.search(r"(\d+)\s*times", g.contents.lower())
    target = int(m.group(1)) if m else 3

    c_res = await db.execute(
        select(func.count(Workout.id)).where(
            Workout.user_id == user.id,
            Workout.workout_at >= week_start,
            Workout.workout_at < week_end,
        )
    )
    done = c_res.scalar_one()
    progress = min(1.0, (done / target) if target else 0.0)
    days_left = max(0, (week_end - now).days)

    return {
        "id": g.id,
        "contents": g.contents,
        "status": g.status,
        "progress": round(progress, 2),
        "days_left": days_left,
        "period": {"start": week_start.isoformat(), "end": week_end.isoformat()},
    }

@router.get("/history")
async def list_goals(
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
    limit: int = 20,
):
    res = await db.execute(select(Goal).where(Goal.user_id == user.id).order_by(Goal.id.desc()).limit(limit))
    items = res.scalars().all()
    return [{"id": g.id, "contents": g.contents, "status": g.status} for g in items]

@router.patch("/{goal_id}")
async def update_goal_status(
    goal_id: int,
    payload: dict,  # { "status": "success" | "fail" | "progress" }
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    res = await db.execute(select(Goal).where(Goal.id == goal_id, Goal.user_id == user.id))
    g = res.scalar_one_or_none()
    if not g:
        raise HTTPException(status_code=404, detail="Goal not found")
    if payload.get("status") not in {"success", "fail", "progress"}:
        raise HTTPException(status_code=400, detail="Invalid status")
    g.status = payload["status"]
    await db.commit()
    await db.refresh(g)
    return {"id": g.id, "status": g.status}