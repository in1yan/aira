from pydantic import BaseModel, ConfigDict, Field


class CardAttributeCreate(BaseModel):
    attribute_image: str | None = Field(default=None, max_length=500)


class CardCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    is_published: bool = False

    attributes: list[CardAttributeCreate] = Field(default_factory=list)


class CardAttributeResponse(CardAttributeCreate):
    model_config = ConfigDict(from_attributes=True)

    id: int
    card_id: int


class CardResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    user_id: int
    is_published: bool
    card_image: str | None
    attributes: list[CardAttributeResponse]
