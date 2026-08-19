from fastapi import APIRouter, File, HTTPException, UploadFile, status, Depends


from app.core.config import settings
from app.services.card_detection import CardDetectionError, get_card_recognizer
from app.dependancies.auth import get_current_user

router = APIRouter()


@router.post(
    "",
    status_code=status.HTTP_200_OK,
    summary="Detect a card from an uploaded image",
    dependencies=[Depends(get_current_user)],
)
async def detect_card(image: UploadFile = File(...)) -> dict:
    """Match an uploaded card image against templates without storing the upload."""
    if not image.content_type or not image.content_type.startswith("image/"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Upload an image file",
        )

    image_bytes = await image.read(settings.MAX_UPLOAD_SIZE + 1)
    await image.close()

    if len(image_bytes) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"Image must be {settings.MAX_UPLOAD_SIZE} bytes or smaller",
        )

    try:
        card, scores = get_card_recognizer().recognize(
            image_bytes,
            min_inliers=settings.CARD_MIN_INLIERS,
            min_ratio=settings.CARD_MIN_INLIER_RATIO,
        )
    except CardDetectionError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc

    return {
        "card": card,
        "matched": card is not None,
        "scores": scores,
    }
