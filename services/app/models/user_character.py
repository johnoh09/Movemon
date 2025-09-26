from __future__ import annotations
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import BigInteger, TIMESTAMP, ForeignKey, PrimaryKeyConstraint, text
from app.db.base import Base

class UserCharacter(Base):
    __tablename__ = "user_characters"

    user_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    character_id: Mapped[int] = mapped_column(BigInteger, ForeignKey("characters.id", ondelete="CASCADE"), nullable=False)
    created_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)
    updated_at: Mapped[str] = mapped_column(TIMESTAMP(timezone=True), server_default=text("now()"), nullable=False)

    __table_args__ = (PrimaryKeyConstraint("user_id", "character_id", name="user_characters_pkey"),)

    user: Mapped["User"] = relationship(back_populates="user_characters")
    character: Mapped["Character"] = relationship(back_populates="user_characters")