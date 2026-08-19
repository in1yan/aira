from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.core.image_urls import to_public_image_url
from app.schemas.categories import CategoryResponse


AttributeType = Literal[
    "group",
    "association",
    "location",
    "function",
    "action",
    "properties",
]
ATTRIBUTE_TYPES: tuple[AttributeType, ...] = (
    "group",
    "association",
    "location",
    "function",
    "action",
    "properties",
)


class CardAttributeCreate(BaseModel):
    attribute_type: AttributeType = "properties"
    attribute_image: str | None = Field(default=None, max_length=500)


class CardCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    is_published: bool = False

    attributes: list[CardAttributeCreate] = Field(default_factory=list)
    category_ids: list[int] = Field(default_factory=list)


class CardUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    is_published: bool | None = None
    category_ids: list[int] | None = None


class CardAttributeResponse(CardAttributeCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    card_id: int

    @field_validator("attribute_type", mode="before")
    @classmethod
    def default_legacy_attribute_type(cls, value: str | None) -> str:
        return value or "properties"

    @field_validator("attribute_image", mode="before")
    @classmethod
    def make_attribute_image_public(cls, value: str | None) -> str | None:
        return to_public_image_url(value)


class CardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    user_id: int
    is_published: bool
    card_image: str | None

    @field_validator("card_image", mode="before")
    @classmethod
    def make_card_image_public(cls, value: str | None) -> str | None:
        return to_public_image_url(value)
    attributes: list[CardAttributeResponse]
    categories: list[CategoryResponse] = Field(default_factory=list)
