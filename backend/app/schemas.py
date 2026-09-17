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

class UserAdminResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    is_active: bool

    class Config:
        from_attributes = True

class UserRoleUpdate(BaseModel):
    role: str

# Concept Attribute schemas
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

class CardAttributeInput(BaseModel):
    key: str
    label: Optional[str] = ""
    name: Optional[str] = ""
    value_en: Optional[str] = ""
    value_ta: Optional[str] = ""
    value_hi: Optional[str] = ""
    value_ml: Optional[str] = ""
    image_url: Optional[str] = ""

# Category schemas
class CategoryCreate(BaseModel):
    name_en: str
    name_ta: Optional[str] = ""
    name_hi: Optional[str] = ""
    name_ml: Optional[str] = ""
    description: Optional[str] = ""
    icon_name: Optional[str] = "pets"
    color_hex: Optional[str] = "#E8F5E9"

class CategoryUpdate(BaseModel):
    name_en: Optional[str] = None
    name_ta: Optional[str] = None
    name_hi: Optional[str] = None
    name_ml: Optional[str] = None
    description: Optional[str] = None
    icon_name: Optional[str] = None
    color_hex: Optional[str] = None

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

# Card schemas
class CardCreate(BaseModel):
    category_id: int
    subcategory: Optional[str] = ""
    name: Optional[str] = None
    title_en: Optional[str] = None
    title_ta: Optional[str] = ""
    title_hi: Optional[str] = ""
    title_ml: Optional[str] = ""
    image_url: Optional[str] = ""
    trigger_image: Optional[str] = ""
    is_published: Optional[bool] = True
    attributes: Optional[Dict[str, Any]] = {}
    attributes_list: Optional[List[Dict[str, Any]]] = None

class CardUpdate(BaseModel):
    category_id: Optional[int] = None
    subcategory: Optional[str] = None
    name: Optional[str] = None
    title_en: Optional[str] = None
    title_ta: Optional[str] = None
    title_hi: Optional[str] = None
    title_ml: Optional[str] = None
    image_url: Optional[str] = None
    trigger_image: Optional[str] = None
    is_published: Optional[bool] = None
    attributes: Optional[Dict[str, Any]] = None
    attributes_list: Optional[List[Dict[str, Any]]] = None

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

# Detection schemas
class DetectionResponse(BaseModel):
    success: bool
    card: Optional[CardResponse] = None
    detected_label: Optional[str] = None
    confidence: Optional[float] = 0.95
    message: str

# TTS schemas
class TTSRequest(BaseModel):
    text: str
    lang: Optional[str] = "en"

class TTSResponse(BaseModel):
    audio_url: str
    language: str
    text: str

# Admin Stats schema
class AdminStatsResponse(BaseModel):
    total_cards: int
    total_categories: int
    total_users: int
    total_attributes: int
    category_distribution: List[Dict[str, Any]]
