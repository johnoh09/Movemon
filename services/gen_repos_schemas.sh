#!/usr/bin/env bash
set -euo pipefail

# 사용법:
#   bash gen_repos_schemas.sh
# 현재 디렉토리를 프로젝트 루트로 가정(app/ 폴더 존재 예정)

mkdir -p app/schemas app/repositories

############################################
# app/schemas/*
############################################
cat > app/schemas/__init__.py <<'PY'
from .common import OrmBase, Timestamped
from .auth import SignupIn, LoginIn, TokenOut
from .user import UserCreate, UserUpdate, UserOut
from .sports import SportOut
from .workouts import WorkoutCreate, WorkoutOut
from .goals import GoalCreate, GoalUpdateStatus, GoalOut, CurrentGoalOut
from .characters import MyCharacterOut
from .user_logs import UserLogCreate, UserLogOut
from .reports import SummaryOut, WeightPoint

__all__ = [
    "OrmBase", "Timestamped",
    "SignupIn", "LoginIn", "TokenOut",
    "UserCreate", "UserUpdate", "UserOut",
    "SportOut",
    "WorkoutCreate", "WorkoutOut",
    "GoalCreate", "GoalUpdateStatus", "GoalOut", "CurrentGoalOut",
    "MyCharacterOut",
    "UserLogCreate", "UserLogOut",
    "SummaryOut", "WeightPoint",
]
PY

cat > app/schemas/common.py <<'PY'
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field

class OrmBase(BaseModel):
    model_config = {"from_attributes": True}

class Timestamped(OrmBase):
    created_at: datetime | None = Field(default=None)
    updated_at: datetime | None = Field(default=None)
PY

cat > app/schemas/auth.py <<'PY'
from __future__ import annotations
from pydantic import BaseModel, EmailStr, Field
from typing import Literal

class SignupIn(BaseModel):
    email: EmailStr
    nickname: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=6, max_length=128)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class TokenOut(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
PY

cat > app/schemas/user.py <<'PY'
from __future__ import annotations
from pydantic import BaseModel, EmailStr, Field
from typing import Literal
from .common import OrmBase

class UserCreate(BaseModel):
    email: EmailStr
    nickname: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=6, max_length=128)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class UserUpdate(BaseModel):
    nickname: str | None = Field(default=None, min_length=1, max_length=100)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class UserOut(OrmBase):
    id: int
    email: EmailStr
    nickname: str
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None
PY

cat > app/schemas/sports.py <<'PY'
from __future__ import annotations
from .common import OrmBase

class SportOut(OrmBase):
    id: int
    name: str
PY

cat > app/schemas/workouts.py <<'PY'
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field
from .common import OrmBase

class WorkoutCreate(BaseModel):
    sports_id: int
    duration_sec: int = Field(gt=0)
    workout_at: datetime  # ISO8601

class WorkoutOut(OrmBase):
    id: int
    user_id: int
    sports_id: int
    duration_sec: int
    workout_at: datetime
PY

cat > app/schemas/goals.py <<'PY'
from __future__ import annotations
from datetime import datetime
from typing import Literal
from pydantic import BaseModel
from .common import OrmBase

GoalStatus = Literal["success", "fail", "progress"]

class GoalCreate(BaseModel):
    contents: str

class GoalUpdateStatus(BaseModel):
    status: GoalStatus

class GoalOut(OrmBase):
    id: int
    contents: str
    status: GoalStatus
    user_id: int

class CurrentGoalOut(BaseModel):
    id: int
    contents: str
    status: GoalStatus
    progress: float  # 0.0 ~ 1.0
    days_left: int
    period: dict[str, datetime]  # {"start": dt, "end": dt}
PY

cat > app/schemas/characters.py <<'PY'
from __future__ import annotations
from pydantic import BaseModel

class MyCharacterOut(BaseModel):
    exists: bool | None = None
    character_id: int | None = None
    level: int | None = None
    next_level_in_sec: int | None = None
    de_evolution_warning: bool | None = None
PY

cat > app/schemas/user_logs.py <<'PY'
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field
from .common import OrmBase

class UserLogCreate(BaseModel):
    weight_kg: float = Field(gt=0)
    height_cm: float = Field(gt=0)
    created_at: datetime | None = None  # 없으면 서버에서 now() 주입

class UserLogOut(OrmBase):
    id: int
    user_id: int
    weight_kg: float
    height_cm: float
    created_at: datetime
PY

cat > app/schemas/reports.py <<'PY'
from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel

class SummaryOut(BaseModel):
    sessions: int
    total_minutes: int
    since: datetime

class WeightPoint(BaseModel):
    ts: datetime
    weight_kg: float
    height_cm: float
PY

