# Flutter Frontend

This frontend has been rebuilt in Flutter.

## Run locally

1. Install Flutter SDK.
2. From `frontend/`, run:

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE=http://localhost:5000/api
```

If you run through Docker/Nginx, keep `API_BASE=/api`.

## Build web

```bash
flutter build web --release --dart-define=API_BASE=/api
```
