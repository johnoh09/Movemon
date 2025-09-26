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
