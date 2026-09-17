import os
import hashlib
from gtts import gTTS
from ..database import AUDIO_DIR

os.makedirs(AUDIO_DIR, exist_ok=True)

LANG_MAPPING = {
    "en": "en",
    "english": "en",
    "ta": "ta",
    "tamil": "ta",
    "hi": "hi",
    "hindi": "hi",
    "ml": "ml",
    "malayalam": "ml"
}

def generate_tts_audio(text: str, lang: str = "en") -> str:
    """
    Generates an MP3 audio file for the given text and language using gTTS.
    Returns the relative URL path to serve the audio file.
    """
    if not text or not text.strip():
        return ""
        
    gtts_lang = LANG_MAPPING.get(lang.lower(), "en")
    
    text_hash = hashlib.md5(f"{text.strip().lower()}_{gtts_lang}".encode('utf-8')).hexdigest()
    filename = f"{text_hash}.mp3"
    filepath = os.path.join(AUDIO_DIR, filename)

    if not os.path.exists(filepath):
        try:
            tts = gTTS(text=text, lang=gtts_lang, slow=False)
            tts.save(filepath)
        except Exception as e:
            print(f"[TTS Error] Failed to generate TTS for '{text}' in '{lang}': {e}")
            return ""

    return f"/static/audio/{filename}"
