from __future__ import annotations

import json
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import ValidationError
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.categories import Categories

from app.core.config import settings
from app.core.image_urls import CARD_IMAGE_URL_PREFIX
from app.db.session import get_db
from app.dependancies.auth import get_current_admin
from app.models.card import Cards
from app.models.card_attr import CardAttributes
from app.models.users import User
from app.schemas.cards import (
    ATTRIBUTE_TYPES,
    CardAttributeCreate,
    CardResponse,
    CardUpdate,
)

router = APIRouter()


@router.get("", response_model=list[CardResponse])
def list_cards(
    category_id: int | None = None,
    db: Session = Depends(get_db),
) -> list[Cards]:
    """Return published cards, optionally filtered by a published category."""
    query = select(Cards).where(Cards.is_published.is_(True))
    if category_id is not None:
        query = query.join(Cards.categories).where(
            Categories.id == category_id,
            Categories.is_published.is_(True),
        )
    return list(db.scalars(query.order_by(Cards.name)).unique().all())


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"}


@router.get("/{card_id}", response_model=CardResponse)
def get_card(card_id: int, db: Session = Depends(get_db)) -> Cards:
    """Get a card by its ID."""
    card = db.get(Cards, card_id)
    if card is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Card not found",
        )
    return card


@router.post("", response_model=CardResponse, status_code=status.HTTP_201_CREATED)
async def create_card(
    name: str = Form(..., min_length=1, max_length=255),
    is_published: bool = Form(False),
    card_image: UploadFile = File(...),
    attributes: str | None = Form(None),
    attribute_images: list[UploadFile] | None = File(None),
    category_ids: str | None = Form(None),
    db: Session = Depends(get_db),
    admin: User = Depends(get_current_admin),
) -> Cards:
    """Create a card and store its image using the generated card ID as its name."""
    if not card_image.content_type or not card_image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="card_image must be an image file",
        )

    extension = Path(card_image.filename or "").suffix.lower()
    if extension not in IMAGE_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Unsupported image type",
        )

    parsed_category_ids: list[int] = []
    if category_ids:
        try:
            raw_category_ids = json.loads(category_ids)
            if not isinstance(raw_category_ids, list) or not all(isinstance(category_id, int) for category_id in raw_category_ids):
                raise ValueError("category_ids must be a JSON array of integers")
            parsed_category_ids = list(dict.fromkeys(int(category_id) for category_id in raw_category_ids))
        except (json.JSONDecodeError, ValueError):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="category_ids must be a valid JSON array of integers",
            ) from None

    categories = db.query(Categories).filter(Categories.id.in_(parsed_category_ids)).all() if parsed_category_ids else []
    if len(categories) != len(parsed_category_ids):
        raise HTTPException(status_code=404, detail="One or more categories were not found")

    parsed_attributes: list[CardAttributeCreate] = []
    if attributes:
        try:
            raw_attributes = json.loads(attributes)
            if not isinstance(raw_attributes, list):
                raise ValueError("attributes must be a JSON array")
            parsed_attributes = [
                CardAttributeCreate.model_validate(attribute)
                for attribute in raw_attributes
            ]
            attribute_types = [
                attribute.attribute_type for attribute in parsed_attributes
            ]
            if len(parsed_attributes) > len(ATTRIBUTE_TYPES):
                raise ValueError("A card can have at most six attributes")
            if len(set(attribute_types)) != len(attribute_types):
                raise ValueError("Each attribute type may only be used once")
        except (json.JSONDecodeError, ValueError, ValidationError) as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="attributes must be a valid JSON array",
            ) from exc

    if attribute_images:
        if len(attribute_images) > len(ATTRIBUTE_TYPES):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="A card can have at most six attribute images",
            )
        if not parsed_attributes:
            parsed_attributes = [
                CardAttributeCreate(attribute_type=ATTRIBUTE_TYPES[index])
                for index in range(len(attribute_images))
            ]
        elif len(attribute_images) != len(parsed_attributes):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="Provide one attribute_images file for each attribute",
            )

    image_bytes = await card_image.read(settings.MAX_UPLOAD_SIZE + 1)
    await card_image.close()
    if len(image_bytes) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image must be {settings.MAX_UPLOAD_SIZE} bytes or smaller",
        )

    attribute_uploads: list[tuple[str, bytes]] = []
    for attribute_image in attribute_images or []:
        if (
            not attribute_image.content_type
            or not attribute_image.content_type.startswith("image/")
        ):
            await attribute_image.close()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="attribute_images must contain only image files",
            )

        attribute_extension = Path(attribute_image.filename or "").suffix.lower()
        if attribute_extension not in IMAGE_EXTENSIONS:
            await attribute_image.close()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported attribute image type",
            )

        attribute_bytes = await attribute_image.read(settings.MAX_UPLOAD_SIZE + 1)
        await attribute_image.close()
        if len(attribute_bytes) > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=(
                    "Each attribute image must be "
                    f"{settings.MAX_UPLOAD_SIZE} bytes or smaller"
                ),
            )
        attribute_uploads.append((attribute_extension, attribute_bytes))

    image_directory = Path(settings.CARD_TEMPLATE_DIR) / "images"
    image_directory.mkdir(parents=True, exist_ok=True)

    card = Cards(
        name=name.strip(),
        user_id=admin.id,
        is_published=is_published,
        attributes=[
            CardAttributes(
                attribute_type=attribute.attribute_type,
                attribute_image=attribute.attribute_image,
            )
            for attribute in parsed_attributes
        ],
        categories=categories,
    )
    db.add(card)
    stored_image_paths: list[Path] = []
    try:
        # Flush assigns the database-generated ID without committing the card yet.
        db.flush()

        image_path = image_directory / f"{card.id}{extension}"
        image_path.write_bytes(image_bytes)
        stored_image_paths.append(image_path)
        card.card_image = f"{CARD_IMAGE_URL_PREFIX}/{image_path.name}"

        for index, ((attribute_extension, attribute_bytes), attribute) in enumerate(
            zip(attribute_uploads, card.attributes, strict=True)
        ):
            attribute_path = (
                image_directory
                / f"{card.id}_attribute_{attribute.attribute_type}{attribute_extension}"
            )
            attribute_path.write_bytes(attribute_bytes)
            stored_image_paths.append(attribute_path)
            attribute.attribute_image = f"{CARD_IMAGE_URL_PREFIX}/{attribute_path.name}"

        db.commit()
        db.refresh(card)
    except Exception:
        db.rollback()
        for stored_image_path in stored_image_paths:
            stored_image_path.unlink(missing_ok=True)
        raise

    return card


