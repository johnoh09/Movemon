# app/routers/goals.py
from datetime import datetime, timedelta, date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.db.session import get_session
from app.models.goal import Goal
from app.models.workout import Workout
from app.deps.auth import get_current_user, CurrentUser
from app.schemas.goals import GoalCreate

router = APIRouter(prefix="/goals", tags=["goals"])


@router.post("", status_code=status.HTTP_201_CREATED)
async def create_goal(
    payload: GoalCreate,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    g = Goal(
        contents=payload.contents,
        user_id=user.id,
        start_date=payload.start_date,
        end_date=payload.end_date,
        weekly_sessions=payload.weekly_sessions,
        session_minutes=payload.session_minutes,
    )
    db.add(g)
    await db.commit()
    await db.refresh(g)
    return {
        "id": g.id,
        "contents": g.contents,
        "status": g.status,
        "start_date": g.start_date,
        "end_date": g.end_date,
        "weekly_sessions": g.weekly_sessions,
        "session_minutes": g.session_minutes,
        "edited_once": getattr(g, "edited_once", False),
    }


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

    # 주간 목표 횟수와 이번 주 기록 확인
    target = g.weekly_sessions
    now = datetime.utcnow()
    week_start = now - timedelta(days=now.weekday())
    week_start = week_start.replace(hour=0, minute=0, second=0, microsecond=0)
    week_end = week_start + timedelta(days=7)

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
        "start_date": g.start_date,
        "end_date": g.end_date,
        "weekly_sessions": g.weekly_sessions,
        "session_minutes": g.session_minutes,
        "edited_once": getattr(g, "edited_once", False),
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
    return [
        {
            "id": g.id,
            "contents": g.contents,
            "status": g.status,
            "start_date": g.start_date,
            "end_date": g.end_date,
            "weekly_sessions": g.weekly_sessions,
            "session_minutes": g.session_minutes,
            "edited_once": getattr(g, "edited_once", False),
        }
        for g in items
    ]

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

@router.patch("/{goal_id}/edit")
async def update_goal_once(
    goal_id: int,
    payload: dict,  # partial update: contents, weekly_sessions, session_minutes, start_date, end_date
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    # Load goal for this user
    res = await db.execute(select(Goal).where(Goal.id == goal_id, Goal.user_id == user.id))
    g = res.scalar_one_or_none()
    if not g:
        raise HTTPException(status_code=404, detail="Goal not found")

    # Already edited once? Block.
    if getattr(g, "edited_once", False):
        raise HTTPException(status_code=409, detail="This goal was already edited once.")

    # Helpers to coerce types safely
    def _coerce_int(v, field_name: str):
        if v is None:
            return None
        try:
            return int(v)
        except Exception:
            raise HTTPException(status_code=400, detail=f"Invalid integer for {field_name}")

    def _coerce_date(v, field_name: str):
        if v is None:
            return None
        if isinstance(v, date):
            return v
        try:
            return date.fromisoformat(v)
        except Exception:
            raise HTTPException(status_code=400, detail=f"Invalid date for {field_name}; use YYYY-MM-DD")

    # Apply changes only if different
    changed = False

    if "contents" in payload and payload["contents"] is not None and payload["contents"] != getattr(g, "contents"):
        g.contents = payload["contents"]
        changed = True

    if "weekly_sessions" in payload:
        ws = _coerce_int(payload.get("weekly_sessions"), "weekly_sessions")
        if ws is not None and ws != getattr(g, "weekly_sessions"):
            g.weekly_sessions = ws
            changed = True

    if "session_minutes" in payload:
        sm = _coerce_int(payload.get("session_minutes"), "session_minutes")
        if sm is not None and sm != getattr(g, "session_minutes"):
            g.session_minutes = sm
            changed = True

    if "start_date" in payload:
        sd = _coerce_date(payload.get("start_date"), "start_date")
        if sd is not None and sd != getattr(g, "start_date"):
            g.start_date = sd
            changed = True

    if "end_date" in payload:
        ed = _coerce_date(payload.get("end_date"), "end_date")
        if ed is not None and ed != getattr(g, "end_date"):
            g.end_date = ed
            changed = True

    # No-op edit shouldn't consume the one-time chance
    if not changed:
        await db.commit()
        await db.refresh(g)
        return {"id": g.id, "edited_once": getattr(g, "edited_once", False)}

    # First successful modification → mark as edited_once
    setattr(g, "edited_once", True)

    await db.commit()
    await db.refresh(g)

    return {
        "id": g.id,
        "contents": g.contents,
        "status": g.status,
        "start_date": g.start_date,
        "end_date": g.end_date,
        "weekly_sessions": g.weekly_sessions,
        "session_minutes": g.session_minutes,
        "edited_once": getattr(g, "edited_once", False),
    }