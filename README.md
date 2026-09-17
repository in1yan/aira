# Aira - Smart Flash Card Multi-Modal Learning Ecosystem

A comprehensive AI-assisted multi-modal learning system featuring:
- **Admin Portal**: Web dashboard to create smart flash cards with 7 images (1 trigger + 6 concept attributes), categories, and subcategories.
- **Mobile User App**: Flutter-based mobile application with OpenCV ORB visual flash card scanning, interactive attribute exploration, and multilingual TTS.
- **Shared Data Layer**: SQLite database and persistent media asset storage shared between Admin and User backends.

---

## 📁 Project Directory Structure

```text
aira-app/
├── admin/
│   ├── frontend/                  # Web Admin Dashboard UI
│   │   ├── index.html             # Responsive Glassmorphic Admin Dashboard
│   │   ├── admin.css              # Styling & Visual Design System
│   │   └── admin.js               # Client Logic & 7-Image Slot Uploaders
│   └── backend/                   # Admin Backend API & Services
│       ├── app/
│       │   ├── database.py        # Shared SQLite DB & Storage Configuration
│       │   ├── models.py          # SQLAlchemy Models (Cards, Categories, Attributes)
│       │   ├── schemas.py         # Pydantic Schemas
│       │   ├── main.py            # Admin FastAPI App (Port 8001)
│       │   └── routers/
│       │       ├── admin.py       # Admin Stats, User Management & Image Uploads
│       │       ├── cards.py       # Card Creation, 7-Image Support & Attribute CRUD
│       │       └── categories.py  # Category Management
│       ├── requirements.txt
│       └── run.py                 # Admin Backend Runner
│
├── user/
│   ├── frontend/                  # Flutter Mobile Application
│   │   ├── lib/                   # Flutter Source Code (Screens, Models, Services)
│   │   ├── android/               # Android Platform Configuration
│   │   ├── web/                   # Web Platform Configuration
│   │   ├── windows/               # Windows Platform Configuration
│   │   └── pubspec.yaml           # Flutter Dependencies & Configuration
│   └── backend/                   # User Mobile API Server & Vision Processing
│       ├── app/
│       │   ├── database.py        # Shared SQLite DB & Storage Configuration
│       │   ├── models.py          # SQLAlchemy Models
│       │   ├── schemas.py         # Pydantic Schemas
│       │   ├── main.py            # User Mobile FastAPI App (Port 8000)
│       │   ├── routers/
│       │   │   ├── detect.py      # OpenCV ORB Computer Vision Flash Card Recognition
│       │   │   ├── cards.py       # Flash Cards Discovery API for Mobile
│       │   │   ├── categories.py  # Category Listings for Mobile
│       │   │   ├── tts.py         # Multilingual Text-To-Speech (EN, TA, HI, ML)
│       │   │   └── auth.py        # User Authentication & Profile
│       │   └── services/
│       │       ├── vision_service.py # ORB Descriptor & Histogram Vision Matcher
│       │       └── tts_service.py    # gTTS Speech Generator
│       ├── requirements.txt
│       └── run.py                 # User Backend Runner
│
├── shared/                        # Shared Persistent Data & Media Assets
│   ├── data/
│   │   └── aira.db                # Shared SQLite Database
│   └── uploads/
│       ├── images/                # Shared Trigger & Attribute Images
│       └── audio/                 # Generated Multilingual Audio Clips
│
├── run_all.py                     # Master launcher to start both backends simultaneously
└── README.md
```

---

## 🚀 Running the Project

### Option 1: Run All Backends with One Command
From the root directory:
```bash
python run_all.py
```
- **Mobile User Backend**: `http://127.0.0.1:8000`
- **Admin Portal & API**: `http://127.0.0.1:8001/admin/`

---

### Option 2: Run Individual Components

#### 1. Admin Backend & Portal
```bash
cd admin/backend
python run.py
```
Access the Admin Dashboard at: **http://127.0.0.1:8001/admin/**

#### 2. User Mobile Backend
```bash
cd user/backend
python run.py
```
Access the User API at: **http://127.0.0.1:8000**

#### 3. User Flutter Mobile App
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