@router.patch("/{card_id}", response_model=CardResponse)
def update_card(
    card_id: int,
    payload: CardUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> Cards:
    card = db.get(Cards, card_id)
    if card is None:
        raise HTTPException(status_code=404, detail="Card not found")

    changes = payload.model_dump(exclude_unset=True)
    category_ids = changes.pop("category_ids", None)
    if "name" in changes:
        changes["name"] = changes["name"].strip()
    for key, value in changes.items():
        setattr(card, key, value)

    if category_ids is not None:
        categories = db.query(Categories).filter(Categories.id.in_(category_ids)).all() if category_ids else []
        if len(categories) != len(set(category_ids)):
            raise HTTPException(status_code=404, detail="One or more categories were not found")
        card.categories = categories

    db.commit()
    db.refresh(card)
    return card


@router.patch("/{card_id}/attributes/{attribute_id}", response_model=CardResponse)
async def update_card_attribute(
    card_id: int,
    attribute_id: int,
    attribute_type: str | None = Form(None),
    attribute_image: UploadFile | None = File(None),
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
) -> Cards:
    """Update an attribute type and/or replace its image."""
    card = db.get(Cards, card_id)
    if card is None:
        raise HTTPException(status_code=404, detail="Card not found")

    attribute = db.get(CardAttributes, attribute_id)
    if attribute is None or attribute.card_id != card_id:
        raise HTTPException(status_code=404, detail="Card attribute not found")
    if attribute_type is None and attribute_image is None:
        raise HTTPException(status_code=400, detail="Provide an attribute type or image")

    if attribute_type is not None:
        attribute_type = attribute_type.strip().lower()
        if attribute_type not in ATTRIBUTE_TYPES:
            raise HTTPException(
                status_code=422,
                detail=f"attribute_type must be one of: {', '.join(ATTRIBUTE_TYPES)}",
            )
        duplicate = (
            db.query(CardAttributes)
            .filter(
                CardAttributes.card_id == card_id,
                CardAttributes.attribute_type == attribute_type,
                CardAttributes.id != attribute_id,
            )
            .first()
        )
        if duplicate is not None:
            raise HTTPException(status_code=409, detail="Each attribute type may only be used once")
        attribute.attribute_type = attribute_type

    stored_image_path: Path | None = None
    if attribute_image is not None:
        if not attribute_image.content_type or not attribute_image.content_type.startswith("image/"):
            await attribute_image.close()
            raise HTTPException(status_code=400, detail="attribute_image must be an image file")
        extension = Path(attribute_image.filename or "").suffix.lower()
        if extension not in IMAGE_EXTENSIONS:
            await attribute_image.close()
            raise HTTPException(status_code=400, detail="Unsupported image type")
        image_bytes = await attribute_image.read(settings.MAX_UPLOAD_SIZE + 1)
        await attribute_image.close()
        if len(image_bytes) > settings.MAX_UPLOAD_SIZE:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Image must be {settings.MAX_UPLOAD_SIZE} bytes or smaller",
            )

        image_directory = Path(settings.CARD_TEMPLATE_DIR) / "images"
        image_directory.mkdir(parents=True, exist_ok=True)
        stored_image_path = image_directory / (
            f"{card_id}_attribute_{attribute.attribute_type}{extension}"
        )
        stored_image_path.write_bytes(image_bytes)
        attribute.attribute_image = f"{CARD_IMAGE_URL_PREFIX}/{stored_image_path.name}"

    try:
        db.commit()
        db.refresh(card)
    except Exception:
        db.rollback()
        if stored_image_path is not None:
            stored_image_path.unlink(missing_ok=True)
        raise
    return card
