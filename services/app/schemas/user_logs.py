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
