from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Text, ForeignKey
from app.db.base import Base
from .enums import GoalStatusEnum

class Goal(Base):
    __tablename__ = "goals"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contents: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(GoalStatusEnum, nullable=False, server_default="progress")
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)

    user: Mapped["User"] = relationship(back_populates="goals")