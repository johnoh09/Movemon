from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Text, ForeignKey
from app.db.base import Base
from .enums import GoalStatusEnum
from datetime import date
from sqlalchemy import BigInteger, Text, ForeignKey, Date, Integer

class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contents: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(GoalStatusEnum, nullable=False, server_default="progress")
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    # 새로운 컬럼: 목표 시작일·종료일과 주간/회당 목표
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    weekly_sessions: Mapped[int] = mapped_column(Integer, nullable=False)
    session_minutes: Mapped[int] = mapped_column(Integer, nullable=False)

    user: Mapped["User"] = relationship(back_populates="goals")