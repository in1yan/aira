import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Path calculations relative to repository root
APP_DIR = os.path.dirname(os.path.abspath(__file__))               # backend/app
BACKEND_DIR = os.path.dirname(APP_DIR)                             # backend
ROOT_DIR = os.path.dirname(BACKEND_DIR)                              # repo root

# Load environment variables from .env if present
try:
    from dotenv import load_dotenv
    load_dotenv(os.path.join(ROOT_DIR, ".env"))
    load_dotenv(os.path.join(BACKEND_DIR, ".env"))
    load_dotenv()
except ImportError:
    pass

SHARED_DIR = os.path.join(ROOT_DIR, "shared")
DATA_DIR = os.path.join(SHARED_DIR, "data")
UPLOADS_DIR = os.path.join(SHARED_DIR, "uploads")
IMAGES_DIR = os.path.join(UPLOADS_DIR, "images")
AUDIO_DIR = os.path.join(UPLOADS_DIR, "audio")
FRONTEND_DIR = os.path.join(ROOT_DIR, "admin", "frontend")

# Ensure required storage directories exist
for directory in [DATA_DIR, UPLOADS_DIR, IMAGES_DIR, AUDIO_DIR]:
    os.makedirs(directory, exist_ok=True)

DB_PATH = os.path.join(DATA_DIR, "aira.db")

# Retrieve database connection string from environment variable (DATABASE_URL / POSTGRES_URL / DB_URL)
raw_db_url = os.getenv("DATABASE_URL") or os.getenv("POSTGRES_URL") or os.getenv("DB_URL")

if raw_db_url and raw_db_url.strip():
    db_url = raw_db_url.strip()
    # Normalize postgres:// to postgresql:// for SQLAlchemy 1.4+ / 2.0+ compatibility
    if db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql://", 1)
    SQLALCHEMY_DATABASE_URL = db_url
else:
    # Default to local SQLite database
    SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

from sqlalchemy import event, text
from sqlalchemy.engine import Engine

# Configure engine based on database dialect
if SQLALCHEMY_DATABASE_URL.startswith("sqlite"):
    IS_SQLITE = True
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        connect_args={"check_same_thread": False}
    )

    @event.listens_for(Engine, "connect")
    def set_sqlite_pragma(dbapi_connection, connection_record):
        try:
            cursor = dbapi_connection.cursor()
            cursor.execute("PRAGMA foreign_keys=ON")
            cursor.close()
        except Exception:
            pass
else:
    IS_SQLITE = False
    engine = create_engine(
        SQLALCHEMY_DATABASE_URL,
        pool_pre_ping=True,
        pool_recycle=300
    )

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def ensure_schema_migrations():
    """
    Auto-migrates existing tables to ensure new columns (e.g. parent_id on categories)
    exist in the current database.
    """
    try:
        with engine.begin() as conn:
            if IS_SQLITE:
                # Check categories table
                cols = [r[1] for r in conn.execute(text("PRAGMA table_info(categories);")).fetchall()]
                if cols and "parent_id" not in cols:
                    conn.execute(text("ALTER TABLE categories ADD COLUMN parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE;"))
                    conn.execute(text("CREATE INDEX IF NOT EXISTS ix_categories_parent_id ON categories (parent_id);"))
            else:
                conn.execute(text("ALTER TABLE categories ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES categories(id) ON DELETE CASCADE;"))
                conn.execute(text("CREATE INDEX IF NOT EXISTS ix_categories_parent_id ON categories (parent_id);"))
    except Exception as e:
        print(f"[Database] Migration notice: {e}")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


