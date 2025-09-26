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
