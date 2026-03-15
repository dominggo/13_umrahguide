# Custom Icons Guide

All custom icons live in one folder: `assets/images/custom_icons/`

Drop your PNG files there and rebuild — icons appear automatically. If a file is missing, the app falls back to the original Material Icon silently.

---

## Step Card Icons

Shown in the 3×3 grid on the Menu tab. Displayed at **40×40 px** inside a coloured header bar.

**Recommended source size:** 80×80 px or larger (square, transparent background)

| Filename | Step |
|---|---|
| `step_ihram.png` | 1. Ihram |
| `step_tawaf.png` | 2. Tawaf |
| `step_solat_tawaf.png` | 3. Solat Sunat Tawaf |
| `step_saie.png` | 4. Sa'ie |
| `step_tahallul.png` | 5. Tahallul |
| `step_tawaf_wida.png` | 6. Tawaf Wida' |
| `step_lain_lain.png` | 7. Lain-lain Doa |
| `step_panduan.png` | 8. Panduan dan Tips |

> Icons are tinted **white** automatically via Flutter's `color: Colors.white` — so use a solid single-colour PNG or a white icon on transparent background.

---

## Bottom Navigation Bar Icons

Shown in the nav bar at the bottom of the screen. Displayed at **24×24 px**.

**Recommended source size:** 48×48 px or larger (square, transparent background)

Each tab has two versions: unselected and selected (active).

| Filename | Tab | State |
|---|---|---|
| `nav_menu.png` | Menu | Unselected |
| `nav_menu_active.png` | Menu | Selected |
| `nav_umrah.png` | Umrah | Unselected |
| `nav_umrah_active.png` | Umrah | Selected |
| `nav_sejarah.png` | Sejarah | Unselected |
| `nav_sejarah_active.png` | Sejarah | Selected |
| `nav_peta.png` | Peta | Unselected |
| `nav_peta_active.png` | Peta | Selected |

> Nav icons are **not** tinted — use the actual colours you want in the PNG itself (e.g. grey for unselected, green for active).

---

## Splash Screen Icon

Shown centred on the green splash screen inside a white rounded card.

**Displayed size:** 72×72 px inside a 120×120 white card
**Recommended source size:** 256×256 px (square, solid colour works best against white background)

| Filename | Used for |
|---|---|
| `splash_icon.png` | Centre icon on the splash screen |

---

## App Launcher Icon (Android)

These are the icons shown on the Android home screen and app drawer. Replace each file directly — keep the exact filename `ic_launcher.png`.

| Folder | Required size |
|---|---|
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | 48×48 px |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | 72×72 px |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | 96×96 px |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | 144×144 px |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | 192×192 px |

**Tip — resize from one source PNG using Python:**

```python
# pip install Pillow
from PIL import Image

sizes = {
    "mdpi":    48,
    "hdpi":    72,
    "xhdpi":   96,
    "xxhdpi":  144,
    "xxxhdpi": 192,
}

src = Image.open("my_icon_1024.png").convert("RGBA")

for dpi, px in sizes.items():
    out = src.resize((px, px), Image.LANCZOS)
    out.save(f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png")
    print(f"Saved {dpi} ({px}x{px})")
```

---

## Quick Checklist

- [ ] PNG format, transparent background (except launcher icons which should be opaque)
- [ ] Square aspect ratio
- [ ] File placed in `assets/images/custom_icons/` (or mipmap folders for launcher)
- [ ] Exact filename match (case-sensitive on Linux/Android)
- [ ] Run `flutter pub get` then `flutter run` or `flutter build apk --release`
