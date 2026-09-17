from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional, Dict
from ..database import get_db
from ..models import Card, CardAttribute, Category
from ..schemas import CardResponse, CardCreate, CardUpdate

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

@router.post("", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
def create_card(payload: CardCreate, db: Session = Depends(get_db)):
    cat = db.query(Category).filter(Category.id == payload.category_id).first()
    if not cat:
        raise HTTPException(status_code=400, detail=f"Category {payload.category_id} not found")

    title = payload.name or payload.title_en or ""
    image = payload.trigger_image or payload.image_url or ""

    new_card = Card(
        category_id=payload.category_id,
        subcategory=payload.subcategory or "",
        title_en=title,
        title_ta=payload.title_ta or "",
        title_hi=payload.title_hi or "",
        title_ml=payload.title_ml or "",
        image_url=image,
        is_published=payload.is_published if payload.is_published is not None else True,
    )
    db.add(new_card)
    db.commit()
    db.refresh(new_card)

    if payload.attributes_list:
        for item in payload.attributes_list:
            key = item.get("key") or f"attr_{len(new_card.attributes) + 1}"
            label = item.get("name") or item.get("label") or CONCEPT_LABELS.get(key, key.capitalize())
            attr = CardAttribute(
                card_id=new_card.id,
                key=key,
                label=label,
                value_en=item.get("value_en") or item.get("en", ""),
                value_ta=item.get("value_ta") or item.get("ta", ""),
                value_hi=item.get("value_hi") or item.get("hi", ""),
                value_ml=item.get("value_ml") or item.get("ml", ""),
                image_url=item.get("image_url") or item.get("attribute_image", "")
            )
            db.add(attr)
        db.commit()
    elif payload.attributes:
        for key, vals in payload.attributes.items():
            if isinstance(vals, dict):
                label = vals.get("name") or vals.get("label") or CONCEPT_LABELS.get(key, key.capitalize())
                attr = CardAttribute(
                    card_id=new_card.id,
                    key=key,
                    label=label,
                    value_en=vals.get("en") or vals.get("value_en", ""),
                    value_ta=vals.get("ta") or vals.get("value_ta", ""),
                    value_hi=vals.get("hi") or vals.get("value_hi", ""),
                    value_ml=vals.get("ml") or vals.get("value_ml", ""),
                    image_url=vals.get("image_url") or vals.get("attribute_image", "")
                )
                db.add(attr)
        db.commit()

    return format_card_response(new_card, db)

@router.put("/{card_id}", response_model=CardResponse)
def update_card(card_id: int, payload: CardUpdate, db: Session = Depends(get_db)):
    card = db.query(Card).filter(Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")

    if payload.category_id is not None:
        cat = db.query(Category).filter(Category.id == payload.category_id).first()
        if not cat:
            raise HTTPException(status_code=400, detail=f"Category {payload.category_id} not found")
        card.category_id = payload.category_id

    if payload.subcategory is not None:
        card.subcategory = payload.subcategory
    if payload.name is not None:
        card.title_en = payload.name
    elif payload.title_en is not None:
        card.title_en = payload.title_en
        
    if payload.title_ta is not None:
        card.title_ta = payload.title_ta
    if payload.title_hi is not None:
        card.title_hi = payload.title_hi
    if payload.title_ml is not None:
        card.title_ml = payload.title_ml
        
    if payload.trigger_image is not None:
        card.image_url = payload.trigger_image
    elif payload.image_url is not None:
        card.image_url = payload.image_url
        
    if payload.is_published is not None:
        card.is_published = payload.is_published

    if payload.attributes_list is not None:
        db.query(CardAttribute).filter(CardAttribute.card_id == card.id).delete()
        for item in payload.attributes_list:
            key = item.get("key") or f"attr_{len(card.attributes) + 1}"
            label = item.get("name") or item.get("label") or CONCEPT_LABELS.get(key, key.capitalize())
            attr = CardAttribute(
                card_id=card.id,
                key=key,
                label=label,
                value_en=item.get("value_en") or item.get("en", ""),
                value_ta=item.get("value_ta") or item.get("ta", ""),
                value_hi=item.get("value_hi") or item.get("hi", ""),
                value_ml=item.get("value_ml") or item.get("ml", ""),
                image_url=item.get("image_url") or item.get("attribute_image", "")
            )
            db.add(attr)
    elif payload.attributes is not None:
        db.query(CardAttribute).filter(CardAttribute.card_id == card.id).delete()
        for key, vals in payload.attributes.items():
            if isinstance(vals, dict):
                label = vals.get("name") or vals.get("label") or CONCEPT_LABELS.get(key, key.capitalize())
                attr = CardAttribute(
                    card_id=card.id,
                    key=key,
                    label=label,
                    value_en=vals.get("en") or vals.get("value_en", ""),
                    value_ta=vals.get("ta") or vals.get("value_ta", ""),
                    value_hi=vals.get("hi") or vals.get("value_hi", ""),
                    value_ml=vals.get("ml") or vals.get("value_ml", ""),
                    image_url=vals.get("image_url") or vals.get("attribute_image", "")
                )
                db.add(attr)

    db.commit()
    db.refresh(card)
    return format_card_response(card, db)

@router.delete("/{card_id}")
def delete_card(card_id: int, db: Session = Depends(get_db)):
    card = db.query(Card).filter(Card.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")

    db.delete(card)
    db.commit()
    return {"message": "Card deleted successfully", "id": card_id}
