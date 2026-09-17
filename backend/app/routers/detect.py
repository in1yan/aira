from fastapi import APIRouter, Depends, UploadFile, File, HTTPException
from sqlalchemy.orm import Session
from ..database import get_db
from ..schemas import DetectionResponse
from ..services.vision_service import process_card_image
from .cards import format_card_response

router = APIRouter(prefix="/api/detect", tags=["Detection"])

@router.post("", response_model=DetectionResponse)
async def detect_card(file: UploadFile = File(...), db: Session = Depends(get_db)):
    """
    Receives image from mobile camera or web scanner, applies OpenCV vision processing,
    and returns the detected flash card with all its 6 attributes.
    """
    try:
        contents = await file.read()
        matched_card, message = process_card_image(contents, db)

        if not matched_card:
            return {
                "success": False,
                "card": None,
                "detected_label": None,
                "confidence": 0.0,
                "message": message or "No flash card matched in image."
            }

        card_data = format_card_response(matched_card, db)

        return {
            "success": True,
            "card": card_data,
            "detected_label": matched_card.title_en,
            "confidence": 0.95,
            "message": message
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image processing failed: {str(e)}")
