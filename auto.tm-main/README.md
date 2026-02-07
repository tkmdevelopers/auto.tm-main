# Alpha Motors — Flutter App

Flutter mobile application (iOS/Android) for the Alpha Motors (auto.tm) marketplace. Uses GetX for state management and routing; authenticates via phone OTP and talks to the NestJS backend.

---

## Prerequisites

- Flutter SDK (stable)
- Backend API running (see [backend/docs/DEVELOPMENT_SETUP.md](../backend/docs/DEVELOPMENT_SETUP.md))

---

## Environment

Create `.env` in this directory (same level as `pubspec.yaml`). Required:

```env
API_BASE=http://10.0.2.2:3080
```

- **Android emulator:** `http://10.0.2.2:3080` (host machine localhost)
- **iOS simulator:** `http://localhost:3080`
- **Physical device:** Use your machine’s LAN IP, e.g. `http://192.168.1.x:3080`

The app loads `API_BASE` via `flutter_dotenv` (see [lib/utils/key.dart](lib/utils/key.dart)).

---

## Commands

From this directory (`auto.tm-main/`):

```bash
flutter pub get      # Install dependencies
flutter run          # Run on connected device/emulator
flutter analyze      # Dart analyzer
flutter test         # Unit tests
flutter build apk --release   # Android release APK
flutter build ios --release   # iOS release (macOS only)
```

---

## Project structure

```
lib/
├── main.dart           # Entry, Firebase init, GetX routes
├── app.dart            # Auth check → /navView or /register
├── screens/            # Feature screens + controllers
│   ├── auth_screens/   # Login, register, OTP
│   ├── home_screen/
│   ├── post_screen/    # Create/edit posts
│   ├── post_details_screen/
│   ├── profile_screen/
│   ├── favorites_screen/
│   ├── filter_screen/
│   ├── search_screen/
│   └── ...
├── services/           # Auth, API client, tokens, notifications
│   ├── auth/
│   ├── network/        # ApiClient (Dio + interceptors)
│   ├── token_service/  # TokenStore (secure storage)
│   └── notification_sevice/
├── global_controllers/ # Theme, connection, currency, language
├── utils/              # Themes, translation, key.dart (API_BASE)
├── ui_components/      # Colors, sizes, styles
├── global_widgets/
└── navbar/             # Bottom navigation
```

**State:** GetX (`GetxController`, `Obx`). **API:** All requests via `ApiClient` (Dio); token refresh and `USER_DELETED` handling in interceptors. **i18n:** GetX translations (e.g. English, Russian, Turkmen).

---

## Related docs

- Full-stack architecture: [docs/ARCHITECTURE.md](../backend/docs/ARCHITECTURE.md)
- Backend API contract: [backend/docs/API_REFERENCE.md](../backend/docs/API_REFERENCE.md)
- Root documentation index: [README.md](../README.md)
