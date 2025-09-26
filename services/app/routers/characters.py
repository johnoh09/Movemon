# app/routers/characters.py
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from app.db.session import get_session
from app.models.user_character import UserCharacter
from app.models.workout import Workout
from app.deps.auth import get_current_user, CurrentUser

router = APIRouter(prefix="/characters", tags=["characters"])

@router.get("/me")
async def get_my_character(
    user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_session),
):
    # 최신 user_character 1건
    res = await db.execute(
        select(UserCharacter).where(UserCharacter.user_id == user.id).order_by(desc(UserCharacter.created_at)).limit(1)
    )
    uc = res.scalar_one_or_none()
    if not uc:
        return {"exists": False}

    # 레벨 산식(예시): 최근 30일 운동 총 시간(분)/60 + 1
    since = datetime.utcnow() - timedelta(days=30)
    s = await db.execute(
        select(func.coalesce(func.sum(Workout.duration_sec), 0)).where(
            Workout.user_id == user.id, Workout.workout_at >= since
        )
    )
    total_sec = int(s.scalar_one())
    level = max(1, 1 + total_sec // 3600)
    next_req = 3600 - (total_sec % 3600)

    # 무활동 7일 경고
    last = await db.execute(
        select(func.max(Workout.workout_at)).where(Workout.user_id == user.id)
    )
    last_dt = last.scalar_one()
    inactive_days = (datetime.utcnow() - last_dt).days if last_dt else 999

    return {
        "character_id": uc.character_id,
        "level": int(level),
        "next_level_in_sec": int(next_req),
        "de_evolution_warning": inactive_days >= 7,
    }