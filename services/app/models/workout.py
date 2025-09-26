from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Integer, TIMESTAMP, CheckConstraint, ForeignKey, text
from app.db.base import Base

class Workout(Base):
    __tablename__ = "workouts"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    sports_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("sports.id", ondelete="RESTRICT"), nullable=False)
    duration_sec: Mapped[int] = mapped_column(Integer, nullable=False)
    workout_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), nullable=False)
    created_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)
    updated_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)

    user: Mapped["User"] = relationship(back_populates="workouts")
    sport: Mapped["Sport"] = relationship(back_populates="workouts")

    __table_args__ = (CheckConstraint("duration_sec > 0", name="ck_workouts_duration"),)