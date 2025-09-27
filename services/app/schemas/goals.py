from __future__ import annotations
from datetime import date, datetime
from typing import Literal
from pydantic import BaseModel
from .common import OrmBase

GoalStatus = Literal["success", "fail", "progress"]

class GoalCreate(BaseModel):
    contents: str
    start_date: date
    end_date: date
    weekly_sessions: int
    session_minutes: int

class GoalUpdateStatus(BaseModel):
    status: GoalStatus

class GoalOut(OrmBase):
    id: int
    contents: str
    status: GoalStatus
    user_id: int
    start_date: date
    end_date: date
    weekly_sessions: int
    session_minutes: int

class CurrentGoalOut(BaseModel):
    id: int
    contents: str
    status: GoalStatus
    progress: float
    days_left: int
    start_date: date
    end_date: date
    # period 필드를 유지할 경우: period: dict[str, datetime]
