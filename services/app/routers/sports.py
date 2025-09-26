# app/routers/sports.py
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_session
from app.models.sport import Sport

router = APIRouter(prefix="/sports", tags=["sports"])

@router.get("", response_model=list[dict])
async def list_sports(db: AsyncSession = Depends(get_session)):
    res = await db.execute(select(Sport).order_by(Sport.id))
    items = res.scalars().all()
    return [{"id": s.id, "name": s.name} for s in items]