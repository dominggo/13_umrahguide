# Panduan Umrah

A Flutter Android app providing a complete step-by-step guide for performing Umrah, with doa (prayer) images and audio playback. UI is in Bahasa Malaysia.

---

## Screen Overview

### 1. `HomeScreen` — Menu Tab
```
┌─────────────────────────────────────────────────┐
│ Panduan Umrah                          🔍  🔖   │  ← AppBar (search + bookmark)
├─────────────────────────────────────────────────┤
│  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │  1.Ihram  │  │  2.Masuk  │  │ 3.Ka'abah │   │
│  └───────────┘  └───────────┘  └───────────┘   │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │  4.Tawaf  │  │5.S.Tawaf  │  │  6.Sa'ie  │   │  ← 9-step card grid
│  └───────────┘  └───────────┘  └───────────┘   │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │7.Tahallul │  │8.Tw.Wida' │  │9.Lain-lain│   │
│  └───────────┘  └───────────┘  └───────────┘   │
├─────────────────────────────────────────────────┤
│    Menu    │   Umrah   │  Sejarah  │    Peta    │  ← Bottom navigation
└─────────────────────────────────────────────────┘
```

### 2. `StepDetailScreen` — Step Overview
```
┌─────────────────────────────────────────────────┐
│ ←  Tawaf                                        │  ← AppBar with step title
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │  Tawaf                                    │  │
│  │  Mengelilingi Ka'abah sebanyak 7 pusingan │  │  ← Green header banner
│  │  [ 7 Bahagian ]  [ 42 Doa ]              │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │ ①  Niat Tawaf                  1 doa  ›  │  │
│  ├───────────────────────────────────────────┤  │
│  │ ②  Tawaf Pusingan 1            6 doa  ›  │  │  ← Substep list tiles
│  ├───────────────────────────────────────────┤  │
│  │ ③  Tawaf Pusingan 2            6 doa  ›  │  │
│  ├───────────────────────────────────────────┤  │
│  │  · · ·                                    │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

### 3. `DoaListScreen` — Doa Thumbnails
```
┌─────────────────────────────────────────────────┐
│ ←  Tawaf Pusingan 1                             │
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │ ┌──────┐  Doa Permulaan Tawaf         🔖 │  │
│  │ │ img  │  Dimulakan dengan Bismillah…    │  │  ← Doa card with thumbnail
│  │ └──────┘  [🖼 Gambar] [🔊 Audio]  ▶     │  │    quick-play + bookmark
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │ ┌──────┐  Doa Semasa Tawaf           🔖 │  │
│  │ │ img  │  Rabbana atina fid-dunya…       │  │
│  │ └──────┘  [🖼 Gambar] [🔊 Audio]  ▶     │  │
│  └───────────────────────────────────────────┘  │
│  · · ·                                          │
└─────────────────────────────────────────────────┘
```

### 4. `DoaViewerScreen` — Full-Screen Doa Reader
```
┌─────────────────────────────────────────────────┐
│ ←  Tawaf — Pusingan 1    ① ② ③ ④ ⑤ ⑥ ⑦    │  ← Round indicators (Tawaf/Sa'ie)
├─────────────────────────────────────────────────┤
│                                                 │
│          ┌────────────────────────┐             │
│          │                        │             │
│          │   Arabic doa text      │             │  ← Doa image (swipe to navigate)
│          │   + transliteration    │             │
│          │                        │             │
│          └────────────────────────┘             │
│                                                 │
│          Niat Tawaf                             │  ← Doa title
│                                                 │
├─────────────────────────────────────────────────┤
│            ⏮    ◀    ▶/⏸    ▶    🔁           │  ← Audio controls
└─────────────────────────────────────────────────┘
```

### 5. `UmrahIniScreen` — Umrah Journey Tab
```
┌─────────────────────────────────────────────────┐
│ Panduan Umrah                          🔍  🔖   │
├─────────────────────────────────────────────────┤
│  GPS Aktif · Ka'abah Zone          Lokasi Manual│  ← Compact GPS row
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │              [ Mulakan Umrah ]            │  │  ← Hidden once journey active
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │  ← Resume card (journey active)
│  │  ▶  Sambung Umrah                      ›  │  │
│  │     Tawaf Pusingan 3                      │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  Perkembangan Umrah                             │
│  ┌───────────────────────────────────────────┐  │
│  │ ①  Ihram                           ●  ›  │  │
│  ├───────────────────────────────────────────┤  │
│  │ ②  Tawaf      ● ● ● ○ ○ ○ ○       ›  │  │  ← Round dots (green=done)
│  ├───────────────────────────────────────────┤  │
│  │ ③  Solat Sunat Tawaf               ○  ›  │  │
│  ├───────────────────────────────────────────┤  │
│  │ ④  Sa'ie      ○ ○ ○ ○ ○ ○ ○       ›  │  │
│  ├───────────────────────────────────────────┤  │
│  │ ⑤  Tahallul                        ○  ›  │  │
│  └───────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│         [ Selesai Ibadah Umrah ]                │  ← Fixed bottom (journey active)
├─────────────────────────────────────────────────┤
│    Menu    │  [Umrah]  │  Sejarah  │    Peta    │
└─────────────────────────────────────────────────┘
```

### 6. `UmrahTamatScreen` — Journey Summary
```
┌─────────────────────────────────────────────────┐
│ ←  Ringkasan Perjalanan              🖼    📄   │  ← PNG + PDF export
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │  Umrah ke-3                               │  │
│  │  Panduan Umrah        Tempoh: 3j 42m      │  │  ← Green summary header
│  │                       Jarak:  4.21 km     │  │
│  │  Mula: 12/3/2026 07:00                    │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  [OSM Map with GPS polyline]              │  │  ← Map (hidden if no GPS)
│  └───────────────────────────────────────────┘  │
│  Rekod Perjalanan                               │
│  ● CP1   Ihram                 07:00 – 07:28   │
│  ▼ Tawaf (3/7)  07:45 – 08:30              ▶  │  ← Collapsible; shows x/7
│  ● CP9   Solat Sunat Tawaf     08:35 – 08:50   │
│  ▼ Sa'ie (0/7)  Tidak dimulakan            ▶  │  ← Red if none started
│  ⚠ CP17  Tahallul   Tidak dimulakan            │  ← Skipped tile (red)
│  ─────────────────────────────────────────────  │
│  ⚠  Semak dan pastikan Umrah ini lengkap        │  ← Amber footer (incomplete)
└─────────────────────────────────────────────────┘
```

### 7. `UmrahAllScreen` — Journey History (Sejarah Tab)
```
┌─────────────────────────────────────────────────┐
│ ←  Sejarah Umrah — 3 kali selesai               │  ← Total count in title
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │ 🕌  Umrah ke-3          12/3/2026 07:00  │  │
│  │  3   3j 42m  ·  4.21 km              ›  🗑 │  │  ← Tap → UmrahTamatScreen
│  └───────────────────────────────────────────┘  │  ← Long-press → edit times
│  ┌───────────────────────────────────────────┐  │  ← Swipe left → delete
│  │ 🕌  Umrah ke-2          05/2/2026 06:15  │  │
│  │  2   4j 10m  ·  4.87 km              ›  🗑 │  │
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │ 🕌  Umrah ke-1          20/1/2026 05:50  │  │
│  │  1   3j 55m  ·  4.60 km              ›  🗑 │  │
│  └───────────────────────────────────────────┘  │
├─────────────────────────────────────────────────┤
│    Menu    │   Umrah   │  [Sejarah] │    Peta   │
└─────────────────────────────────────────────────┘
```

### 8. `MapScreen` — Peta Masjidil Haram Tab
```
┌─────────────────────────────────────────────────┐
│ Peta Masjidil Haram                    📍       │  ← "My Location" button
├─────────────────────────────────────────────────┤
│  ✅ Anda di: Ka'abah                            │  ← Green zone status bar
├─────────────────────────────────────────────────┤
│                                                 │
│   · · · · · · [OpenStreetMap] · · · · · · · ·  │
│                                                 │
│           [G] Ka'abah                           │
│                  [G] Hijir Ismail               │  ← Green zone markers (G)
│                 [B] ← your GPS dot              │  ← Blue GPS dot (B)
│           [G] Makam Ibrahim                     │
│               [G] Multazam · · ← GPS trail     │
│                       [G] Zamzam               │
│   [G] Safa                        [G] Marwah   │
│                                                 │  ← Long-press → manual zone
├─────────────────────────────────────────────────┤
│    Menu    │   Umrah   │  Sejarah  │   [Peta]   │
└─────────────────────────────────────────────────┘
```
Tap a zone marker → bottom sheet with description + related duas.

### 9. `SearchScreen` — Cari Doa
```
┌─────────────────────────────────────────────────┐
│ ←  🔍 Cari doa...                               │  ← Search field (AppBar)
├─────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────┐  │
│  │  Doa Qunut Nazilah                        │  │
│  │  Ihram › Doa Semasa Ihram                 │  │  ← step › substep breadcrumb
│  └───────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────┐  │
│  │  Doa Talbiah                              │  │
│  │  Ihram › Talbiah                          │  │
│  └───────────────────────────────────────────┘  │
│  · · ·  (results update on every keystroke)     │
└─────────────────────────────────────────────────┘
```
Tap result → `DoaViewerScreen` at that doa.

### 10. `_BookmarksScreen` — Simpanan
```
┌─────────────────────────────────────────────────┐
│ ←  Simpanan                                     │
├─────────────────────────────────────────────────┤
│  Tawaf                                          │  ← Step group header
│  ┌───────────────────────────────────────────┐  │
│  │ ┌──────┐  Doa Semasa Tawaf          🔖   │  │
│  │ │ img  │  Tawaf Pusingan 1               │  │  ← Tap → DoaViewerScreen
│  │ └──────┘                                  │  │  ← Tap 🔖 → remove bookmark
│  └───────────────────────────────────────────┘  │
│  Sa'ie                                          │
│  ┌───────────────────────────────────────────┐  │
│  │ ┌──────┐  Doa Semasa Sa'ie          🔖   │  │
│  │ │ img  │  Sa'ie Pusingan 1               │  │
│  │ └──────┘                                  │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## Features

### Doa Content
- **9 Umrah steps** from Ihram to Lain-lain Doa
- **173 audio files** — listen to each doa recited aloud
- **176 doa images** — Arabic text with transliteration
- **Offline** — all content bundled in the app

### Navigation
- **Menu** — browse all 9 steps freely
- **Umrah** — journey dashboard: start/end a recorded Umrah, GPS status, checkpoint tracker, step grid
- **Sejarah** — full list of all past Umrah journeys
- **Peta** — offline OSM map of Masjidil Haram

**AppBar (all tabs):**
- Search icon — search any doa by name across all steps
- Bookmark icon — view all saved bookmarks, grouped by step

### Audio Playback
- **Auto-play groups** — audio advances automatically through a sequence of duas; items with `autoPlay: false` act as manual break-points
- **Repeat** — loop the current auto-play group
- **Skip prev / next** — jump one doa at a time with auto-play

### Bookmarks
- Save any doa with the bookmark icon in the doa viewer
- All bookmarks accessible via the **bookmark icon in the AppBar**, grouped by step
- Persisted across app restarts

### Tawaf & Sa'ie Round Tracking
- 7-circle indicator in the AppBar when viewing Tawaf or Sa'ie rounds
- Confirmation dialog when reaching the last doa in each round: "Adakah anda telah melengkapkan pusingan ini?"
- Round status (confirmed / skipped / pending) persisted to device storage
- Missed rounds highlighted with a reminder banner

### Journey Recording & Checkpoint System
- GPS track recorded in the background during your Umrah (every 5 m movement)
- Auto-detects which Masjidil Haram zone you are in (Ka'abah, Hijir Ismail, Makam Ibrahim, Multazam, Telaga Zamzam, Bukit Safa, Bukit Marwah)
- **17 checkpoints** spanning Ihram through Tahallul, each with its own start and end timestamp:
  - CP1: Ihram
  - CP2–8: Tawaf (niat + 7 rounds)
  - CP9: Solat Sunat Tawaf
  - CP10–16: Sa'ie (niat + 7 rounds)
  - CP17: Tahallul
- Next button disabled at checkpoint end until user confirms completion
- **Missed checkpoint detection** — checkpoints never started are highlighted; "Rekod Semula" lets you re-record them
- **"Selesai Ibadah Umrah"** button ends the journey and opens the summary screen

### Journey Summary & Export
- Total distance (km) and duration
- OSM map with GPS polyline
- **Grouped checkpoint timeline**: CP1 (Ihram), CP2–8 collapsible Tawaf group, CP9 (Solat Tawaf), CP10–16 collapsible Sa'ie group, CP17 (Tahallul)
- Skipped/unstarted checkpoints highlighted with alert indicator
- Edit checkpoint start/end times within 24 hours of journey end
- **Export PNG** — screenshot of summary card, shared via WhatsApp / Telegram / etc.
- **Export PDF** — styled PDF report, shared via any app
- Auto-saved to journey history on first open

### Journey History
- Complete list of all past Umrah journeys (newest first)
- Tap any entry to view its full summary
- Long-press to correct start/end date & time
- Swipe to delete (with confirmation)
- Header shows total Umrah count: "X kali selesai"

### Peta Masjidil Haram (OSM Map)
- Offline-capable OpenStreetMap tiles (cached in memory)
- Green zone markers for 7 key Masjidil Haram locations
- Blue GPS dot for your live position
- GPS journey polyline overlay
- Tap any marker — description + related duas (tap doa → opens viewer)
- Long-press map — manually set your current zone
- Status bar shows current detected zone

### Analytics
- Anonymous usage analytics via Firebase Analytics (no personal data collected)

---

## Umrah Steps Covered

1. Ihram (mandi, solat, niat, talbiah, doa permulaan safar)
2. Masuk Kota Makkah
3. Melihat Ka'abah & Pintu Bani Syaibah
4. Tawaf (7 pusingan + Hijir Ismail)
5. Solat Sunat Tawaf (Makam Ibrahim, Multazam, Air Zam Zam)
6. Sa'ie (7 kali Safa–Marwah)
7. Tahallul (bercukur / bergunting)
8. Tawaf Wida' (7 pusingan + Solat Sunat Tawaf, Doa Makam Ibrahim, Minum Air Zam Zam)
9. Lain-lain Doa (Doa Musafir, Bab Salam, Bani Syaibah, Sujud Sajadah, Zamzam, Multazam, Hijir Ismail, Makam Ibrahim, Solat Jenazah, Peringatan Wanita, Tawaf Sunat, Wuduk)

---

## Getting Started

**Requirements:** Flutter 3.x, Android device or emulator

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`
AAB output: `build/app/outputs/bundle/release/app-release.aab`

Convenience scripts are included: `setup_and_run.bat` and `build_apk.bat`.

**Package name:** `com.faeq.umrahmas`

---

## Getting the APK

### Build commands

```bash
# Release APK (optimised, smaller — requires keystore for signing)
flutter build apk --release

# Debug APK (no keystore needed — for testing only)
flutter build apk --debug
```

Shortcut: run `build_apk.bat` from the project root — it builds the release APK automatically.

**Output path:**
```
build\app\outputs\flutter-apk\app-release.apk   (release)
build\app\outputs\flutter-apk\app-debug.apk     (debug)
```

### Install on Android device

1. Copy the APK file to your Android device (USB, cloud storage, or direct download).
2. On the device, go to **Settings → Apps → Special app access → Install unknown apps** and enable "Install from unknown sources" for your file manager or browser.
3. Open the APK file on the device and tap **Install**.
4. Once installed, open **Panduan Umrah** from the home screen.

> **Note:** The release APK must be signed with a keystore before distribution. For personal use, the debug APK is sufficient.

---

## Acknowledgements

This app is inspired by and based on the doa content from **M-Umrah Pro**, a pioneering mobile Umrah guidance app developed at Universiti Sains Malaysia (USM).

**Original research & content by:**
> **Assoc. Prof. Dr. Muhammad Rafie Hj. Mohd Arshad**
> School of Computer Sciences, Universiti Sains Malaysia

M-Umrah Pro has since been retired, but its doa images and audio recordings — made available for the Muslim community — form the core content of this app.

**Learn more:**
- [M-Umrah for the World — USM News](https://cs.usm.my/index.php/news-events/news-cs/375-m-umrah-for-the-world)
- [M-Umrah Pro coverage — Amanz.my](https://amanz.my/201228569)

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Material 3) |
| Language | Dart |
| Audio | [just_audio](https://pub.dev/packages/just_audio) |
| State | [provider](https://pub.dev/packages/provider) |
| HTML rendering | [flutter_html](https://pub.dev/packages/flutter_html) |
| Map | [flutter_map](https://pub.dev/packages/flutter_map) + [flutter_map_cache](https://pub.dev/packages/flutter_map_cache) |
| GPS | [geolocator](https://pub.dev/packages/geolocator) |
| Export | [pdf](https://pub.dev/packages/pdf) + [screenshot](https://pub.dev/packages/screenshot) + [share_plus](https://pub.dev/packages/share_plus) |
| Persistence | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| Analytics | [firebase_core](https://pub.dev/packages/firebase_core) + [firebase_analytics](https://pub.dev/packages/firebase_analytics) |

---

## Project Structure

```
lib/
├── data/
│   └── umrah_data.dart               # All step/doa content (hardcoded) — edit content here
├── models/
│   ├── umrah_step.dart               # UmrahStep, UmrahSubStep, DoaItem
│   ├── audio_provider.dart           # Global audio playback state + track-complete stream
│   ├── bookmark_provider.dart        # Bookmark save/load (shared_preferences)
│   ├── progress_provider.dart        # Guided-flow progress + Tawaf/Sa'ie round tracking
│   ├── location_provider.dart        # GPS tracking, zone detection, checkpoint recording
│   ├── journey_models.dart           # JourneyPoint, CheckpointRecord data classes
│   ├── journey_record.dart           # UmrahJourneyRecord with mutable date fields
│   ├── journey_history_provider.dart # Journey history CRUD + JSON persistence
│   └── umrah_location.dart           # UmrahLocation model + 7 Masjidil Haram zones
├── screens/
│   ├── splash_screen.dart            # 3 s splash with auto-navigation to HomeScreen
│   ├── home_screen.dart              # 4-tab nav: Menu / Umrah / Sejarah / Peta
│   ├── step_detail_screen.dart       # Step overview + substep list
│   ├── doa_list_screen.dart          # Doa thumbnails with quick play + bookmark toggle
│   ├── doa_viewer_screen.dart        # Full-screen PageView + audio nav + auto-play + checkpoints
│   ├── search_screen.dart            # SearchDelegate across all duas
│   ├── map_screen.dart               # Offline OSM map + GPS dot + zone markers
│   ├── umrah_ini_screen.dart         # Journey dashboard (start/end, GPS status, checkpoint tracker)
│   ├── umrah_tamat_screen.dart       # Summary: grouped timeline + map + PNG/PDF export
│   └── umrah_all_screen.dart         # All past journeys: list, edit, delete
├── services/
│   └── analytics_service.dart        # Firebase Analytics wrapper (static, no-op until initialized)
├── firebase_options.dart             # Generated by flutterfire configure (gitignored)
├── main.dart                         # App entry point, MultiProvider setup, Firebase init
└── utils/
    └── map_tile_cache.dart           # Shared in-memory OSM tile cache
```

### Android permissions required
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```
