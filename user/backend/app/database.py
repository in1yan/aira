import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

APP_DIR = os.path.dirname(os.path.abspath(__file__))               # user/backend/app
BACKEND_DIR = os.path.dirname(APP_DIR)                             # user/backend
USER_DIR = os.path.dirname(BACKEND_DIR)                            # user
ROOT_DIR = os.path.dirname(USER_DIR)                               # aira-app

SHARED_DIR = os.path.join(ROOT_DIR, "shared")
DATA_DIR = os.path.join(SHARED_DIR, "data")
UPLOADS_DIR = os.path.join(SHARED_DIR, "uploads")
IMAGES_DIR = os.path.join(UPLOADS_DIR, "images")
AUDIO_DIR = os.path.join(UPLOADS_DIR, "audio")

# Ensure directories exist
for directory in [DATA_DIR, UPLOADS_DIR, IMAGES_DIR, AUDIO_DIR]:
    os.makedirs(directory, exist_ok=True)

DB_PATH = os.path.join(DATA_DIR, "aira.db")
SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
