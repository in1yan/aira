from sqlalchemy import Column, ForeignKey, Table

from app.db.session import Base


card_categories = Table(
    "card_categories",
    Base.metadata,
    Column("card_id", ForeignKey("cards.id", ondelete="CASCADE"), primary_key=True),
    Column("category_id", ForeignKey("categories.id", ondelete="CASCADE"), primary_key=True),
)
