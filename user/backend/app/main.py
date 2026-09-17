import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .database import engine, Base, IMAGES_DIR, AUDIO_DIR
from .routers import detect, cards, categories, tts, auth

# Initialize DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Aira Smart Flash Cards - Mobile User API",
    description="Mobile Backend for Card Discovery, Computer Vision Detection, and Multilingual Audio",
    version="2.0.0"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Shared Static Directories for Mobile Images and Audio
app.mount("/static/images", StaticFiles(directory=IMAGES_DIR), name="images")
app.mount("/static/audio", StaticFiles(directory=AUDIO_DIR), name="audio")

# Include User Routers
app.include_router(detect.router)
app.include_router(cards.router)
app.include_router(categories.router)
app.include_router(tts.router)
app.include_router(auth.router)

@app.get("/")
def root():
    return {
        "status": "online",
        "service": "aira-user-backend",
        "version": "2.0.0",
        "endpoints": [
            "/api/detect",
            "/api/cards",
            "/api/categories",
            "/api/tts",
            "/api/auth"
        ]
    }

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "user-backend"}
