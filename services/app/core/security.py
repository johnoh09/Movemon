# app/core/security.py
from __future__ import annotations
from datetime import datetime, timedelta, timezone
from typing import Any, Optional
import jwt
import bcrypt
from app.core.config import settings

def hash_password(plain_password: str) -> str:
    hashed = bcrypt.hashpw(plain_password.encode(), bcrypt.gensalt())
    return hashed.decode()

def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode(), hashed.encode())

def create_access_token(sub: str | int, expires_minutes: Optional[int] = None) -> str:
    now = datetime.now(timezone.utc)
    exp = now + timedelta(minutes=expires_minutes or settings.access_token_expires_minutes)
    payload: dict[str, Any] = {"sub": str(sub), "iat": int(now.timestamp()), "exp": int(exp.timestamp())}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)

def decode_access_token(token: str) -> dict[str, Any]:
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])