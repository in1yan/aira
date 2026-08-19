from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.card_category import card_categories

from app.db.session import Base

if TYPE_CHECKING:
    from app.models.card import Cards


class Categories(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    is_published: Mapped[bool] = mapped_column(Boolean, default=False)
    banner_url: Mapped[str | None] = mapped_column(String(500), default=None)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )
    cards: Mapped[list["Cards"]] = relationship(
        secondary=card_categories, back_populates="categories"
    )

    def __repr__(self) -> str:
        return f"<Categories id={self.id} name={self.name!r}>"
