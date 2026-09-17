import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from typing import List, Optional
from ..database import get_db, IMAGES_DIR
from ..models import Card, Category, User, CardAttribute
from ..schemas import AdminStatsResponse, UserAdminResponse, UserRoleUpdate

router = APIRouter(prefix="/api/admin", tags=["Admin"])

@router.get("/stats", response_model=AdminStatsResponse)
def get_admin_stats(db: Session = Depends(get_db)):
    total_cards = db.query(Card).count()
    total_categories = db.query(Category).count()
    total_users = db.query(User).count()
    total_attributes = db.query(CardAttribute).count()

    categories = db.query(Category).all()
    category_distribution = []
    for cat in categories:
        count = db.query(Card).filter(Card.category_id == cat.id).count()
        category_distribution.append({
            "category_id": cat.id,
            "category_name": cat.name_en,
            "card_count": count,
            "icon_name": cat.icon_name or "pets",
            "color_hex": cat.color_hex or "#E8F5E9"
        })

    return {
        "total_cards": total_cards,
        "total_categories": total_categories,
        "total_users": total_users,
        "total_attributes": total_attributes,
        "category_distribution": category_distribution
    }

@router.get("/users", response_model=List[UserAdminResponse])
def get_admin_users(db: Session = Depends(get_db)):
    users = db.query(User).all()
    return [
        {
            "id": u.id,
            "name": u.name,
            "email": u.email,
            "role": u.role or "user",
            "is_active": u.is_active if u.is_active is not None else True
        }
        for u in users
    ]

@router.put("/users/{user_id}/role", response_model=UserAdminResponse)
def update_user_role(user_id: int, payload: UserRoleUpdate, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user.role = payload.role
    db.commit()
    db.refresh(user)

    return {
        "id": user.id,
        "name": user.name,
        "email": user.email,
        "role": user.role or "user",
        "is_active": user.is_active if user.is_active is not None else True
    }

@router.post("/upload-image")
async def upload_card_image(file: UploadFile = File(...)):
    os.makedirs(IMAGES_DIR, exist_ok=True)
    extension = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
    unique_filename = f"card_{uuid.uuid4().hex[:10]}.{extension}"
    file_path = os.path.join(IMAGES_DIR, unique_filename)

    contents = await file.read()
    with open(file_path, "wb") as f:
        f.write(contents)

    return {
        "success": True,
        "filename": unique_filename,
        "image_url": f"/static/images/{unique_filename}"
    }
