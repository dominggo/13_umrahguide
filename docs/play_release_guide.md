# Release Guide (Google Play + GitHub)

How Panduan Umrah (`com.faeq.umrahmas`) is versioned, built, uploaded to Play and tagged on GitHub. Updated 2026-10-25 (merged the old `github_release_guide.md`). Current status of the closed test: `play_closed_test_handoff.md` (local only).

## 1. Prerequisites (Windows)

1. Install with scoop: `temurin17-jdk`, `flutter`, `android-clt`.
2. Create an SDK on `C:` (not the shared `P:` drive) and set `ANDROID_HOME`, for example `C:\Users\<you>\Android\Sdk`.
3. Install with `sdkmanager --sdk_root=%ANDROID_HOME%`: `cmdline-tools;latest`, `platform-tools`, `platforms;android-35`, `platforms;android-36`, `build-tools;36.0.0`, `ndk;27.0.12077973`, `cmake;3.22.1`, and accept the licences.
4. `flutter doctor -v` must show the Android toolchain with all licences accepted. A missing `cmdline-tools` makes the release build fail with "failed to strip debug symbols from native libraries".
5. Gitignored files must exist: `lib/firebase_options.dart`, `android/app/google-services.json` (needs clients for `com.faeq.umrahmas` and `com.faeq.umrahmas.dev`), `android/key.properties`, `android/app/upload-keystore.jks`.

## 2. Versioning

`version: MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.

- MINOR for new features, PATCH for bug fixes only, MAJOR for a rewrite.
- **BUILD must increase on every Play upload and never reset**, even across major versions. Play rejects a repeated or lower version code. History: 1.0.0+1, 1.1.0+2/+3, 1.2.0+4.
- Work on `master`; use a feature branch only for work that takes more than a day. Bump the version in its own commit right before the release.
- Commit prefixes: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`.
- Fix a bad pushed commit with `git revert`, never `git reset --hard`.

## 3. Build

```
flutter analyze && flutter test
flutter build apk --debug           # installs as "Panduan Umrah dev" (com.faeq.umrahmas.dev)
flutter build appbundle --release   # build/app/outputs/bundle/release/app-release.aab (7-10 min on P:)
flutter build apk --release         # build/app/outputs/flutter-apk/app-release.apk (for GitHub / sideloading)
```

- Verify the signature: `jarsigner -verify -certs app-release.aab` should print "jar verified".
- Afterwards run `git status` and revert any rewrite of `analysis_options.yaml`, `pubspec.lock` or `android/gradle.properties`.
- Phone install: enable USB debugging and "Install via USB" (Xiaomi), unlock the phone, then `adb install -r build/app/outputs/flutter-apk/app-debug.apk`.

## 4. Upload and submit (Play Console)

1. Test and release > Testing > Closed testing > Alpha > Create new release (or edit the draft).
2. Upload `app-release.aab` by hand. It is about 85 MB, above the 10 MB limit of browser automation tools.
3. Remove older bundles from the draft, add release notes (Malay, inside `<ms-MY>` tags), then Next > Save.
4. Make sure countries and testers are set on the track (Alpha > Countries / regions, Testers).
5. Publishing overview > "Submit N changes for review". Pre-review checks can take about 14 minutes; fix any issue shown (for example the advertising ID declaration).
6. Review can take up to about 7 days (1.2.0+4 went live the same day). Play does not email testers; send them the opt-in links.

## 5. Tag and GitHub release

After the Play upload is accepted:

```
git push origin master
git tag vX.Y.Z && git push origin vX.Y.Z
```

Then github.com/dominggo/13_umrahguide/releases > Draft a new release > pick the tag > title "vX.Y.Z — short summary" > notes (new, fixed, known issues) > attach `app-release.apk` (and the `.aab` as an archive copy) > Publish. Forgot to tag? `git tag vX.Y.Z <hash>` works on any past commit.

## 6. Production access (personal account)

- Production and open testing are locked until a closed test has at least 12 testers opted in for 14 consecutive days.
- Tester list `closed1` has 52 addresses (see the local `play_closed_test_testers.md`); each must open the opt-in link and stay opted in.
- After day 14: Dashboard > apply for production access, then create a production release with a higher version code.

## 7. Declarations currently on file

- Data safety: collects App interactions and Device or other IDs for Analytics (Firebase), not shared; encrypted in transit; no accounts; no deletion path.
- Advertising ID: used, purpose Analytics only (the manifest includes `com.google.android.gms.permission.AD_ID` via Firebase Analytics).
- AI-generated assets: "Don't label assets" for the store listing graphics.
- Privacy policy: pinned to commit `1690ff0` of `docs/PRIVACY_POLICY.md` on GitHub; keep that commit reachable and update the Play URL when the policy changes.

## 8. Signing files

The keystore is the only way to publish updates and cannot be regenerated. Copies exist on linku and in the OneDrive folder `P:\OneDrive\Apps\umrah-app-signing\` (hash-verified 2026-10-19). If all copies are lost, request an upload-key reset in Play Console (Play App Signing is on).

## 9. Pending work

The main todo for all projects is `P:\mnt\shared\00_proxmox\docs\todo.md` (section "Umrah Guide"); this repo does not keep its own todo file.
