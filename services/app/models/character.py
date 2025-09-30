from __future__ import annotations
from datetime import datetime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Text, Integer, TIMESTAMP, CheckConstraint, text
from app.db.base import Base
from .enums import GenderEnum

class Character(Base):
    __tablename__ = "characters"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    age: Mapped[int] = mapped_column(Integer, nullable=False)
    sex: Mapped[str] = mapped_column(GenderEnum, nullable=False)
    character_type: Mapped[str] = mapped_column(Text, nullable=False)
    img_url: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False
    )
    updated_at: Mapped[datetime] = mapped_column(
        TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False
    )

    # 문자열로 타깃 모델 명시 (추론 실패 방지)
    user_characters: Mapped[list["UserCharacter"]] = relationship(
        "UserCharacter", back_populates="character", cascade="all, delete-orphan"
    )

    __table_args__ = (
        CheckConstraint("age BETWEEN 0 AND 120", name="ck_characters_age"),
    )