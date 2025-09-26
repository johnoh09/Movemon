from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Text, TIMESTAMP, text
from app.db.base import Base

class Sport(Base):
    __tablename__ = "sports"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)
    updated_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)

    workouts: Mapped[list["Workout"]] = relationship(back_populates="sport")