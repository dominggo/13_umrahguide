# Android emulator (AVD) testing for Umrah: handover to k9s

Status 2026-10-24: **first attempt on win-z620 failed and was removed. Retry on k9s.** Tracked in the main todo,
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

## Plan for k9s
1. Check hardware virtualization is on (`systeminfo`: "Virtualization Enabled In Firmware: Yes", or Task Manager > CPU).
   Run `emulator -accel-check` and follow what it says (Windows Hypervisor Platform / AEHD / HAXM).
   Keep at least 16 GB RAM free and about 6 GB disk per AVD.
2. Install the SDK with `sdkmanager`: `cmdline-tools;latest`, `platform-tools`, `emulator`,
   `system-images;android-35;google_apis_playstore;x86_64` (the Google Play image is required for the Play Store).
   Put it on the big drive, set `ANDROID_AVD_HOME` there, run `sdkmanager --licenses`.
   Do not change a global `ANDROID_HOME` that scoop manages; use its own `sdkmanager`/`avdmanager` paths.
3. Create ONE AVD first: `avdmanager create avd -n umrah-t1 -k "system-images;android-35;google_apis_playstore;x86_64" -d pixel_8`.
   `avdmanager` can write `PlayStore.enabled=no`; set it to `yes` in the AVD's `config.ini`.
4. Boot it from a normal PowerShell window and wait for `adb shell getprop sys.boot_completed` = 1.
   Try GPU modes in this order: `-gpu host` (needs a real GPU), `angle_indirect`, `swiftshader_indirect`.
   First boot takes minutes; later boots resume from the snapshot.
5. In the AVD: Play Store > sign in as tester 1 (an established `closed1` account) > open the web opt-in link
   `https://play.google.com/apps/testing/com.faeq.umrahmas` > Become a tester > install from
   `https://play.google.com/store/apps/details?id=com.faeq.umrahmas`.
6. Check the Dashboard opted-in count went up (it can lag a day). Only then create AVD 2..5, one at a time.

## Fallbacks
- Sideload the release APK: `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk`
  (debug builds use `com.faeq.umrahmas.dev`).
- Use a real second phone for the Play opt-in path.

## Caveats
- Emulators usually fail strong Play Integrity. Fine for installing from Play and testing the app, since the app does not call it.
- Use established accounts and add them gradually; many fresh accounts from one IP/device can trigger verification.
  Do not spoof the device.
