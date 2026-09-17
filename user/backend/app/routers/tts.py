from fastapi import APIRouter, Query
from ..schemas import TTSResponse
from ..services.tts_service import generate_tts_audio

router = APIRouter(prefix="/api/tts", tags=["TTS"])

@router.get("", response_model=TTSResponse)
def get_tts(text: str = Query(..., description="Text to synthesize to speech"), lang: str = Query("en", description="Language code: en, ta, hi, ml")):
    audio_url = generate_tts_audio(text, lang)
    return {
        "audio_url": audio_url,
        "language": lang,
        "text": text
    }
