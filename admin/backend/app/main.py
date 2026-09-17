import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, RedirectResponse

from .database import engine, Base, IMAGES_DIR, AUDIO_DIR, FRONTEND_DIR
from .routers import cards, categories, admin

# Initialize DB tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Aira Smart Flash Cards - Admin API",
    description="Admin Portal Backend for Managing Flash Cards, Attributes, and Media Assets",
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

# Mount Shared Static Directories
app.mount("/static/images", StaticFiles(directory=IMAGES_DIR), name="images")
app.mount("/static/audio", StaticFiles(directory=AUDIO_DIR), name="audio")

# Mount Admin Frontend Static Assets
if os.path.exists(FRONTEND_DIR):
    app.mount("/static/admin", StaticFiles(directory=FRONTEND_DIR), name="admin_static")

# Include Admin Routers
app.include_router(cards.router)
app.include_router(categories.router)
app.include_router(admin.router)

@app.get("/")
def root():
    return RedirectResponse(url="/admin/")

@app.get("/admin")
@app.get("/admin/")
def serve_admin():
    index_file = os.path.join(FRONTEND_DIR, "index.html")
    if os.path.exists(index_file):
        return FileResponse(index_file)
    return {"message": "Admin frontend not found. Please ensure admin/frontend/index.html exists."}

@app.get("/health")
def health_check():
    return {"status": "ok", "service": "admin-backend"}
