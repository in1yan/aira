# Aira

Aira is an AI-assisted smart flashcard learning platform. It combines a
Flutter mobile app, a browser-based administration portal, and a unified
FastAPI backend for managing and exploring visual learning content.

## What Aira does

- Stores flashcards with a trigger image and visual concept attributes.
- Organizes cards into multilingual categories and nested subcategories.
- Recognizes a physical flashcard from a camera image using OpenCV ORB feature
  matching and HSV histogram comparison.
- Presents card content in English, Tamil, Hindi, and Malayalam.
- Generates text-to-speech audio for supported languages.
- Lets administrators create, edit, publish, and delete cards and categories.
- Uploads media to local storage and can optionally synchronize images to an
  S3-compatible bucket.
- Exports the database, media, audio, and a JSON visual-context manifest as a
  downloadable bundle.

## Main components

```text
aira/
├── backend/                 # FastAPI API and application services
│   └── app/
│       ├── main.py          # Application setup and route registration
│       ├── database.py      # SQLAlchemy engine and shared storage paths
│       ├── models.py        # Users, categories, cards, and attributes
│       ├── schemas.py       # Request and response models
│       ├── routers/         # Auth, cards, categories, detection, TTS, admin
│       └── services/        # Vision, speech, and object storage services
├── admin/frontend/          # Static web administration portal
├── user/frontend/           # Flutter mobile application
├── shared/
│   ├── data/aira.db         # Default local SQLite database
│   └── uploads/             # Local image and generated audio storage
├── run_all.py               # Development launcher for the backend
├── pyproject.toml           # Python package and dependency definition
└── upload_images_to_s3.py   # Optional bulk image synchronization utility
```

## Architecture

The backend runs one FastAPI application on port `8000`. It serves:

1. The admin portal at `/admin/`.
2. JSON API endpoints under `/api`.
3. Interactive OpenAPI documentation at `/docs`.
4. Local media under `/static/images` and `/static/audio`.

The mobile app communicates with the same API. The admin portal uses the
management endpoints to maintain the learning dataset, while the mobile app
uses card discovery, scanning, category, authentication, and TTS endpoints.

## Requirements

- Python 3.12 or newer
- Flutter SDK 3.2 or newer
- Android SDK and `adb` for Android device testing
- Optional: PostgreSQL-compatible database and S3-compatible object storage

## Quick start

### 1. Install Python dependencies

Using `uv`:

```bash
uv sync
```

Or install the project with pip:

```bash
pip install -e .
```

### 2. Configure environment variables

Copy the example file and edit it as needed:

```bash
cp .env.example .env
```

Without a database setting, Aira creates and uses:

```text
shared/data/aira.db
```

For PostgreSQL, set one of `DATABASE_URL`, `POSTGRES_URL`, or `DB_URL`.
For cloud media storage, configure `AWS_REGION`, `AWS_ACCESS_KEY_ID`,
`AWS_SECRET_ACCESS_KEY`, and `AWS_S3_BUCKET`. Custom S3 endpoints and CDN
domains are also supported; see `.env.example`.

### 3. Start the backend

From the repository root:

```bash
python run_all.py
```

Available URLs:

| Purpose | URL |
|---|---|
| Admin portal | <http://127.0.0.1:8000/admin/> |
| API status | <http://127.0.0.1:8000/api> |
| Health check | <http://127.0.0.1:8000/health> |
| Swagger UI | <http://127.0.0.1:8000/docs> |
| ReDoc | <http://127.0.0.1:8000/redoc> |

The backend can also be started directly:

```bash
cd backend
python run.py
```

### 4. Start the Flutter app

```bash
cd user/frontend
flutter pub get
flutter run
```

For an Android device connected over USB, forward the backend port first:

```bash
adb reverse tcp:8000 tcp:8000
flutter run
```

The app includes a home experience, category and card browsing, camera-based
card recognition, card detail views, settings, and login/session handling.

## Core API areas

All endpoints are prefixed with `/api`.

| Area | Routes | Purpose |
|---|---|---|
| Cards | `/cards` | List, filter, create, update, and delete flashcards |
| Categories | `/categories` | Manage folders, nested subcategories, and contents |
| Detection | `/detect` | Upload an image and identify a stored flashcard |
| TTS | `/tts` | Generate speech audio for card text |
| Authentication | `/auth` | Register, login, session lookup, and token refresh |
| Administration | `/admin` | Statistics, users, uploads, synchronization, and exports |

Example card detection request:

```bash
curl -X POST http://127.0.0.1:8000/api/detect \
  -F "file=@path/to/flashcard.jpg"
```

Example TTS request:

```bash
curl -X POST http://127.0.0.1:8000/api/tts \
  -H "Content-Type: application/json" \
  -d '{"text":"பூனை","lang":"ta"}'
```

## Learning data model

- **User**: account identity, role, activation state, and avatar.
- **Category**: multilingual folder metadata, domain, icon, color, and optional
  parent category.
- **Card**: multilingual title, trigger image, category, domain, subcategory,
  and publication state.
- **Card attribute**: a named concept dimension with multilingual text and an
  optional image.

Cards are designed around six visual concept dimensions. The API supports
named keys such as `group`, `location`, `association`, `property`, `use`, and
`action`, while also allowing custom attribute keys.

## Domains, categories, and subcategories

Aira currently supports five learning domains:

