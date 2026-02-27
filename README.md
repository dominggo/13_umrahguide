# Panduan Umrah

A Flutter Android app providing a complete step-by-step guide for performing Umrah, with doa (prayer) images and audio playback. UI is in Bahasa Malaysia.

## Features

### Doa Content
- **8 Umrah ritual steps** from Ihram to Tawaf Wida'
- **182 audio files** — listen to each doa recited aloud
- **163 doa images** — Arabic text with transliteration
- **Offline** — all content bundled in the app

### Navigation
- **Menu** — browse all 8 steps freely
- **Panduan Aliran** — linear guided walk-through with progress auto-save and resume
- **Carian (Search)** — search any doa by name across all steps

### Audio Playback
- **Auto-play groups** — audio advances automatically through a sequence of duas; `autoPlay: false` items act as manual break-points
- **Repeat** — loop the current auto-play group
- **Skip prev / next** — jump one doa at a time with auto-play

### Bookmarks
- Save any doa with the bookmark icon
- All bookmarks listed in the **Simpan** tab, grouped by step
- Persisted across app restarts

### Tawaf & Sa'ie Round Tracking
- 7-circle indicator in the AppBar when viewing Tawaf or Sa'ie rounds
- Confirmation dialog when reaching the last doa in each round: "Adakah anda telah melengkapkan pusingan ini?"
- Round status (confirmed / skipped / pending) persisted to device storage
- Missed rounds highlighted with a reminder banner

### Journey Recording ("Mulakan Perjalanan")
- GPS track recorded in the background during your Umrah (every 5 m movement)
- Auto-detects which Masjidil Haram zone you are in (Ka'abah, Hijir Ismail, Makam Ibrahim, Multazam, Telaga Zamzam, Bukit Safa, Bukit Marwah)
- Manual zone override if GPS is unavailable
- Journey events logged (step start, doa played, round confirmed) with timestamps and coordinates
- **"Selesai Ibadah Umrah"** button ends the journey and opens the summary screen

### Journey Summary & Export
- Total distance (km) and duration
- OSM map with GPS polyline
- Step-by-step timeline with timestamps and doa counts
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
- Tap any marker → description + related duas (tap doa → opens viewer)
- Long-press map → manually set your current zone
- Status bar shows current detected zone

---

## Umrah Steps Covered

1. Ihram (mandi, solat, niat, talbiah, doa permulaan safar)
2. Masuk Kota Makkah
3. Melihat Ka'abah & Pintu Bani Syaibah
4. Tawaf (7 pusingan + Hijir Ismail)
5. Solat Sunat Tawaf (Makam Ibrahim, Multazam, Air Zam Zam)
6. Sa'ie (7 kali Safa–Marwah)
7. Tahallul (bercukur / bergunting)
8. Tawaf Wida'

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
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

Convenience scripts are included: `setup_and_run.bat` and `build_apk.bat`.

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

---

## Project Structure

```
lib/
├── data/
│   └── umrah_data.dart          # All step/doa content (hardcoded) — edit content here
├── models/
│   ├── umrah_step.dart          # UmrahStep, UmrahSubStep, DoaItem
│   ├── audio_provider.dart      # Global audio playback state + track-complete stream
│   ├── bookmark_provider.dart   # Bookmark save/load (shared_preferences)
│   ├── progress_provider.dart   # Guided flow progress + Tawaf/Sa'ie round tracking
│   ├── location_provider.dart   # GPS tracking, zone detection, journey recording
│   ├── journey_models.dart      # JourneyPoint, JourneyEvent data classes
│   ├── journey_record.dart      # UmrahJourneyRecord with mutable date fields
│   ├── journey_history_provider.dart  # Journey history CRUD + JSON persistence
│   └── umrah_location.dart      # UmrahLocation model + 7 Masjidil Haram zones
├── screens/
│   ├── home_screen.dart         # 4-tab nav: Menu / Panduan Aliran / Simpan / Peta
│   ├── step_detail_screen.dart  # Step overview + substep list
│   ├── substep_screen.dart      # Doa thumbnails with quick play + bookmark toggle
│   ├── doa_viewer_screen.dart   # Full-screen PageView + audio nav + auto-play + rounds
│   ├── guide_flow_screen.dart   # Linear guided flow with progress save + round dialogs
│   ├── search_screen.dart       # SearchDelegate across all duas
│   ├── makkah_map_screen.dart   # Offline OSM map + GPS dot + zone markers
│   ├── journey_screen.dart      # Journey dashboard (start/end, GPS status, round tracker)
│   ├── journey_summary_screen.dart  # Summary: map + timeline + PNG/PDF export
│   └── journey_history_screen.dart  # All past journeys: list, edit, delete
└── utils/
    └── map_tile_cache.dart      # Shared in-memory OSM tile cache
```

### Android permissions required
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```
