from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base

if TYPE_CHECKING:
    from app.models.card import Cards


class CardAttributes(Base):
    __tablename__ = "card_attributes"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True, index=True)
    card_id: Mapped[int] = mapped_column(ForeignKey("cards.id", ondelete="CASCADE"), nullable=False, index=True)
    attribute_image: Mapped[str | None] = mapped_column(String(500), default=None)
    card: Mapped["Cards"] = relationship(back_populates="attributes")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    def __repr__(self) -> str:
        return f"<CardAttributes id={self.id} card_id={self.card_id}>"
