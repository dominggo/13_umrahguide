# Android emulator (AVD) testing for Umrah (k9s)

Status 2026-10-24: **working on k9s.** Panduan Umrah was installed from Play and runs in `umrah-t1`. Open items are tracked only in `P:\mnt\shared\00_proxmox\docs\todo.md` (section "Umrah Guide"), not here.

Goal (optional): test the Alpha opt-in and Play install path from several tester accounts, one emulator at a time. The release already passed on a real phone, and real testers can opt in instead.

## Do not use win-z620
It is a Proxmox VM (nested virtualization). AEHD said OK but the emulator never showed a window and adb stayed `offline`; it also died when started from a background or Claude Code `!` shell. Everything was removed on 2026-10-24. Always start emulators from a normal PowerShell window on the k9s desktop.

## Setup on k9s (done 2026-10-24)
- Acceleration: Windows Hypervisor Platform (`emulator -accel-check` OK); no AEHD/HAXM.
- SDK `F:\android-sdk` (emulator 37.2.12, `system-images;android-35;google_apis_playstore;x86_64`, platform-tools, plus a COPY of cmdline-tools in `cmdline-tools\latest` because `avdmanager` has no `--sdk_root` flag). `adb`: `F:\android-sdk\platform-tools\adb.exe`.
- AVDs in `F:\android-avd`: `umrah-t1`..`umrah-t5` (Pixel 8, Play image, 2 vCPU, 3 GB RAM, `PlayStore.enabled=yes`, `hw.keyboard=yes`). `avdmanager` prints a harmless "Could not load devices from ...devices.xml".
- Launchers: `F:\android-avd\start-avd.cmd <avdname>`, desktop shortcuts `P:\OneDrive\Desktop\AVD\Umrah tester 1..5.lnk`. It runs `emulator.exe -avd <name> -gpu swiftshader_indirect -feature -Vulkan -no-snapshot-save` with the SDK env set for that process only.
- Env gotcha: the global `ANDROID_HOME` (`C:\Users\user\Android\Sdk`, scoop/Flutter) wins over `ANDROID_SDK_ROOT` and gives "Broken AVD system path". Set `ANDROID_HOME`, `ANDROID_SDK_ROOT`, `ANDROID_AVD_HOME` for the emulator process only; never change the global value.
- Stable GPU mode: `swiftshader_indirect` with Vulkan off. `angle_indirect` crashed qemu (0xc0000005) on Home/Play, and swiftshader crashed with Vulkan on. First boot after a mode change takes a few minutes. `host` not tried.
- Black screen is not a freeze: Android sleeps after 10 s on the lock screen and `adb input` cannot dismiss it. Swipe up with the mouse and run `adb shell "dumpsys battery set ac 1; svc power stayon true"` (lost on cold boot).
- Each emulator uses about 3 GB of the 16 GB: run 2-3 at most.

## Use
In an AVD: Play Store > sign in as an established `closed1` tester > open `https://play.google.com/apps/testing/com.faeq.umrahmas` > Become a tester > install from `https://play.google.com/store/apps/details?id=com.faeq.umrahmas`. Check the Dashboard opted-in count later (it can lag a day) and add accounts to the other AVDs gradually.

## Fallbacks
- Sideload: `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk` (debug builds use `com.faeq.umrahmas.dev`).
- Use a real second phone for the Play opt-in path.

## Caveats
Emulators usually fail strong Play Integrity; fine here since the app does not call it. Use established accounts and add them gradually (many fresh accounts from one IP/device can trigger verification). Do not spoof the device.
