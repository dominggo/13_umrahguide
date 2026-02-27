# Panduan Umrah

A Flutter Android app providing a complete step-by-step guide for performing Umrah, with doa (prayer) images and audio playback. UI is in Bahasa Malaysia.

## Features

- **8 Umrah ritual steps** from Ihram to Tawaf Wida'
- **182 audio files** — listen to each doa recited aloud
- **163 doa images** — Arabic text with transliteration
- **Two navigation modes:**
  - **Menu** — browse all 8 steps freely
  - **Panduan Aliran** — linear guided walk-through with progress tracking
- Offline — all content bundled in the app

## Umrah Steps Covered

1. Ihram (mandi, solat, niat, talbiah, doa permulaan safar)
2. Masuk Kota Makkah
3. Melihat Ka'abah & Pintu Bani Syaibah
4. Tawaf (7 pusingan + Hijir Ismail)
5. Solat Sunat Tawaf (Makam Ibrahim, Multazam, Air Zam Zam)
6. Sa'ie (7 kali Safa–Marwah)
7. Tahallul (bercukur / bergunting)
8. Tawaf Wida'

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

## Project Structure

```
lib/
├── data/umrah_data.dart       # All step/doa content (hardcoded)
├── models/
│   ├── umrah_step.dart        # UmrahStep, UmrahSubStep, DoaItem
│   └── audio_provider.dart    # Global audio playback state
└── screens/
    ├── home_screen.dart        # BottomNav: menu grid + flow timeline
    ├── step_detail_screen.dart # Step overview + substep list
    ├── substep_screen.dart     # Doa thumbnails with quick play
    ├── doa_viewer_screen.dart  # Full-screen PageView + audio nav
    └── guide_flow_screen.dart  # Linear guided flow
```
