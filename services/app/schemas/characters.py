from __future__ import annotations
from pydantic import BaseModel

class MyCharacterOut(BaseModel):
    exists: bool | None = None
    character_id: int | None = None
    level: int | None = None
    next_level_in_sec: int | None = None
    de_evolution_warning: bool | None = None
