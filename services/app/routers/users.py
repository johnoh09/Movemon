# app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from app.schemas.user import UserCreate, UserRead, UserOut
from app.repositories.user_repo import UserRepository
from app.db.session import get_session
from app.deps.auth import get_current_user
from app.models.user import User

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserOut)
async def me(current_user: User = Depends(get_current_user)):
    return current_user

@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def create_user(payload: UserCreate, db: AsyncSession = Depends(get_session)):
    return await UserRepository.create(db, payload)

@router.get("/{user_id}", response_model=UserRead)
async def get_user(user_id: int, db: AsyncSession = Depends(get_session)):
    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("", response_model=list[UserRead])
async def list_users(db: AsyncSession = Depends(get_session)):
    return await UserRepository.list_all(db)

@router.put("/{user_id}", response_model=UserRead)
async def update_user(user_id: int, payload: UserCreate, db: AsyncSession = Depends(get_session)):
    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return await UserRepository.update(db, user, payload.dict(exclude_unset=True))

@router.delete("/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_user(user_id: int, db: AsyncSession = Depends(get_session)):
    user = await UserRepository.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    await UserRepository.delete(db, user)