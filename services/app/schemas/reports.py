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
