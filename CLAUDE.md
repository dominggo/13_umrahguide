# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Build release APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Build debug APK
flutter build apk --debug

# Build app bundle for Play Store
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab

# Lint check
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

Use `build.bat` (Windows) as a shortcut for common build tasks.

## Build Environment

- Toolchain: Flutter 3.47+ (verified 3.47.7), JDK 17, Gradle 8.14.3, AGP 8.11.1, Kotlin 2.3.20, NDK 27.0.12077973. Older Flutter (e.g. 3.27) will not build this config.
- `android/gradle.properties` sets `kotlin.incremental=false` (Kotlin can't write its cache on the `P:` shared drive). Don't remove it.
- Gitignored files that must exist locally: `lib/firebase_options.dart`, `android/app/google-services.json` (placeholders work, Analytics off), and for release signing `android/key.properties` + `android/app/upload-keystore.jks`. Never commit them; the keystore is not regenerable.
- Running Flutter newer than the project can make it rewrite `analysis_options.yaml`, `pubspec.lock` and `android/gradle.properties`; check `git status` and revert unintended changes.
- Windows setup (scoop): `temurin17-jdk`, `flutter`, `android-clt`; set `ANDROID_HOME` to an SDK on `C:` (e.g. `C:\Users\<you>\Android\Sdk`) and install `cmdline-tools;latest`, `platform-tools`, `platforms;android-35/36`, `build-tools;36.0.0`, `ndk;27.0.12077973` with `sdkmanager`. Without `cmdline-tools` inside the SDK, `flutter build appbundle` fails at "failed to strip debug symbols". Check with `flutter doctor -v`.
- Release builds: `flutter build appbundle --release` (about 7 min on the `P:` drive). Play already holds earlier version codes, so bump the build number in `pubspec.yaml` first.
- **Signing files** (`android/app/upload-keystore.jks`, `android/key.properties`, `lib/firebase_options.dart`, `android/app/google-services.json`): the keystore is the only way to publish updates and cannot be regenerated. Copies: linku (`/mnt/shared/13_umrahguide/umrah_guide/`) and the OneDrive folder `P:\OneDrive\Apps\umrah-app-signing\` (hash-verified against the repo copies on 2026-10-19).- **Todo:** the main todo for all projects, including this app, is `P:\mnt\shared\00_proxmox\docs\todo.md` (section "Umrah Guide"). Do not keep a separate todo file in this repo.
- The debug build uses application ID `com.faeq.umrahmas.dev` ("Panduan Umrah dev"); `google-services.json` must contain a client for both `com.faeq.umrahmas` and the `.dev` suffix.

## Architecture

**Target:** Android only (Flutter). No web/iOS targets configured.

**State Management:** `MultiProvider` at root (`main.dart`) with 5 providers:
- `AudioProvider` — wraps `just_audio`; single global audio player. `play(assetPath)` toggles; page changes and leaving `DoaViewerScreen` (its `dispose`) call `stop()`. Emits a track-complete stream used by `DoaViewerScreen` for auto-advance.
- `BookmarkProvider` — bookmark CRUD via `shared_preferences`; key format `{stepId}__{substepId}__{doaTitle}`.
- `ProgressProvider` — only holds the persisted auto-play toggle (`autoPlayEnabled`); Round progress is NOT stored here — it comes from journey checkpoints in `LocationProvider`.
- `LocationProvider` — GPS subscription, zone auto-detection against 7 hardcoded Masjidil Haram coordinates, manual zone override, journey GPS/checkpoint recording. One session at a time, of a `JourneyKind`: `umrah` (CP1–17) or `wida` (CP18–24, standalone Tawaf Wida'). Checkpoints outside the active kind's range are ignored, so a Tawaf doa opened during a Wida' session can't write into it.
  - `notifyListeners()` fires only on zone / GPS-state / journey / checkpoint changes. Every fix goes to the separate `position` `ValueNotifier` (used by the map dot and track), so GPS fixes don't rebuild screens.
  - Foreground GPS only (no background service). A fix is requested every 2 s with no distance filter, so silence means lost signal. During a journey `gpsSignal` goes `lost` after 30 s without a fix, then `recovered`. A track point after more than 60 s without a fix gets `JourneyPoint.gapBefore` (JSON `gap`); the gap is excluded from distance and drawn dashed. Fixes with accuracy over 50 m are not recorded.
  - The stream restarts on app resume and when location services come back. The screen is kept on (`wakelock_plus`) while a journey is active.
  - Track file writes (`umrah_cur.json`) are queued so they never overlap.
- `JourneyHistoryProvider` — CRUD for completed journeys; persisted as JSON at `{appDocDir}/umrah_history.json` (atomic tmp+rename writes). If the file can't be parsed it is renamed to `umrah_history.corrupt-<ms>.json` so a later save can't overwrite it.

**Navigation flow:**
```
SplashScreen (~1.2 s auto-nav)
  └── HomeScreen (NavigationBar, 4 tabs in an IndexedStack; AppBar title per tab — tabs have no AppBar of their own)
        ├── Tab 0: Menu — grid of 8 UmrahStep cards
        │     └── StepDetailScreen → DoaListScreen (doa thumbnails)
        │           └── DoaViewerScreen (PageView + audio + round indicator + checkpoint buttons)
        ├── Tab 1: Umrah — UmrahIniScreen (checkpoint-based journey; GPS tracking;
        │     separate "Tawaf Wida'" card = independent Wida' session, CP18–24)
        │     ├── StepDetailScreen (fromJourney: true) → DoaViewerScreen (flat navigation)
        │     └── End journey → UmrahTamatScreen pushed above Home (map + timeline + PNG/PDF export)
        ├── Tab 2: Sejarah — UmrahAllScreen (list of completed journeys)
        │     └── UmrahTamatScreen (view past journey)
        └── Tab 3: Peta — MapScreen (OSM with disk tile cache + GPS dot + zone markers)

AppBar actions (all tabs):
  - Search icon → UmrahSearchDelegate (search across all duas)
  - Bookmark icon → _BookmarksScreen (bookmarks grouped by step → DoaViewerScreen)
  - Info icon → About dialog
```

**Data layer:** All content hardcoded in `lib/data/umrah_data.dart` as a `const List<UmrahStep>`. No network calls; all assets bundled offline. Asset paths are string literals.

**Journey vs browsing:** `DoaViewerScreen` records checkpoint starts and shows the start/end buttons only when opened with `fromJourney: true` (Umrah tab flow). From the Menu tab, search or bookmarks it records nothing; a niat doa there shows "Mulakan Umrah? Tekan di sini" (or "Sambung di tab Umrah" while a session runs), which sets `HomeScreen.tabRequest` and pops to Home on the Umrah tab.

**Journey flows** live in `lib/screens/journey_actions.dart`:
- `startJourney` shows a "no GPS" snackbar if needed, logs analytics, shows the one-time keep-screen-on notice (pref `hide_screen_on_notice`) and opens the first checkpoint.
- `finishJourney` asks to confirm, then finalizes, saves to history, logs analytics and opens `UmrahTamatScreen` with `pushAndRemoveUntil(isFirst)`.
- `openCheckpoint` opens a checkpoint's doa.

Use these flows rather than duplicating them. Checkpoint lookups use `checkpointStartLocation(n)` / `checkpointName(n)` from `umrah_data.dart`.

**Auto-play groups:** `DoaViewerScreen` listens to `AudioProvider.onTrackComplete`. If `ProgressProvider.autoPlayEnabled` is on (toggle in the viewer AppBar), it turns to the next doa and plays it. It stops before a doa with `autoPlay: false` (a manual break-point), a doa with no audio, or a checkpoint-end doa (waits for the user to confirm).

**Shared utils:**
- `lib/utils/format.dart` — `kPrimaryGreen`, `fmtTime`, `fmtDateTime`, `fmtDuration`.
- `lib/utils/geo.dart` — distance, gap-aware `trackDistanceKm` and `trackSegments`.
- `lib/utils/map_tile_cache.dart` — disk tile cache (`initTileCache()` runs in `main`), `osmTileLayer()` and `trackLayer()`.

**PDF/PNG export:**
- The PDF uses the bundled `assets/fonts/Nunito-*.ttf`, so it works offline. Don't go back to `PdfGoogleFonts`.
- The PNG is captured with `captureFromLongWidget` from a non-scrolling summary, without the map.

## Key Files

| File | Purpose |
|------|---------|
| `lib/data/umrah_data.dart` | All 8 Umrah steps with substeps & duas — edit content here; also checkpoint lookup helpers |
| `lib/screens/journey_actions.dart` | Shared start / finish / open-checkpoint journey flows |
| `lib/models/umrah_step.dart` | `UmrahStep`, `UmrahSubStep`, `DoaItem` data classes |
| `lib/models/audio_provider.dart` | Global audio state + track-complete stream |
| `lib/models/progress_provider.dart` | Auto-play toggle only |
| `lib/models/location_provider.dart` | GPS, zone detection, journey recording (`JourneyKind` umrah/wida) |
| `lib/models/journey_history_provider.dart` | Journey CRUD + JSON file persistence |
| `lib/models/umrah_location.dart` | `UmrahLocation` model + 7 Masjidil Haram zone coordinates |
| `lib/screens/doa_viewer_screen.dart` | Full-screen doa PageView, auto-play logic, checkpoint start/end buttons, 7-dot round indicator (Tawaf/Sa'ie/Wida') |
| `lib/screens/doa_list_screen.dart` | Doa thumbnails with quick play + bookmark toggle (`DoaListScreen`) |
| `lib/screens/umrah_ini_screen.dart` | Tab 1 — checkpoint-based Umrah journey; GPS zone display; 5-step tiles; start/end flow (`UmrahIniScreen`) |
| `lib/screens/umrah_all_screen.dart` | Tab 2 — list of completed journey records; opens UmrahTamatScreen (`UmrahAllScreen`) |
| `lib/screens/umrah_tamat_screen.dart` | Journey summary with OSM map, checkpoint timeline, PNG/PDF export (`UmrahTamatScreen`) |
| `lib/screens/map_screen.dart` | Tab 3 — offline OSM map with GPS overlay and zone markers (`MapScreen`) |
| `lib/utils/map_tile_cache.dart` | Shared disk OSM tile cache + `osmTileLayer()` / `trackLayer()` |
| `lib/utils/geo.dart` | Distance and gap-aware track helpers |
| `lib/utils/format.dart` | Primary colour const and date/duration formatters |

## Google Play Status (2026-10-20)

**Update 2026-10-20:** the review passed and the closed test is live, but **0 testers have opted in yet**. Opt-in links, console URLs (use `/console/u/1/`), what to do next and the invite email are in `docs/play_closed_test_handoff.md`.

- Personal developer account: production is locked until a closed test has run with at least 12 testers opted in for 14 consecutive days. Open testing is locked too.
- Closed testing "Alpha": release `1.1.0+3`, tester list `closed1` (15 testers), countries MY, ID, SG, SA, TH (Brunei is not offered by Play). 14 changes were submitted for review on 2026-10-19; pre-review checks passed and Play Console showed "Your changes are now in review" the same day (Google review takes about 7 days; check Publishing overview).
- Privacy policy URL on Play is pinned to commit `1690ff0` of `docs/PRIVACY_POLICY.md` on GitHub (`dominggo/13_umrahguide`); keep that commit reachable and update the URL in Play Console when the policy changes.
- Data safety: collected App interactions + Device or other IDs for Analytics (Firebase), not shared; advertising ID declared as used for Analytics.
- The Play bundle is 88.7 MB, so the browser upload tool cannot send it; upload `build/app/outputs/bundle/release/app-release.aab` manually in Play Console.

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
