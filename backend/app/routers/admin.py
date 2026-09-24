import os
import io
import json
import uuid
import zipfile
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from fastapi.responses import FileResponse, StreamingResponse
from sqlalchemy.orm import Session
from typing import List, Optional
from ..database import get_db, IMAGES_DIR, AUDIO_DIR, DB_PATH, DATA_DIR
from ..models import Card, Category, User, CardAttribute
from ..schemas import AdminStatsResponse, UserAdminResponse, UserRoleUpdate
from ..services import storage_service

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

    local_url = f"/static/images/{unique_filename}"
    s3_url = None
    s3_key = None
    storage_mode = "local"

    # Attempt S3 cloud bucket upload
    try:
        s3_key = f"uploads/images/{unique_filename}"
        s3_url, s3_key = storage_service.upload_bytes_to_s3(
            file_bytes=contents,
            key=s3_key,
            content_type=file.content_type
        )
        storage_mode = "s3"
    except Exception as e:
        # S3 upload failed or not configured, fallback to local static URL
        print(f"[Storage Service Warning] S3 upload skipped/failed ({e}), using local static storage.")

    return {
        "success": True,
        "filename": unique_filename,
        "image_url": s3_url or local_url,
        "s3_url": s3_url,
        "s3_key": s3_key,
        "local_url": local_url,
        "storage_mode": storage_mode
    }

@router.post("/sync-images-to-s3")
def sync_all_images_to_s3(db: Session = Depends(get_db)):
    """
    Scans all cards and card attributes in the database, uploads their local images
    to the configured S3 storage bucket, and updates the database with presigned S3 URLs.
    """
    updated_cards = []
    updated_attributes = []
    errors = []

    # 1. Sync Cards
    cards = db.query(Card).all()
    for card in cards:
        if card.image_url:
            clean_filename = os.path.basename(card.image_url.split("?")[0])
            local_path = os.path.join(IMAGES_DIR, clean_filename)
            if os.path.exists(local_path):
                try:
                    s3_key = f"uploads/images/{clean_filename}"
                    s3_url, key = storage_service.upload_file_path_to_s3(
                        file_path=local_path,
                        custom_key=s3_key
                    )
                    card.image_url = s3_url
                    updated_cards.append({
                        "card_id": card.id,
                        "title": card.title_en,
                        "filename": clean_filename,
                        "url": s3_url,
                        "key": key
                    })
                except Exception as e:
                    errors.append(f"Card #{card.id} ({card.title_en}): {str(e)}")

    # 2. Sync Card Attributes
    attributes = db.query(CardAttribute).all()
    for attr in attributes:
        if attr.image_url:
            clean_filename = os.path.basename(attr.image_url.split("?")[0])
            local_path = os.path.join(IMAGES_DIR, clean_filename)
            if os.path.exists(local_path):
                try:
                    s3_key = f"uploads/images/{clean_filename}"
                    s3_url, key = storage_service.upload_file_path_to_s3(
                        file_path=local_path,
                        custom_key=s3_key
                    )
                    attr.image_url = s3_url
                    updated_attributes.append({
                        "attribute_id": attr.id,
                        "card_id": attr.card_id,
                        "key": attr.key,
                        "filename": clean_filename,
                        "url": s3_url,
                        "s3_key": key
                    })
                except Exception as e:
                    errors.append(f"Attribute #{attr.id} (Card #{attr.card_id}, {attr.key}): {str(e)}")

    db.commit()

    return {
        "success": True,
        "updated_cards_count": len(updated_cards),
        "updated_attributes_count": len(updated_attributes),
        "updated_cards": updated_cards,
        "updated_attributes": updated_attributes,
        "errors": errors
    }


def _generate_visual_context_manifest(db: Session) -> dict:
    categories = db.query(Category).all()
    cards = db.query(Card).all()
    users = db.query(User).all()

    cats_data = [
        {
            "id": c.id,
            "name_en": c.name_en,
            "name_ta": c.name_ta,
            "name_hi": c.name_hi,
            "name_ml": c.name_ml,
            "description": c.description,
            "icon_name": c.icon_name,
            "color_hex": c.color_hex,
        }
        for c in categories
    ]

    cards_data = []
    for card in cards:
        attrs = db.query(CardAttribute).filter(CardAttribute.card_id == card.id).all()
        attr_list = [
            {
                "key": a.key,
                "label": a.label,
                "value_en": a.value_en,
                "value_ta": a.value_ta,
                "value_hi": a.value_hi,
                "value_ml": a.value_ml,
                "image_url": a.image_url,
                "image_filename": os.path.basename(a.image_url) if a.image_url else None
            }
            for a in attrs
        ]

        cards_data.append({
            "id": card.id,
            "category_id": card.category_id,
            "category_name": card.category.name_en if card.category else None,
            "subcategory": card.subcategory,
            "title_en": card.title_en,
            "title_ta": card.title_ta,
            "title_hi": card.title_hi,
            "title_ml": card.title_ml,
            "trigger_image_url": card.image_url,
            "trigger_image_filename": os.path.basename(card.image_url) if card.image_url else None,
            "is_published": card.is_published,
            "attributes_visual_context": attr_list
        })

    return {
        "export_metadata": {
            "application": "Aira Smart Flash Cards",
            "version": "2.0.0",
            "exported_at": datetime.utcnow().isoformat() + "Z",
            "total_categories": len(cats_data),
            "total_cards": len(cards_data),
            "total_users": len(users)
        },
        "categories": cats_data,
        "cards": cards_data
    }

