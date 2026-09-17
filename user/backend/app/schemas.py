from pydantic import BaseModel
from typing import List, Optional, Dict, Any

# Authentication schemas
class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: Optional[str] = "user"

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: Optional[str] = "user"
    is_active: Optional[bool] = True

    class Config:
        from_attributes = True

# Concept Attribute schema
class CardAttributeSchema(BaseModel):
    key: str
    label: str
    name: Optional[str] = ""
    value_en: Optional[str] = ""
    value_ta: Optional[str] = ""
    value_hi: Optional[str] = ""
    value_ml: Optional[str] = ""
    image_url: Optional[str] = ""

    class Config:
        from_attributes = True

# Category schemas
class CategoryResponse(BaseModel):
    id: int
    name_en: str
    name_ta: Optional[str] = ""
    name_hi: Optional[str] = ""
    name_ml: Optional[str] = ""
    description: Optional[str] = ""
    icon_name: Optional[str] = "pets"
    color_hex: Optional[str] = "#E8F5E9"
    card_count: Optional[int] = 0

    class Config:
        from_attributes = True

# Card detail response
class CardResponse(BaseModel):
    id: int
    category_id: int
    category_name: Optional[str] = ""
    subcategory: Optional[str] = ""
    name: str
    title_en: str
    title_ta: Optional[str] = ""
    title_hi: Optional[str] = ""
    title_ml: Optional[str] = ""
    image_url: Optional[str] = ""
    trigger_image: Optional[str] = ""
    is_published: Optional[bool] = True
    attributes: Dict[str, Any] = {}
    attributes_list: List[Dict[str, Any]] = []

    class Config:
        from_attributes = True

# Detection response
class DetectionResponse(BaseModel):
    success: bool
    card: Optional[CardResponse] = None
    detected_label: Optional[str] = None
    confidence: Optional[float] = 0.95
    message: str

# TTS response
class TTSResponse(BaseModel):
    audio_url: str
    language: str
    text: str
