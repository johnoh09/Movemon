# app/repositories/user_repo.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User
from app.schemas.user import UserCreate

class UserRepository:

    @staticmethod
    async def create(db: AsyncSession, data: UserCreate) -> User:
        user = User(
            email=data.email,
            nickname=data.nickname,
            password=data.password,
            sex=data.sex,
            age=data.age,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)  # id, created_at 등 반영
        return user

    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: int) -> User | None:
        result = await db.execute(select(User).where(User.id == user_id))
        return result.scalar_one_or_none()

    @staticmethod
    async def list_all(db: AsyncSession) -> list[User]:
        result = await db.execute(select(User).order_by(User.id))
        return list(result.scalars().all())

    @staticmethod
    async def update(db: AsyncSession, user: User, data: dict) -> User:
        for field, value in data.items():
            setattr(user, field, value)
        await db.commit()
        await db.refresh(user)
        return user

    @staticmethod
    async def delete(db: AsyncSession, user: User) -> None:
        await db.delete(user)
        await db.commit()