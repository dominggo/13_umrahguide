# Android emulator (AVDs) for Umrah multi-account testing

Handover for continuing in the `umrah-app` project (Claude Code). Set up 2026-10-24 on win-z620.

## Goal
Test the Umrah app from up to 5 different Google Play tester accounts (Alpha track),
each account persistent (login + installed app kept), run one at a time, GUI.

## What exists
- SDK: `P:\android-sdk` (emulator 37.2.12, platform-tools, platforms;android-35,
  system-images;android-35;google_apis_playstore;x86_64, cmdline-tools;latest).
  Kept off C: (37 GB free); each AVD ~4-6 GB.
- AVDs: `umrah-t1` .. `umrah-t5` in `P:\android-sdk\avd` (Pixel 8, Play Store enabled,
  2 vCPU / 2 GB RAM / 8 GB data). Each keeps its own Google login and installed apps.
- Hypervisor: AEHD 2.2 installed (admin, `silent_install.bat`), `emulator -accel-check` OK,
  so nested virtualization works on this Proxmox VM. No VBS/Hyper-V change was needed.
- Launcher: `scripts/umrah-avd.ps1 <1-5>` (sets its own ANDROID_* env, GPU swiftshader_indirect).
  Run: `pwsh P:\mnt\shared\00_proxmox\scripts\umrah-avd.ps1 1`

## Gotchas
- Global `ANDROID_HOME` points to the scoop SDK (`...\scoop\apps\android-clt\current`).
  Do NOT change it. `avdmanager` derives its SDK root from its own location, so use
  `P:\android-sdk\cmdline-tools\latest\bin\avdmanager.bat` (scoop's one only sees android-34).
- avdmanager wrote `PlayStore.enabled=no`; fixed to `yes` in each AVD's config.ini.
- A separate older AVD `umrah_pixel` lives in `C:\Users\user\.android\avd` (untouched).
- First boot of each AVD takes minutes; later boots resume from snapshot.
- `adb` is on PATH (scoop); the P: copy is `P:\android-sdk\platform-tools\adb.exe`.

## State when handed over
- `umrah-t1` was launched and booting (adb `emulator-5554`). Not yet signed in to Play.
- Not yet done: sign in per AVD, opt in to Alpha track, install Umrah from Play,
  boot-test performance on 4 vCPUs (tune GPU mode / RAM if slow).

## Next steps (in umrah-app)
1. Start AVD N, open Play Store, sign in with tester N, accept the Alpha opt-in, install the app.
2. Repeat for the other testers, one AVD at a time.
3. For dev builds: `adb -s emulator-5554 install -r app-release.apk` (sideload skips the Play path).

## Caveats
- Emulators are detectable by Google (Play Integrity usually fails strong integrity).
  Fine for installing from Play and testing the app, unless the app calls Play Integrity.
- Use established accounts and add them gradually; many fresh accounts from one IP/device
  can trigger verification. Do not spoof the device.
