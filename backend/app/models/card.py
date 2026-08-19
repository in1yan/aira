from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base

if TYPE_CHECKING:
    from app.models.card_attr import CardAttributes
    from app.models.categories import Categories
    from app.models.users import User


class Cards(Base):
    __tablename__ = "cards"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    is_published: Mapped[bool] = mapped_column(Boolean, default=True)
    owner: Mapped["User"] = relationship(back_populates="cards")
    attributes: Mapped[list["CardAttributes"]] = relationship(
        back_populates="card", cascade="all, delete-orphan"
    )
    categories: Mapped[list["Categories"]] = relationship(
        secondary="card_categories", back_populates="cards"
    )
    card_image: Mapped[str | None] = mapped_column(String(500), default=None)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )

    def __repr__(self) -> str:
        return f"<Cards id={self.id} name={self.name!r}>"
