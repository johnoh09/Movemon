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
