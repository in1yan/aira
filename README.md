# Aira - Smart Flash Card Multi-Modal Learning Ecosystem

A comprehensive AI-assisted multi-modal learning system featuring:
- **Admin Portal**: Web dashboard to create smart flash cards with 7 images (1 trigger + 6 concept attributes), categories, and subcategories.
- **Mobile User App**: Flutter-based mobile application with OpenCV ORB visual flash card scanning, interactive attribute exploration, and multilingual TTS.
- **Unified Backend API**: Consolidated FastAPI service serving both Web Admin and Mobile User endpoints on a single port (`8000`).
- **Shared Data Layer**: SQLite database and persistent media asset storage.

---

## 📁 Project Directory Structure

```text
aira/
├── backend/                       # Unified Backend API & Services (Port 8000)
│   ├── app/
│   │   ├── database.py            # SQLite DB & Storage Directory Paths
│   │   ├── models.py              # SQLAlchemy Models (Cards, Categories, Attributes, Users)
│   │   ├── schemas.py             # Pydantic Schemas
│   │   ├── main.py                # Unified FastAPI App (Admin + User Mobile API)
│   │   ├── routers/
│   │   │   ├── admin.py           # Admin Stats, User Management & Image Uploads
│   │   │   ├── cards.py           # Card Full CRUD & Attribute Management
│   │   │   ├── categories.py      # Category CRUD Management
│   │   │   ├── detect.py          # OpenCV ORB Computer Vision Flash Card Recognition
│   │   │   ├── tts.py             # Multilingual Text-To-Speech (EN, TA, HI, ML)
│   │   │   └── auth.py            # User Authentication & Profile
│   │   └── services/
│   │       ├── vision_service.py  # ORB Descriptor & Histogram Vision Matcher
│   │       └── tts_service.py     # gTTS Speech Generator
│   ├── requirements.txt
│   └── run.py                     # Unified Backend Runner
│
├── admin/
│   └── frontend/                  # Web Admin Dashboard UI
│       ├── index.html             # Responsive Glassmorphic Admin Dashboard
│       ├── admin.css              # Styling & Visual Design System
│       └── admin.js               # Client Logic & 7-Image Slot Uploaders
│
├── user/
│   └── frontend/                  # Flutter Mobile Application
│       ├── lib/                   # Flutter Source Code (Screens, Models, Services)
│       ├── android/               # Android Platform Configuration
│       ├── web/                   # Web Platform Configuration
│       ├── windows/               # Windows Platform Configuration
│       └── pubspec.yaml           # Flutter Dependencies & Configuration
│
├── shared/                        # Shared Persistent Data & Media Assets
│   ├── data/
│   │   └── aira.db                # SQLite Database
│   └── uploads/
│       ├── images/                # Trigger & Attribute Images
│       └── audio/                 # Generated Multilingual Audio Clips
│
├── run_all.py                     # Master launcher to start the unified backend server
└── README.md
```

---

## 🚀 Running the Project

### Option 1: Run Unified Backend with Master Launcher
From the root directory:
```bash
python run_all.py
```
- **Web Admin Portal**: `http://127.0.0.1:8000/admin/` (or `http://127.0.0.1:8000/`)
- **Mobile User API**: `http://127.0.0.1:8000/api`
- **Interactive Swagger Docs**: `http://127.0.0.1:8000/docs`

---

### Option 2: Run Backend Directory Directly
```bash
cd backend
python run.py
```

---

### Option 3: Run Flutter Mobile App
```bash
cd user/frontend
flutter run
```
To run on a connected Android phone over USB:
```bash
# Forward port 8000 so the phone communicates with localhost backend:
adb reverse tcp:8000 tcp:8000

# Launch Flutter app:
flutter run
```
