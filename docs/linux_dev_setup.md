# Linux Dev Setup — Flutter on This Server

This guide documents how to set up and use Flutter on this Linux server (Ubuntu 24.04 x86_64).

## Environment

| Item | Value |
|------|-------|
| OS | Ubuntu 24.04 LTS |
| Flutter | 3.27.4 installed at `/opt/flutter` — **outdated**, see note below |
| Dart | 3.6.2 |
| Java | OpenJDK 17 (required for Android builds) |
| Home directory | `/root` |
| Project directory | `/mnt/shared/13_umrahguide/umrah_guide` |

> **Flutter version note (2026-10-14):** the Android build config was updated for the latest Flutter (3.47.x): Gradle 8.14.3, AGP 8.11.1, Kotlin 2.3.x, NDK 27. The project is verified on Flutter **3.47.7** (Windows, JDK 17). The 3.27.4 install on this server predates that change and has **not** been re-tested against it; upgrade Flutter here (`cd /opt/flutter && git fetch && git checkout stable`) before building.
>
> `lib/firebase_options.dart` and `android/app/google-services.json` are gitignored. Copy them from this server's project folder when setting up a new machine (Analytics is disabled without them, the app still runs).

---

## 1. Set Up PATH (every new shell session)

Flutter is not in the system PATH by default. Run this before any `flutter` command:

```bash
export PATH="/opt/flutter/bin:$PATH"
```

To make this permanent, add it to `/root/.bashrc`:

```bash
echo 'export PATH="/opt/flutter/bin:$PATH"' >> /root/.bashrc
source /root/.bashrc
```

---

## 2. Install Dependencies

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
cd /mnt/shared/13_umrahguide/umrah_guide
flutter pub get
```

---

## 3. Lint / Analyze

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
cd /mnt/shared/13_umrahguide/umrah_guide
flutter analyze
```

Expected output: `No issues found!`

---

## 4. Run Tests

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

---

## 5. Build APK

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
cd /mnt/shared/13_umrahguide/umrah_guide

# Debug APK
flutter build apk --debug
# Output: /mnt/shared/13_umrahguide/umrah_guide/build/app/outputs/flutter-apk/app-debug.apk

# Release APK (requires keystore — see android/key.properties)
flutter build apk --release
# Output: /mnt/shared/13_umrahguide/umrah_guide/build/app/outputs/flutter-apk/app-release.apk
```

---

## 6. Build App Bundle (Play Store)

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
cd /mnt/shared/13_umrahguide/umrah_guide
flutter build appbundle --release
# Output: /mnt/shared/13_umrahguide/umrah_guide/build/app/outputs/bundle/release/app-release.aab
```

---

## 7. Clean Build Cache

**Run from:** `/mnt/shared/13_umrahguide/umrah_guide`

```bash
cd /mnt/shared/13_umrahguide/umrah_guide
flutter clean
flutter pub get   # re-fetch dependencies after clean
```

---

## Notes

- **Running as root:** Flutter will warn `"You appear to be trying to run flutter as root"` — this is safe to ignore on this server.
- **Android device/emulator:** `flutter run` requires a connected Android device or running emulator. This server has no display, so `flutter run` is not applicable here.
- **Keystore for release builds:** The signing keystore is at `android/app/upload-keystore.jks` with credentials in `android/key.properties` (not committed to git).
- **Gradle build cache** lives at `/root/.gradle/` and can grow large over time. Clear with `rm -rf /root/.gradle/caches` if disk space is an issue.
