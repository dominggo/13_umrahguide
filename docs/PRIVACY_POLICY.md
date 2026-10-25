# Privacy Policy — Panduan Umrah
# Dasar Privasi — Panduan Umrah

**Effective Date / Tarikh Berkuat Kuasa:** 25 October 2026  
**App / Aplikasi:** Panduan Umrah (`com.faeq.umrahmas`)  
**Developer / Pembangun:** Badruz@faeq  
**Contact / Hubungi:** umrah@faeq.net

---

## English

### 1. Overview

Panduan Umrah is a Flutter-based Android application that provides step-by-step Umrah guidance including doa (prayers), audio recitations, GPS journey tracking, and maps of Masjidil Haram. This policy explains what data is collected and how it is used.

### 2. Data We Collect

#### a) Location Data (GPS)
- The app requests `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions.
- GPS data is used **only within the app, and only while the app is open** (there is no background location tracking), to detect your zone inside Masjidil Haram and to record your Umrah journey path. You can deny the permission and still use the guide.
- Location data is **stored locally on your device** (journey records in the app's private storage) and is **never transmitted to any server** by this app.

#### b) Map Tiles (OpenStreetMap)
- The map screens download map tiles from `tile.openstreetmap.org`. Like any web request, this exposes your IP address and the tile coordinates requested to OpenStreetMap. Your GPS position is **not** sent; only the map area being viewed is requested. Downloaded tiles are kept in a cache on your device so they can be shown again offline. The app therefore uses the `INTERNET` and `ACCESS_NETWORK_STATE` permissions.

#### c) Anonymous Analytics
- The app uses **Firebase Analytics** to collect anonymous, aggregated usage data.
- App events we log: when a journey or Tawaf Wida' session starts or finishes (journey type and number of checkpoints completed), when a checkpoint is completed (checkpoint number and name), and which step of the guide is opened.
- Firebase also collects some data automatically: an app-instance identifier, the Android advertising ID, device model, Android version, app version, language, and approximate region derived from the IP address. We use this only for analytics, not for advertising, and we do not share it with anyone else.
- **No GPS coordinates, journey tracks, bookmarks or exported files are sent** through analytics, and the app does not ask for your name or email.
- You can reset or delete the advertising ID in Android settings (Settings > Google > Ads).
- Firebase Analytics data is processed by Google. Refer to [Google's Privacy Policy](https://policies.google.com/privacy) for details.

### 3. Data We Do NOT Collect

- Name, email, phone number, or any personal identity
- Passwords or authentication credentials
- Payment or financial information
- Your GPS position or journey path (these never leave your device)
- Device identifiers beyond those Firebase Analytics collects automatically, as described above

### 4. Data Storage

- Journey records (including GPS tracks), the journey in progress, bookmarks, the auto-play setting and the map tile cache are stored **locally on your device only**, in the app's private storage. Uninstalling the app deletes them; you can also delete journey records inside the app.
- While a journey is active the app keeps the screen on; this does not collect any data.
- Journey exports (PDF/PNG) are created only when you choose to share them through the Android share sheet, and go only where you send them.
- The app does not upload your journey data to any server of ours. The only data that leaves the device is the analytics described above and the map tile requests.

### 5. Third-Party Services

| Service | Purpose | Privacy Policy |
|---|---|---|
| Firebase Analytics (Google) | Anonymous usage analytics | [Google Privacy Policy](https://policies.google.com/privacy) |
| OpenStreetMap | Map tiles (downloaded when online) | [OSM Privacy Policy](https://wiki.osmfoundation.org/wiki/Privacy_Policy) |

### 6. Children's Privacy

This app does not knowingly collect data from children under 13. It is designed as a religious guidance tool for general use.

### 7. Changes to This Policy

Any updates to this policy will be reflected by an updated effective date in this document.

### 8. Contact

For questions regarding this privacy policy:  
**Email:** umrah@faeq.net

---

## Bahasa Malaysia

### 1. Gambaran Keseluruhan

Panduan Umrah ialah aplikasi Android berasaskan Flutter yang menyediakan panduan langkah demi langkah untuk menunaikan Umrah, termasuk doa, audio bacaan, penjejakan perjalanan GPS, dan peta Masjidil Haram. Dasar ini menerangkan data yang dikumpul dan cara penggunaannya.

### 2. Data Yang Kami Kumpul

#### a) Data Lokasi (GPS)
- Aplikasi ini memerlukan kebenaran `ACCESS_FINE_LOCATION` dan `ACCESS_COARSE_LOCATION`.
- Data GPS digunakan **dalam aplikasi sahaja, dan hanya semasa aplikasi dibuka** (tiada penjejakan lokasi di latar belakang), untuk mengesan zon anda di dalam Masjidil Haram dan merekod laluan perjalanan Umrah anda. Anda boleh menolak kebenaran ini dan masih menggunakan panduan.
- Data lokasi **disimpan secara setempat di peranti anda** (rekod perjalanan dalam storan peribadi aplikasi) dan **tidak dihantar ke mana-mana pelayan** oleh aplikasi ini.

#### b) Jubin Peta (OpenStreetMap)
- Skrin peta memuat turun jubin peta daripada `tile.openstreetmap.org`. Seperti permintaan web biasa, alamat IP anda dan koordinat jubin yang diminta didedahkan kepada OpenStreetMap. Kedudukan GPS anda **tidak** dihantar; hanya kawasan peta yang dilihat diminta. Jubin yang dimuat turun disimpan dalam cache di peranti anda supaya boleh dipaparkan semula tanpa internet. Oleh itu aplikasi menggunakan kebenaran `INTERNET` dan `ACCESS_NETWORK_STATE`.

#### c) Analitik Tanpa Nama
- Aplikasi ini menggunakan **Firebase Analytics** untuk mengumpul data penggunaan tanpa nama dan agregat.
- Peristiwa yang direkod: apabila perjalanan atau sesi Tawaf Wida' bermula atau tamat (jenis perjalanan dan bilangan *checkpoint* selesai), apabila *checkpoint* selesai (nombor dan nama *checkpoint*), dan langkah panduan yang dibuka.
- Firebase juga mengumpul sebahagian data secara automatik: pengecam instans aplikasi, ID iklan Android, model peranti, versi Android, versi aplikasi, bahasa, dan kawasan anggaran berdasarkan alamat IP. Data ini hanya digunakan untuk analitik, bukan untuk pengiklanan, dan tidak dikongsi dengan pihak lain.
- **Tiada koordinat GPS, laluan perjalanan, penanda buku atau fail eksport dihantar** melalui analitik, dan aplikasi tidak meminta nama atau e-mel anda.
- Anda boleh menetap semula atau memadam ID iklan dalam tetapan Android (Tetapan > Google > Iklan).
- Data Firebase Analytics diproses oleh Google. Rujuk [Dasar Privasi Google](https://policies.google.com/privacy) untuk maklumat lanjut.

### 3. Data Yang TIDAK Kami Kumpul

- Nama, e-mel, nombor telefon, atau sebarang maklumat peribadi
- Kata laluan atau kelayakan pengesahan
- Maklumat pembayaran atau kewangan
- Kedudukan GPS atau laluan perjalanan anda (ini tidak pernah meninggalkan peranti anda)
- Pengecam peranti selain daripada yang dikumpul secara automatik oleh Firebase Analytics seperti diterangkan di atas

### 4. Penyimpanan Data

- Rekod perjalanan (termasuk trek GPS), perjalanan yang sedang berjalan, penanda buku, tetapan main automatik dan cache jubin peta disimpan **secara setempat di peranti anda sahaja**, dalam storan peribadi aplikasi. Menyahpasang aplikasi memadamnya; anda juga boleh memadam rekod perjalanan dalam aplikasi.
- Semasa perjalanan aktif, aplikasi mengekalkan skrin hidup; ini tidak mengumpul sebarang data.
- Eksport perjalanan (PDF/PNG) hanya dibuat apabila anda memilih untuk berkongsi melalui menu kongsi Android, dan hanya ke destinasi pilihan anda.
- Aplikasi ini tidak memuat naik data perjalanan anda ke mana-mana pelayan kami. Satu-satunya data yang keluar dari peranti ialah analitik seperti di atas dan permintaan jubin peta.

### 5. Perkhidmatan Pihak Ketiga

| Perkhidmatan | Tujuan | Dasar Privasi |
|---|---|---|
| Firebase Analytics (Google) | Analitik penggunaan tanpa nama | [Dasar Privasi Google](https://policies.google.com/privacy) |
| OpenStreetMap | Jubin peta (dimuat turun semasa dalam talian) | [Dasar Privasi OSM](https://wiki.osmfoundation.org/wiki/Privacy_Policy) |

### 6. Privasi Kanak-Kanak

Aplikasi ini tidak mengumpul data daripada kanak-kanak bawah umur 13 tahun secara sedar. Ia direka sebagai alat panduan agama untuk kegunaan umum.

### 7. Perubahan Pada Dasar Ini

Sebarang kemaskini pada dasar ini akan dicerminkan oleh tarikh berkuat kuasa yang dikemaskini dalam dokumen ini.

### 8. Hubungi Kami

Untuk pertanyaan berkaitan dasar privasi ini:  
**E-mel:** umrah@faeq.net