@router.get("/export/bundle")
def export_database_bundle(db: Session = Depends(get_db)):
    """
    Exports a comprehensive ZIP archive containing:
    1. SQLite Database (`data/aira.db`)
    2. All Visual Context Images (`images/*`)
    3. Audio Pronunciations (`audio/*`)
    4. Visual Context JSON Manifest (`visual_context_manifest.json`)
    5. Dataset Documentation (`README.txt`)
    """
    manifest_data = _generate_visual_context_manifest(db)
    zip_buffer = io.BytesIO()

    with zipfile.ZipFile(zip_buffer, "w", zipfile.ZIP_DEFLATED) as zip_file:
        # 1. Add SQLite Database file
        if os.path.exists(DB_PATH):
            zip_file.write(DB_PATH, arcname="data/aira.db")

        # 2. Add Visual Context Manifest JSON
        manifest_json_str = json.dumps(manifest_data, indent=2, ensure_ascii=False)
        zip_file.writestr("visual_context_manifest.json", manifest_json_str)

        # 3. Add Images (Trigger images & 6-concept attribute images)
        if os.path.exists(IMAGES_DIR):
            for root, _, files in os.walk(IMAGES_DIR):
                for f in files:
                    file_full_path = os.path.join(root, f)
                    arc_path = os.path.join("images", f)
                    zip_file.write(file_full_path, arcname=arc_path)

        # 4. Add Audio files
        if os.path.exists(AUDIO_DIR):
            for root, _, files in os.walk(AUDIO_DIR):
                for f in files:
                    file_full_path = os.path.join(root, f)
                    arc_path = os.path.join("audio", f)
                    zip_file.write(file_full_path, arcname=arc_path)

        # 5. Add README documentation inside the archive
        readme_content = f"""========================================================================
  AIRA SMART FLASHCARDS - DATABASE & VISUAL CONTEXT DATASET
========================================================================

Exported At: {manifest_data["export_metadata"]["exported_at"]}
Total Flashcards: {manifest_data["export_metadata"]["total_cards"]}
Total Categories: {manifest_data["export_metadata"]["total_categories"]}

PACKAGE CONTENTS:
-----------------
1. data/aira.db
   - Full SQLite 3 relational database containing users, categories,
     cards, and the 6 cognitive dimension attributes.

2. visual_context_manifest.json
   - Complete JSON dataset describing all flashcards with their 4-language
     labels (English, Tamil, Hindi, Malayalam), trigger images, and 6-concept
     visual attributes (Group, Use, Action, Location, Association, Properties).

3. images/
   - Visual context image assets including card trigger images used for
     computer vision recognition and dimension attribute graphics.

4. audio/
   - Multilingual synthesized speech clips (gTTS MP3 files).

========================================================================
"""
        zip_file.writestr("README.txt", readme_content)

    zip_buffer.seek(0)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    filename = f"aira_db_with_visual_context_{timestamp}.zip"

    return StreamingResponse(
        zip_buffer,
        media_type="application/zip",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Access-Control-Expose-Headers": "Content-Disposition"
        }
    )

@router.get("/export/db")
def export_raw_db():
    """
    Directly downloads the raw SQLite database file (`aira.db`).
    """
    if not os.path.exists(DB_PATH):
        raise HTTPException(
            status_code=404,
            detail="SQLite database file not found. When connected to a remote PostgreSQL database, raw SQLite file download is unavailable. Please use JSON or bundle export."
        )
    
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    return FileResponse(
        DB_PATH,
        media_type="application/x-sqlite3",
        filename=f"aira_{timestamp}.db"
    )

@router.get("/export/json")
def export_visual_context_json(db: Session = Depends(get_db)):
    """
    Directly returns the Visual Context JSON manifest.
    """
    manifest_data = _generate_visual_context_manifest(db)
    json_bytes = json.dumps(manifest_data, indent=2, ensure_ascii=False).encode('utf-8')
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    
    return StreamingResponse(
        io.BytesIO(json_bytes),
        media_type="application/json",
        headers={
            "Content-Disposition": f'attachment; filename="aira_visual_context_{timestamp}.json"',
            "Access-Control-Expose-Headers": "Content-Disposition"
        }
    )
