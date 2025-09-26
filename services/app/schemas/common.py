from __future__ import annotations
from datetime import datetime
from pydantic import BaseModel, Field

class OrmBase(BaseModel):
    model_config = {"from_attributes": True}

class Timestamped(OrmBase):
    created_at: datetime | None = Field(default=None)
    updated_at: datetime | None = Field(default=None)
