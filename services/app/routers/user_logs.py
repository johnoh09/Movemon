# app/routers/user_logs.py
from datetime import datetime
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_session
from app.models.user_log import UserLog
from app.deps.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/user-logs", tags=["user_logs"])

@router.post("", status_code=status.HTTP_201_CREATED)
async def create_log(
    payload: dict,  # { "weight_kg": 72.5, "height_cm": 175.0, "created_at"?: ISO8601 }
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    created_at = datetime.fromisoformat(payload["created_at"]) if "created_at" in payload else None
    log = UserLog(
        user_id=user.id,
        weight_kg=payload["weight_kg"],
        height_cm=payload["height_cm"],
        created_at=created_at or datetime.utcnow(),
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return {"id": log.id, "created_at": log.created_at.isoformat()}

@router.get("")
async def list_logs(
    limit: int = 30,
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    res = await db.execute(
        select(UserLog).where(UserLog.user_id == user.id).order_by(UserLog.created_at.desc()).limit(limit)
    )
    items = res.scalars().all()
    return [
        {"id": x.id, "weight_kg": float(x.weight_kg), "height_cm": float(x.height_cm), "created_at": x.created_at.isoformat()}
        for x in items
    ]