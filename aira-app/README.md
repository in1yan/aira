# 🃏 Smart Flash Cards

A clickable prototype Flutter app for recognizing and learning from flash cards. Built with Material Design 3, hardcoded mock data, and zero external dependencies.

---

## 🚀 Quick Start

```bash
# 1. Navigate to the project
cd e:\Project\Flashcards

# 2. Install dependencies
flutter pub get

# 3. Add platform support (only needed once)
flutter create . --platforms web,windows

# 4. Run the app (pick one)
flutter run -d chrome        # Run in Chrome browser
flutter run -d edge          # Run in Edge browser
flutter run -d windows       # Run as Windows desktop app
```

---

## 📱 Running on Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch Medium_Phone

# Run on the emulator (wait for it to boot first)
flutter run
```

---

## 🔥 Hot Reload (while app is running)

| Key | Action |
|-----|--------|
| `r` | Hot reload (apply changes instantly) |
| `R` | Hot restart (full restart) |
| `q` | Quit the app |
| `d` | Detach (keep app running, stop debug) |

---

## 📂 Project Structure

```
lib/
├── main.dart                              # App entry point & theme
├── mock_data.dart                         # All hardcoded data
└── screens/
    ├── login_screen.dart                  # Login page
    ├── home_screen.dart                   # Dashboard + settings
    ├── scan_flash_card_screen.dart        # Camera scan simulation
    ├── card_recognition_screen.dart       # AI recognition result
    ├── categories_screen.dart             # Category grid
    ├── card_list_screen.dart              # Animal cards grid
    ├── card_detail_screen.dart            # Card detail with concepts
    └── interactive_learning_screen.dart   # Concept learning view
```

---

## 🗺️ Screen Flow

```
Login → Home Dashboard
              ├── Scan Flash Card → (2s delay) → Card Recognition → Card Detail → Interactive Learning
              └── View Categories → Animals → Card List → Card Detail → Interactive Learning
```

---

## 🎨 Design

- **Primary**: Green `#4CAF50`
- **Secondary**: Blue `#2196F3`
- **Style**: Material Design 3, card-based UI, smooth animations
- **No images needed** — uses Flutter icons and colored containers

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| `flutter` not recognized | Add Flutter to your system PATH |
| No supported devices | Run `flutter create . --platforms web,windows` |
| Emulator won't start | Use `flutter run -d chrome` instead |
| First build is slow | Normal — subsequent builds use cache |

```bash
# Check your Flutter setup
flutter doctor

# See all connected devices
flutter devices
```
