from __future__ import annotations
from pydantic import BaseModel, EmailStr, Field
from typing import Literal

class SignupIn(BaseModel):
    email: EmailStr
    nickname: str = Field(min_length=1, max_length=100)
    password: str = Field(min_length=6, max_length=128)
    sex: Literal["M", "F", "N"] | None = None
    age: int | None = None

class LoginIn(BaseModel):
    email: EmailStr
    password: str

class TokenOut(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
