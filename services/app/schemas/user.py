from __future__ import annotations
from pydantic import BaseModel, EmailStr, Field
from typing import Literal
from .common import OrmBase

class UserCreate(BaseModel):
    email: EmailStr
    nickname: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=6, max_length=128)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class UserUpdate(BaseModel):
    nickname: str | None = Field(default=None, min_length=1, max_length=100)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class UserOut(OrmBase):
    id: int
    email: EmailStr
    nickname: str
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class UserRead(BaseModel):
    id: int
    email: EmailStr
    nickname: str
    sex: str | None = None
    age: int | None = None

    model_config = {"from_attributes": True}