| Domain | Focus |
|---|---|
| **Phonology** | Form: sounds, articulation, and sound positions |
| **Morphology** | Form: words, word parts, and vocabulary patterns |
| **Syntax** | Form: sentence building and stimulation stories |
| **Semantic** | Content: vocabulary, concepts, and visual attributes |
| **Pragmatic** | Use: communication, interaction, and social language |

The app's built-in catalog contains the following categories and example
subcategories:

### Phonology

- **Consonants & Vowels**: Bilabials, alveolars, velars
- **Initial Sounds**: Initial consonants, initial blend sounds
- **Medial Sounds**: Medial vowels, medial clusters
- **Final Sounds**: Final plosives, final nasals, final fricatives

### Morphology

- **Animals**
- **Birds**
- **Fruits**
- **Vegetables**
- **Food Items**
- **Vehicles**
- **Household Items**
- **Clothes**
- **Occupations**
- **Places**
- **Reptiles**
- **Marine Animals**
- **Insects**
- **Utensils**
- **Colours**
- **Shapes**
- **Seasons**
- **Festivals**
- **Indian Leaders**
- **Sports Players**
- **Lord/God**
- **Actors**
- **Cartoons**
- **States**

The fallback prototype catalog also includes **Plurals & Suffixes** and
**Verb Tenses**.

### Syntax

- **Sentence Sequencing**: Subject-Verb-Object (SVO), subject-verb-adjective,
  3-step sequence stories
- **WH Question Stories**: Who & Where, What & Why, When stories
- **Conjunctions & Compound Sentences**: And/Because, But/Or
- **Prepositional Phrases**: In/On/Under, Behind/In front of/Next to

### Semantic

- **Animals**: Domestic animals, wild animals, farm animals, reptiles
- **Birds**: Common birds, birds of prey, water birds
- **Sea & Water Animals**: Fish, dolphin/whale, crab, turtle, other aquatic
  animals
- **Insects & Creatures**: Butterfly, bee, fly, cockroach, ant, scorpion,
  spider
- **Fruits**: Apple, banana, mango, orange, grapes, papaya, pomegranate,
  strawberry
- **Vegetables**: Potato, tomato, carrot, cabbage, onion, green beans, peas,
  cucumber, spinach
- **Plants & Flowers**: Trees, leaves, flowers, garden plants
- **Clothes & Accessories**: Shirts, pants, dresses, shoes, sarees, caps, belts
- **Home & Kitchen**: Cups, plates, spoons, pots, pans, furniture, household
  items
- **School & Learning**: Books, pencil, pen, blackboard, school bag,
  educational materials
- **Vehicles & Transport**: Car, bus, train, bicycle, motorcycle, aircraft,
  ship, boat, ambulance, tractor
- **Numbers**: 0–9 numbers, counting cards, mathematical signs
- **Shapes**: Circle, square, triangle, rectangle, star, heart, 3D shapes
- **Colours**: Red, blue, green, yellow, black, white, purple, orange, brown,
  grey
- **Time & Calendar**: Days of the week, months, morning/night, time concepts
- **Body Parts**: Eyes, nose, ear, mouth, hand, leg, foot
- **People & Professions**: Doctor, teacher, police, lawyer, farmer, engineer
- **Places & Buildings**: Houses, schools, hospitals, temples, monuments,
  famous landmarks
- **Nature & Environment**: Sun, sky, trees, landscape, water, desert, weather
- **Emotions & Concepts**: Happiness, fear, honesty, knowledge, friendship

### Pragmatic

- **Turn-Taking Games**: My turn/your turn games, waiting and signaling intent
- **Conversational Prompts**: Greetings and farewells, initiating conversation,
  topic maintenance
- **Social Requests & Needs**: Asking for help politely, requesting items,
  refusal and boundary phrases
- **Emotion & Empathy Sharing**: Expressing feelings, recognizing partner
  emotions, comforting responses

### Current database contents

The checked-in SQLite database currently contains the **Phonology** domain
with two root categories:

- **Hindi**: letter-level subcategories including क, कष, ख, ग, घ, च, छ, ज, जञ,
  झ, ठ, ड, ढ, त, तर, थ, द, ध, न, प, फ, ब, भ, म, र, ल, व, श, स, and ह
- **Tamil**: currently configured as a root category; additional child
  categories can be added through the admin portal

The other domain/category trees above are supported by the mobile UI and
prototype fallback data and can be populated through the admin portal or API.

## Recognition flow

1. The mobile app captures an image.
2. The app uploads it to `POST /api/detect`.
3. The vision service decodes the image and compares it with stored card
   trigger images.
4. ORB descriptors provide feature matches and HSV histograms provide a
   color/appearance similarity signal.
5. The best matching card and its attributes are returned to the app.

Reference images may be local files, `/static/images/...` paths, absolute
paths, or remote HTTP(S) URLs.

## Media and exports

Local media is stored in:

```text
shared/uploads/images/
shared/uploads/audio/
```

The admin API can upload individual images, synchronize local images to S3,
and export:

- The SQLite database
- All images and generated audio
- `visual_context_manifest.json`
- A dataset README

Export routes are available under `/api/admin/export`, including the complete
bundle at `/api/admin/export/bundle`.

## Development notes

- Database tables are created automatically when the backend starts.
- A small startup migration adds the category `parent_id` column to older
  databases when required.
- CORS is currently open for development and local app integration.
- Authentication routes currently return demonstration token values; replace
  this flow with production token validation before deploying publicly.
- S3 upload failures fall back to local image storage.

## License and project status

This repository is an active application project rather than a published
package. Review deployment, authentication, CORS, and object-storage settings
before using it in production.
