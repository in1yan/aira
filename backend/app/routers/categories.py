from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from ..database import get_db
from ..models import Category, Card
from ..schemas import CategoryResponse, CategoryCreate, CategoryUpdate

router = APIRouter(prefix="/api/categories", tags=["Categories"])

def format_category_response(cat: Category, db: Session) -> dict:
    card_count = db.query(Card).filter(Card.category_id == cat.id).count()
    return {
        "id": cat.id,
        "name_en": cat.name_en,
        "name_ta": cat.name_ta or "",
        "name_hi": cat.name_hi or "",
        "name_ml": cat.name_ml or "",
        "icon_name": cat.icon_name or "pets",
        "color_hex": cat.color_hex or "#E8F5E9",
        "description": cat.description or "",
        "card_count": card_count
    }

@router.get("", response_model=List[CategoryResponse])
def get_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).all()
    return [format_category_response(cat, db) for cat in categories]

@router.get("/{category_id}", response_model=CategoryResponse)
def get_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )
    return format_category_response(category, db)

@router.post("", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(payload: CategoryCreate, db: Session = Depends(get_db)):
    name_clean = (payload.name_en or "").strip()
    if not name_clean:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Category English name (name_en) cannot be empty"
        )

    # Check for duplicate category name (case-insensitive)
    existing = db.query(Category).filter(Category.name_en.ilike(name_clean)).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Category with name '{name_clean}' already exists"
        )

    new_cat = Category(
        name_en=name_clean,
        name_ta=(payload.name_ta or "").strip(),
        name_hi=(payload.name_hi or "").strip(),
        name_ml=(payload.name_ml or "").strip(),
        description=(payload.description or "").strip(),
        icon_name=(payload.icon_name or "pets").strip(),
        color_hex=(payload.color_hex or "#E8F5E9").strip(),
    )
    db.add(new_cat)
    db.commit()
    db.refresh(new_cat)

    return format_category_response(new_cat, db)

@router.put("/{category_id}", response_model=CategoryResponse)
def update_category(category_id: int, payload: CategoryUpdate, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )

    if payload.name_en is not None:
        name_clean = payload.name_en.strip()
        if not name_clean:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Category English name cannot be empty"
            )
        # Check if another category already has this name
        existing = db.query(Category).filter(
            Category.name_en.ilike(name_clean),
            Category.id != category_id
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Category with name '{name_clean}' already exists"
            )
        category.name_en = name_clean

    if payload.name_ta is not None:
        category.name_ta = payload.name_ta.strip()
    if payload.name_hi is not None:
        category.name_hi = payload.name_hi.strip()
    if payload.name_ml is not None:
        category.name_ml = payload.name_ml.strip()
    if payload.description is not None:
        category.description = payload.description.strip()
    if payload.icon_name is not None:
        category.icon_name = payload.icon_name.strip()
    if payload.color_hex is not None:
        category.color_hex = payload.color_hex.strip()

    db.commit()
    db.refresh(category)
    return format_category_response(category, db)

@router.delete("/{category_id}")
def delete_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category with ID {category_id} not found"
        )

    category_name = category.name_en
    db.delete(category)
    db.commit()
    return {"message": f"Category '{category_name}' deleted successfully", "id": category_id}
