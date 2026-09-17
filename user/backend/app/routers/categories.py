from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Category, Card
from ..schemas import CategoryResponse

router = APIRouter(prefix="/api/categories", tags=["Categories"])

@router.get("", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).all()
    result = []
    for cat in categories:
        card_count = db.query(Card).filter(Card.category_id == cat.id).count()
        result.append({
            "id": cat.id,
            "name_en": cat.name_en,
            "name_ta": cat.name_ta,
            "name_hi": cat.name_hi,
            "name_ml": cat.name_ml,
            "icon_name": cat.icon_name,
            "color_hex": cat.color_hex,
            "description": cat.description,
            "card_count": card_count
        })
    return result
