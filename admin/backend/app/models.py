from sqlalchemy import Column, Integer, String, Boolean, ForeignKey, Text
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)
    avatar_url = Column(String, nullable=True)
    role = Column(String, default="user")
    is_active = Column(Boolean, default=True)

class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name_en = Column(String, index=True, nullable=False)
    name_ta = Column(String, nullable=True)
    name_hi = Column(String, nullable=True)
    name_ml = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    icon_name = Column(String, default="pets")
    color_hex = Column(String, default="#E8F5E9")

    cards = relationship("Card", back_populates="category", cascade="all, delete-orphan")

class Card(Base):
    __tablename__ = "cards"

    id = Column(Integer, primary_key=True, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=False)
    subcategory = Column(String, nullable=True, index=True)
    title_en = Column(String, index=True, nullable=False)
    title_ta = Column(String, nullable=True)
    title_hi = Column(String, nullable=True)
    title_ml = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    is_published = Column(Boolean, default=True)

    category = relationship("Category", back_populates="cards")
    attributes = relationship("CardAttribute", back_populates="card", cascade="all, delete-orphan")

class CardAttribute(Base):
    __tablename__ = "card_attributes"

    id = Column(Integer, primary_key=True, index=True)
    card_id = Column(Integer, ForeignKey("cards.id"), nullable=False)
    key = Column(String, nullable=False)
    label = Column(String, nullable=False)
    value_en = Column(Text, nullable=False)
    value_ta = Column(Text, nullable=True)
    value_hi = Column(Text, nullable=True)
    value_ml = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)

    card = relationship("Card", back_populates="attributes")
