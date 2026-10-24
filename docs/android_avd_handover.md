# Android emulator (AVD) testing for Umrah (k9s)

Status 2026-10-24: **win-z620 attempt failed and was removed. k9s install DONE: 5 AVDs + desktop launchers ready; remaining = sign in, opt in, install from Play.** Tracked in the main todo,
`P:\mnt\shared\00_proxmox\docs\todo.md` (section "Umrah Guide"). Do not keep a separate todo here.

## Goal
Test the Umrah app from several Google Play tester accounts on the Alpha track (sign in, accept the opt-in,
install from Play), one emulator at a time, so the opted-in count and the Play install path can be checked.
This is optional: the release build already passed on a real phone, and real testers can opt in instead.

## What was tried on win-z620 (and why it failed)
- win-z620 is a Proxmox VM (nested virtualization). SDK in `P:\android-sdk` (emulator 37.2.12,
  `system-images;android-35;google_apis_playstore;x86_64`), 5 AVDs `umrah-t1..t5` (Pixel 8, 2 vCPU, 2 GB RAM).
- AEHD 2.2 installed; `emulator -accel-check` said OK and the log said "AEHD is operational".
- The emulator process ran but **never showed a window and adb stayed `offline`** (`getprop sys.boot_completed` never answered).
- Only GPU was an NVIDIA NVS 310; the log said "Failed to load opengl32sw ... falling back to system OpenGL"
  with `-gpu swiftshader_indirect`.
- Starting it from the Claude Code `!` shell or a background process gave no desktop window and the emulator
  died when that shell ended. Always start emulators from a normal PowerShell window on the desktop.
- Everything was removed with `00_proxmox\scripts\cleanup-umrah-avd.ps1` (asks for UAC): AEHD driver and `P:\android-sdk`.
  The old `umrah_pixel` AVD in `C:\Users\user\.android\avd` was deleted too (not needed for builds).

## Setup on k9s (done 2026-10-24)
- Acceleration: Windows Hypervisor Platform works (`emulator -accel-check`: "WHPX(10.0.26200) is installed and usable"); no AEHD/HAXM needed.
- SDK: `F:\android-sdk` (emulator 37.2.12, `system-images;android-35;google_apis_playstore;x86_64`, platform-tools,
  and a COPY of cmdline-tools in `F:\android-sdk\cmdline-tools\latest` so `avdmanager` resolves this root; `avdmanager`
  has no `--sdk_root` flag and otherwise looks in scoop's SDK and reports "Package path is not valid").
  Licences accepted with `sdkmanager --sdk_root=F:\android-sdk --licenses`. `adb`: `F:\android-sdk\platform-tools\adb.exe`.
- AVDs in `F:\android-avd`: `umrah-t1`..`umrah-t5` (Pixel 8, android-35 Play image, 2 vCPU, 3072 MB RAM, `PlayStore.enabled=yes`).
  `avdmanager` prints a harmless "Could not load devices from ...devices.xml" error but still creates the AVD.
- Env gotcha: the global user `ANDROID_HOME` (`C:\Users\user\Android\Sdk`, scoop/Flutter) takes priority over
  `ANDROID_SDK_ROOT`, so the emulator died with "Broken AVD system path". Set `ANDROID_HOME`, `ANDROID_SDK_ROOT` and
  `ANDROID_AVD_HOME` for the emulator process only; do not change the global value.
- Launchers: `F:\android-avd\start-avd.cmd <avdname>` sets that env and runs
  `emulator.exe -avd <name> -gpu angle_indirect`. Desktop shortcuts `P:\OneDrive\Desktop\AVD\Umrah tester 1..5.lnk` call it.
- Result: `umrah-t1` booted with a window in about 3 min (`sys.boot_completed`=1, Android 15, Play Store + Gmail present).
  `-gpu angle_indirect` works on k9s (Quadro K420); not tried: `host`, `swiftshader_indirect`.
- Memory: each emulator takes about 3 GB and k9s has 16 GB, so run 2-3 at most.

## Still to do (tracked in the main todo)
1. In an AVD: Play Store > sign in as an established `closed1` tester > open
   `https://play.google.com/apps/testing/com.faeq.umrahmas` > Become a tester > install from
   `https://play.google.com/store/apps/details?id=com.faeq.umrahmas`.
2. Check the Dashboard opted-in count went up (can lag a day). Add accounts to the other AVDs gradually.
## Fallbacks
- Sideload the release APK: `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk`
  (debug builds use `com.faeq.umrahmas.dev`).
- Use a real second phone for the Play opt-in path.

## Caveats
- Emulators usually fail strong Play Integrity. Fine for installing from Play and testing the app, since the app does not call it.
- Use established accounts and add them gradually; many fresh accounts from one IP/device can trigger verification.
  Do not spoof the device.
