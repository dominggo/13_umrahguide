# Google Play Release Guide

How Panduan Umrah (`com.faeq.umrahmas`) is built, uploaded and submitted. Written 2026-10-19 after the first closed-test submission of `1.1.0+3`.

## 1. Prerequisites (Windows)

1. Install with scoop: `temurin17-jdk`, `flutter`, `android-clt`.
2. Create an SDK on `C:` (not the shared `P:` drive) and set `ANDROID_HOME`, for example `C:\Users\<you>\Android\Sdk`.
3. Install with `sdkmanager --sdk_root=%ANDROID_HOME%`: `cmdline-tools;latest`, `platform-tools`, `platforms;android-35`, `platforms;android-36`, `build-tools;36.0.0`, `ndk;27.0.12077973`, `cmake;3.22.1`, and accept the licences.
4. `flutter doctor -v` must show the Android toolchain with all licences accepted. A missing `cmdline-tools` makes the release build fail with "failed to strip debug symbols from native libraries".
5. Gitignored files must exist: `lib/firebase_options.dart`, `android/app/google-services.json` (needs clients for `com.faeq.umrahmas` and `com.faeq.umrahmas.dev`), `android/key.properties`, `android/app/upload-keystore.jks`.

## 2. Build

```
flutter build apk --debug           # installs as "Panduan Umrah dev" (com.faeq.umrahmas.dev)
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab (about 7 min on P:)
```

- Bump the build number in `pubspec.yaml` (`version: 1.1.0+N`) before every upload; Play rejects a repeated version code.
- Verify the signature: `jarsigner -verify -certs app-release.aab` should print "jar verified".
- Afterwards run `git status` and revert any rewrite of `analysis_options.yaml` or `pubspec.lock`.
- Phone install: enable USB debugging and "Install via USB" (Xiaomi), unlock the phone, then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

## 3. Upload and submit (Play Console)

1. Test and release > Testing > Closed testing > Alpha > Create new release (or edit the draft).
2. Upload `app-release.aab` by hand. It is about 88.7 MB, which is above the 10 MB limit of browser automation tools.
3. Remove older bundles from the draft, add release notes (Malay, inside `<ms-MY>` tags), then Next > Save.
4. Make sure countries and testers are set on the track (Alpha > Countries / regions, Testers).
5. Publishing overview > "Submit N changes for review". Pre-review checks can take about 14 minutes; fix any issue shown (for example the advertising ID declaration).
6. Review takes about 7 days. After approval, the opt-in links appear on the Testers tab; Play does not email testers.

## 4. Production access (personal account)

- Production and open testing are locked until a closed test has at least 12 testers opted in for 14 consecutive days.
- Tester list `closed1` has 15 Gmail accounts. Each must open the opt-in link and stay opted in.
- After day 14: Dashboard > apply for production access, then create a production release with a higher version code.

## 5. Declarations currently on file

- Data safety: collects App interactions and Device or other IDs for Analytics (Firebase), not shared; encrypted in transit; no accounts; no deletion path.
- Advertising ID: used, purpose Analytics only (the manifest includes `com.google.android.gms.permission.AD_ID` via Firebase Analytics).
- AI-generated assets: "Don't label assets" for the store listing graphics.
- Privacy policy: pinned to commit `1690ff0` of `docs/PRIVACY_POLICY.md` on GitHub; keep that commit reachable.

## 6. Signing files

The keystore is the only way to publish updates and cannot be regenerated. Keep copies outside the build machine and outside linku. If it is lost, request an upload-key reset in Play Console (Play App Signing is on).
