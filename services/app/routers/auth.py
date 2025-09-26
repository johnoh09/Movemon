# app/routers/auth.py
from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_session
from app.schemas import SignupIn, LoginIn, TokenOut, UserOut
from app.repositories.users import UserRepository
from app.core.security import create_access_token, verify_password, hash_password

router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/signup", response_model=TokenOut, status_code=status.HTTP_201_CREATED)
async def signup(payload: SignupIn, db: AsyncSession = Depends(get_session)):
    # email 중복 확인
    if await UserRepository.get_by_email(db, payload.email):
        raise HTTPException(status_code=400, detail="Email already registered")
    user = await UserRepository.create(
        db,
        email=payload.email,
        nickname=payload.nickname,
        password_plain=payload.password,  # 내부에서 bcrypt 해시됨
        sex=payload.sex,
        age=payload.age,
    )
    token = create_access_token(user.id)
    return TokenOut(access_token=token, token_type="bearer")

@router.post("/login", response_model=TokenOut)
async def login(payload: LoginIn, db: AsyncSession = Depends(get_session)):
    print("login")
    user = await UserRepository.get_by_email(db, payload.email)
    print("user", verify_password(payload.password, user.password))
    if not user or not verify_password(payload.password, user.password):
        raise HTTPException(status_code=400, detail="Invalid email or password")
    token = create_access_token(user.id)
    return TokenOut(access_token=token, token_type="bearer")

