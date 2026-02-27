# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Add Flutter to PATH (required each shell session if not in system PATH)
set PATH=C:\flutter\bin;%PATH%

# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
# Output: build\app\outputs\flutter-apk\app-release.apk

# Build debug APK
flutter build apk --debug

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Lint check
flutter analyze
```

Use `setup_and_run.bat` or `build_apk.bat` as shortcuts for common tasks.

## Architecture

**Target:** Android only (Flutter). No web/iOS targets configured.

**State Management:** Single `ChangeNotifierProvider` at root (`main.dart`) exposing `AudioProvider` — the only global state. Everything else is stateless or uses local `StatefulWidget` state.

**Navigation flow:**
```
SplashScreen (3s auto-nav)
  └── HomeScreen (BottomNavigationBar)
        ├── Tab 0: Menu — grid of 8 UmrahStep cards
        │     └── StepDetailScreen (substep list)
        │           └── SubstepScreen (doa thumbnails + quick play)
        │                 └── DoaViewerScreen (PageView, full image + audio nav)
        └── Tab 1: Panduan Aliran — timeline of all steps
              └── GuideFlowScreen (linear walk-through, progress bar)
                    └── DoaViewerScreen (same viewer, different entry point)
```

**Data layer:** All content is hardcoded in `lib/data/umrah_data.dart` as a `List<UmrahStep>`. No network calls, no database. Asset paths are string literals referencing `assets/images/doa/` and `assets/audio/`.

**Audio:** `AudioProvider` wraps `just_audio`'s `AudioPlayer`. Toggle play/pause by calling `play(assetPath)` — calling with the currently playing path pauses it. Only one track plays at a time; navigating away (page change in `DoaViewerScreen`) calls `stop()`.

## Key Files

| File | Purpose |
|------|---------|
| `lib/data/umrah_data.dart` | All 8 Umrah steps — add/edit content here |
| `lib/models/umrah_step.dart` | `UmrahStep`, `UmrahSubStep`, `DoaItem` data classes |
| `lib/models/audio_provider.dart` | Global audio state (play/pause/stop) |
| `lib/screens/doa_viewer_screen.dart` | Full-screen doa PageView with audio nav bar |
| `lib/screens/guide_flow_screen.dart` | Guided linear flow through all 8 steps |

## Asset Conventions

- Doa images: `assets/images/doa/<name>.png`
- Audio files: `assets/audio/<name>.ogg` (some `.mp3`)
- Step overview images: `assets/images/overview/<name>.jpg`
- Location photos: `assets/images/locations/<name>.jpg`
- Text guides (HTML-formatted): `assets/text/<name>.txt`
- Any new asset folder must be declared in `pubspec.yaml` under `flutter.assets`

## Theme

Material 3, primary green `Color(0xFF1B5E20)`. AppBar is always dark green with white foreground. Card elevation: 2, border radius: 12.
