from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from ..database import get_db
from ..models import Card, CardAttribute, Category
from ..schemas import CardResponse

router = APIRouter(prefix="/api/cards", tags=["Cards"])

CONCEPT_LABELS = {
    "group": "Group",
    "location": "Location",
    "association": "Association",
    "property": "Property",
    "properties": "Properties",
    "use": "Use",
    "action": "Action",
    "attr_5": "Attribute 5",
    "attr_6": "Attribute 6"
}

def format_card_response(card: Card, db: Session) -> dict:
    attributes = db.query(CardAttribute).filter(CardAttribute.card_id == card.id).all()
    attr_dict = {}
    attr_list = []
    
    for attr in attributes:
        label = attr.label or CONCEPT_LABELS.get(attr.key, attr.key.capitalize())
        attr_data = {
            "key": attr.key,
            "label": label,
            "name": label,
            "en": attr.value_en or "",
            "ta": attr.value_ta or "",
            "hi": attr.value_hi or "",
            "ml": attr.value_ml or "",
            "value_en": attr.value_en or "",
            "value_ta": attr.value_ta or "",
            "value_hi": attr.value_hi or "",
            "value_ml": attr.value_ml or "",
            "image_url": attr.image_url or "",
            "attribute_type": attr.key,
            "attribute_image": attr.image_url or ""
        }
        attr_dict[attr.key] = attr_data
        attr_list.append(attr_data)
    
    category_name = ""
    if card.category:
        category_name = card.category.name_en

    title = card.title_en or ""
    image = card.image_url or ""

    return {
        "id": card.id,
        "name": title,
        "title_en": title,
        "title_ta": card.title_ta or "",
        "title_hi": card.title_hi or "",
        "title_ml": card.title_ml or "",
        "category_id": card.category_id,
        "category_name": category_name,
        "subcategory": card.subcategory or "",
        "image_url": image,
        "trigger_image": image,
        "card_image": image,
        "is_published": card.is_published if card.is_published is not None else True,
        "attributes": attr_dict,
        "attributes_list": attr_list
    }

@router.get("", response_model=List[CardResponse])
def get_cards(category_id: Optional[int] = None, db: Session = Depends(get_db)):
    query = db.query(Card)
    if category_id is not None:
        query = query.filter(Card.category_id == category_id)
    cards = query.all()
    return [format_card_response(c, db) for c in cards]

@router.get("/{card_id}", response_model=CardResponse)
def get_card(card_id: int, db: Session = Depends(get_db)):
    card = db.query(Card).filter(Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")
    return format_card_response(card, db)
