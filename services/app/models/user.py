from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Text, Integer, TIMESTAMP, CheckConstraint, text
from app.db.base import Base
from .enums import GenderEnum

class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    email: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    nickname: Mapped[str] = mapped_column(Text, nullable=False)
    password: Mapped[str] = mapped_column(Text, nullable=False)  # 해시 저장
    sex: Mapped[str | None] = mapped_column(GenderEnum, nullable=True)
    age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    created_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)
    updated_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)

    # relationships
    goals: Mapped[list["Goal"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    logs: Mapped[list["UserLog"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    workouts: Mapped[list["Workout"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    user_characters: Mapped[list["UserCharacter"]] = relationship(back_populates="user", cascade="all, delete-orphan")

    __table_args__ = (CheckConstraint("age BETWEEN 0 AND 120", name="ck_users_age"),)