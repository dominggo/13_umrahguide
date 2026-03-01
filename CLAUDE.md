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

**State Management:** `MultiProvider` at root (`main.dart`) with 5 providers:
- `AudioProvider` — wraps `just_audio`; single global audio player. `play(assetPath)` toggles; navigating away calls `stop()`. Emits a track-complete stream used by `DoaViewerScreen` for auto-advance.
- `BookmarkProvider` — bookmark CRUD via `shared_preferences`; key format `{stepId}__{substepId}__{doaTitle}`.
- `ProgressProvider` — guided-flow cursor (step/substep indices) + Tawaf/Sa'ie round status (`RoundStatus` enum: pending/confirmed/skipped). Both persisted.
- `LocationProvider` — GPS subscription, zone auto-detection against 7 hardcoded Masjidil Haram coordinates, manual zone override, journey point/event recording.
- `JourneyHistoryProvider` — CRUD for completed journeys; persisted as JSON at `{appDocDir}/umrah_history.json`.

**Navigation flow:**
```
SplashScreen (3 s auto-nav)
  └── HomeScreen (BottomNavigationBar, 4 tabs)
        ├── Tab 0: Menu — grid of 8 UmrahStep cards
        │     └── StepDetailScreen → SubstepScreen (doa thumbnails)
        │           └── DoaViewerScreen (PageView + audio nav + round tracking)
        ├── Tab 1: Panduan Aliran — GuideFlowScreen (linear, progress save/resume)
        │     └── DoaViewerScreen (same viewer, flow context)
        ├── Tab 2: Simpan — bookmarks grouped by step
        │     └── DoaViewerScreen (jump to bookmarked doa)
        └── Tab 3: Peta — MakkahMapScreen (OSM + GPS dot + zone markers)

AppBar extras (all tabs):
  - Search icon → UmrahSearchDelegate (SearchDelegate across all duas)
  - History icon → JourneyHistoryScreen → JourneySummaryScreen
  - "Masuk ke Masjid" card → JourneyScreen (start/end journey)
        └── End journey → JourneySummaryScreen (map + timeline + PNG/PDF export)
```

**Data layer:** All content hardcoded in `lib/data/umrah_data.dart` as a `const List<UmrahStep>`. No network calls; all assets bundled offline. Asset paths are string literals.

**Auto-play groups:** `DoaViewerScreen` groups consecutive `DoaItem`s where `autoPlay: true` and auto-advances through them; items with `autoPlay: false` act as manual break-points requiring user tap.

## Key Files

| File | Purpose |
|------|---------|
| `lib/data/umrah_data.dart` | All 8 Umrah steps with substeps & duas — edit content here |
| `lib/models/umrah_step.dart` | `UmrahStep`, `UmrahSubStep`, `DoaItem` data classes |
| `lib/models/audio_provider.dart` | Global audio state + track-complete stream |
| `lib/models/progress_provider.dart` | Guided-flow cursor + `RoundStatus` tracking |
| `lib/models/location_provider.dart` | GPS, zone detection, journey recording |
| `lib/models/journey_history_provider.dart` | Journey CRUD + JSON file persistence |
| `lib/models/umrah_location.dart` | `UmrahLocation` model + 7 Masjidil Haram zone coordinates |
| `lib/screens/doa_viewer_screen.dart` | Full-screen doa PageView, auto-play logic, round dialogs |
| `lib/screens/guide_flow_screen.dart` | Linear guided flow through all 8 steps |
| `lib/screens/makkah_map_screen.dart` | Offline OSM map with GPS overlay and zone markers |
| `lib/screens/journey_summary_screen.dart` | Journey summary with PNG/PDF export |
| `lib/utils/map_tile_cache.dart` | Shared in-memory OSM tile cache (singleton) |

## Asset Conventions

- Doa images: `assets/images/doa/<name>.png`
- Audio files: `assets/audio/<name>.ogg` (some `.mp3`)
- Step overview images: `assets/images/overview/<name>.jpg`
- Location photos: `assets/images/locations/<name>.jpg`
- Text guides (HTML-formatted): `assets/text/<name>.txt`
- Any new asset folder must be declared in `pubspec.yaml` under `flutter.assets`

Use `gen_asset_excel.py` (project root) to generate `asset_mismatch.xlsx` — a report that cross-checks hardcoded asset paths against actual files on disk.

## Theme

Material 3, primary green `Color(0xFF1B5E20)`. AppBar is always dark green with white foreground. Card elevation: 2, border radius: 12. UI language: Bahasa Malaysia throughout.
