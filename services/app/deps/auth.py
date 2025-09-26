# app/deps/auth.py (발췌)
from __future__ import annotations
from fastapi import Depends, HTTPException, status, Header
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from typing import Annotated
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import decode_access_token
from app.db.session import get_session
from app.repositories.users import UserRepository
from app.models.user import User

security = HTTPBearer(auto_error=False)

async def get_current_user(
    db: AsyncSession = Depends(get_session),
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    x_user_id: int | None = Header(default=None, alias="X-User-Id"),
) -> User:
    user_id: int | None = None
    if credentials and credentials.scheme.lower() == "bearer":
        try:
            payload = decode_access_token(credentials.credentials)
            user_id = int(payload["sub"])
        except Exception:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    elif x_user_id is not None:
        user_id = int(x_user_id)

    if user_id is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Not authenticated")

    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user

# ★ 여기 추가
CurrentUser = Annotated[User, get_current_user]