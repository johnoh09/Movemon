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

class WorkoutUpdate(BaseModel):
    sports_id: Optional[int] = None
    duration_sec: Optional[int] = None
    workout_at: Optional[datetime] = None