############################################
# app/repositories/*
############################################
cat > app/repositories/__init__.py <<'PY'
from .base import RepoHelper
from .users import UserRepository
from .sports import SportRepository
from .workouts import WorkoutRepository
from .goals import GoalRepository
from .user_logs import UserLogRepository
from .characters import CharacterRepository

__all__ = [
    "RepoHelper",
    "UserRepository",
    "SportRepository",
    "WorkoutRepository",
    "GoalRepository",
    "UserLogRepository",
    "CharacterRepository",
]
PY

cat > app/repositories/base.py <<'PY'
from __future__ import annotations
from typing import Iterable, Sequence, TypeVar, Generic
from sqlalchemy.ext.asyncio import AsyncSession

T = TypeVar("T")

class RepoHelper(Generic[T]):
    """공통 유틸: commit/refresh 핸들링"""
    @staticmethod
    async def save(db: AsyncSession, obj: T) -> T:
        db.add(obj)
        await db.commit()
        await db.refresh(obj)
        return obj

    @staticmethod
    async def save_all(db: AsyncSession, objs: Iterable[T]) -> Sequence[T]:
        objs = list(objs)
        db.add_all(objs)
        await db.commit()
        for o in objs:
            await db.refresh(o)
        return list(objs)
PY

cat > app/repositories/users.py <<'PY'
from __future__ import annotations
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user import User
from .base import RepoHelper
import bcrypt

class UserRepository:
    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: int) -> Optional[User]:
        res = await db.execute(select(User).where(User.id == user_id))
        return res.scalar_one_or_none()

    @staticmethod
    async def get_by_email(db: AsyncSession, email: str) -> Optional[User]:
        res = await db.execute(select(User).where(User.email == email))
        return res.scalar_one_or_none()

    @staticmethod
    async def create(
        db: AsyncSession,
        *,
        email: str,
        nickname: str,
        password_plain: str,
        sex: Optional[str] = None,
        age: Optional[int] = None,
    ) -> User:
        hashed = bcrypt.hashpw(password_plain.encode(), bcrypt.gensalt()).decode()
        u = User(email=email, nickname=nickname, password=hashed, sex=sex, age=age)
        return await RepoHelper.save(db, u)

    @staticmethod
    async def update_partial(
        db: AsyncSession,
        user: User,
        *,
        nickname: Optional[str] = None,
        sex: Optional[str] = None,
        age: Optional[int] = None,
        password_plain: Optional[str] = None,
    ) -> User:
        if nickname is not None:
            user.nickname = nickname
        if sex is not None:
            user.sex = sex
        if age is not None:
            user.age = age
        if password_plain:
            user.password = bcrypt.hashpw(password_plain.encode(), bcrypt.gensalt()).decode()
        await db.commit()
        await db.refresh(user)
        return user
PY

cat > app/repositories/sports.py <<'PY'
from __future__ import annotations
from typing import Sequence, Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.sport import Sport
from .base import RepoHelper

class SportRepository:
    @staticmethod
    async def list_all(db: AsyncSession) -> Sequence[Sport]:
        res = await db.execute(select(Sport).order_by(Sport.id))
        return res.scalars().all()

    @staticmethod
    async def get_by_id(db: AsyncSession, sport_id: int) -> Optional[Sport]:
        res = await db.execute(select(Sport).where(Sport.id == sport_id))
        return res.scalar_one_or_none()

    @staticmethod
    async def create(db: AsyncSession, name: str) -> Sport:
        s = Sport(name=name)
        return await RepoHelper.save(db, s)
PY

cat > app/repositories/workouts.py <<'PY'
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
PY

cat > app/repositories/goals.py <<'PY'
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
PY

cat > app/repositories/user_logs.py <<'PY'
from __future__ import annotations
from datetime import datetime
from typing import Sequence
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.user_log import UserLog
from .base import RepoHelper

class UserLogRepository:
    @staticmethod
    async def create(
        db: AsyncSession,
        *,
        user_id: int,
        weight_kg: float,
        height_cm: float,
        created_at: datetime | None = None,
    ) -> UserLog:
        log = UserLog(
            user_id=user_id,
            weight_kg=weight_kg,
            height_cm=height_cm,
            created_at=created_at or datetime.utcnow(),
        )
        return await RepoHelper.save(db, log)

    @staticmethod
    async def list_for_user(db: AsyncSession, user_id: int, limit: int = 30) -> Sequence[UserLog]:
        res = await db.execute(
            select(UserLog).where(UserLog.user_id == user_id).order_by(UserLog.created_at.desc()).limit(limit)
        )
        return res.scalars().all()
PY

cat > app/repositories/characters.py <<'PY'
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
PY

echo "✅ Generated files in app/schemas and app/repositories"
echo "ℹ️  참고: EmailStr 사용 시 'email-validator'가 필요합니다 -> pip install email-validator"
echo "ℹ️  비밀번호 해시(bcrypt)를 사용합니다 -> pip install bcrypt"