from __future__ import annotations

import json
from pathlib import Path

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.session import get_db
from app.dependancies.auth import get_current_admin
from app.models.card import Cards
from app.models.card_attr import CardAttributes
from app.models.users import User
from app.schemas.cards import CardAttributeCreate, CardResponse

router = APIRouter()


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
        except (json.JSONDecodeError, ValueError, ValidationError) as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="attributes must be a valid JSON array",
            ) from exc

    if attribute_images:
        if not parsed_attributes:
            parsed_attributes = [
                CardAttributeCreate() for _ in attribute_images
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
            CardAttributes(attribute_image=attribute.attribute_image)
            for attribute in parsed_attributes
        ],
    )
    db.add(card)
    stored_image_paths: list[Path] = []
    try:
        # Flush assigns the database-generated ID without committing the card yet.
        db.flush()

        image_path = image_directory / f"{card.id}{extension}"
        image_path.write_bytes(image_bytes)
        stored_image_paths.append(image_path)
        card.card_image = image_path.as_posix()

        for index, ((attribute_extension, attribute_bytes), attribute) in enumerate(
            zip(attribute_uploads, card.attributes, strict=True)
        ):
            attribute_path = (
                image_directory / f"{card.id}_attribute_{index}{attribute_extension}"
            )
            attribute_path.write_bytes(attribute_bytes)
            stored_image_paths.append(attribute_path)
            attribute.attribute_image = attribute_path.as_posix()

        db.commit()
        db.refresh(card)
    except Exception:
        db.rollback()
        for stored_image_path in stored_image_paths:
            stored_image_path.unlink(missing_ok=True)
        raise

    return card
