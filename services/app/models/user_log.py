from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, Numeric, TIMESTAMP, CheckConstraint, ForeignKey, text
from app.db.base import Base

class UserLog(Base):
    __tablename__ = "user_logs"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    weight_kg: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    height_cm: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    created_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)

    user: Mapped["User"] = relationship(back_populates="logs")

    __table_args__ = (
        CheckConstraint("weight_kg > 0", name="ck_user_logs_weight"),
        CheckConstraint("height_cm > 0", name="ck_user_logs_height"),
    )