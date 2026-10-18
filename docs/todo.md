# TODO — Panduan Umrah

Last updated: 2026-10-19

## Google Play release (blocking)

- [x] Signed release bundle `1.1.0+3` built and uploaded to Closed testing "Alpha"
- [x] Store listing (text, icon, feature graphic, 6 phone screenshots), data safety, ad ID declaration, privacy policy URL
- [x] 14 changes submitted for review on 2026-10-19 (pre-review checks were still running)
- [ ] Confirm the review result in Play Console > Publishing overview (about 7 days)
- [ ] Send the opt-in link (Alpha > Testers > "How testers join your test") to all 15 testers in list `closed1`; Play does not email them
- [ ] Keep at least 12 testers opted in for 14 consecutive days
- [ ] After day 14: apply for production access on the Dashboard
- [ ] Submit a production release (bump the build number first; Play already has 2 and 3)
- [ ] Optional: reorder the 6 screenshots so the Menu one is first; tablet screenshots are not required

## Safety (do soon)

- [ ] **Back up the signing and Firebase files outside linku and outside this PC**: `android/app/upload-keystore.jks`, `android/key.properties`, `lib/firebase_options.dart`, `android/app/google-services.json`. The keystore cannot be regenerated; if it is lost, an upload-key reset must be requested from Google. The earlier note about a OneDrive backup (`P:\OneDrive\backup\umrah-app-signing`) was wrong: that folder does not exist.
- [ ] Keep commit `1690ff0` (privacy policy) reachable on GitHub; Play links to it. Update the Play privacy policy URL whenever `docs/PRIVACY_POLICY.md` changes.

## App polish (next update)

- [ ] Replace the remaining Material mosque icons (splash fallback, journey history list, journey summary) with the new icon set
- [ ] Redo the history clock icon (hands look like crossed swords at small size) and the Sa'ie icon (hills look rocky); regenerate Ihram/Tawaf icons if desired
- [ ] Doa list thumbnails still fall back to `ic_default.png` ("DEFAULT") in some places; assets in `assets/images/icons/` are old glossy icons from M-Umrah Pro, so confirm usage rights before relying on them
- [ ] Decide whether to keep Firebase Analytics and the AD_ID permission (declared as Analytics only); removing the permission would need a manifest `tools:node="remove"` entry and a new bundle
- [ ] Brunei is not selectable in Play country lists; no action unless Google adds it

## Dev environment

- [ ] Install `analysis_options.yaml`/`pubspec.lock` guard: after any `flutter` run, `git status` and revert unintended rewrites (see CLAUDE.md)
- [ ] Consider uploading a smaller bundle (the 88.7 MB `.aab` exceeds the 10 MB browser-automation upload limit, so it must be uploaded manually)
