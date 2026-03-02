// ════════════════════════════════════════════════════════════════════════════
// CONTENT EDITING GUIDE — umrah_data.dart
// ════════════════════════════════════════════════════════════════════════════
//
// DATA HIERARCHY (3 levels):
//
//   UmrahStep          — one of the 9 main Umrah steps/categories
//     └── UmrahSubStep — a named sub-section within a step (e.g. Pusingan 1)
//           └── DoaItem  — one individual doa/prayer card shown to the user
//
// ─── UmrahStep fields ────────────────────────────────────────────────────────
//   id:       unique string key (used for bookmarks, progress, GPS tracking)
//   title:    shown in the grid card and AppBar (Malay)
//   subtitle: one-line description shown below the title card
//   icon:     asset path for the step icon image (assets/images/...)
//   textFile: optional text guide file in assets/text/ (HTML-formatted Malay)
//   subSteps: list of UmrahSubStep — at least one required
//
// ─── UmrahSubStep fields ─────────────────────────────────────────────────────
//   id:    unique key within the step — must be snake_case
//         Tawaf rounds MUST use format:       tawaf_1      … tawaf_7
//         Tawaf Wida' rounds MUST use format: tawaf_wida_1 … tawaf_wida_7
//         Sa'ie rounds MUST use format:       saie_1       … saie_7
//         (The app uses these ids to drive the round-completion tracking UI)
//   title: shown in the SubStep screen list and GuideFlow header
//   duas:  list of DoaItem — can be empty [] but try to include at least one
//
// ─── DoaItem fields ──────────────────────────────────────────────────────────
//   title:       doa name shown as heading and in search results
//   imagePath:   path to the doa image PNG (null → shows a placeholder icon)
//                Convention: 'assets/images/doa/<name>.png'
//   audioPath:   path to the audio file (null → "Tiada audio" shown)
//                Convention: 'assets/audio/<name>.ogg'  (some .mp3 also exist)
//   description: optional short description/transliteration shown below image
//   textFile:    optional filename in assets/text/ (HTML-formatted Malay text)
//                Rendered below the image in the doa viewer
//   autoPlay:    (default true) if false, audio auto-chain stops at this doa;
//               the user must tap Play manually — use as a deliberate pause/
//               break-point between thematic groups of duas
//
// ─── HOW TO EDIT CONTENT ─────────────────────────────────────────────────────
//
//  ADD a new doa:  insert a new DoaItem(…) into any duas: [] list
//  REMOVE a doa:   delete the DoaItem(…) line (and its trailing comma)
//  REORDER duas:   cut and paste DoaItem entries within the same list
//  EDIT a doa:     change its title/imagePath/audioPath/description fields
//
//  ADD a new substep:
//    Insert a new UmrahSubStep(id: '…', title: '…', duas: […]) into the
//    subSteps: [] list of the relevant UmrahStep.
//
//  ADD a new step:
//    Append a new UmrahStep(…) to the umrahSteps list below, then also add
//    an entry in the _stepColors and _stepIcons arrays in home_screen.dart.
//
// ─── ASSET PATH CONVENTIONS ──────────────────────────────────────────────────
//   Doa images:       assets/images/doa/<name>.png
//   Step icons:       assets/images/misc/<name>.png  OR  locations/<name>.jpg
//   Overview images:  assets/images/overview/<name>.png
//   Location photos:  assets/images/locations/<name>.jpg
//   Audio files:      assets/audio/<name>.ogg  (preferred) or .mp3
//   Text guides:      assets/text/<name>.txt   (HTML-formatted Malay)
//
//   Any new file must also be in pubspec.yaml under flutter.assets!
//   New folders need a new entry; existing folder entries cover all files.
//
// ════════════════════════════════════════════════════════════════════════════

import '../models/umrah_step.dart';

final List<UmrahStep> umrahSteps = [
  // ════════ STEP 1: IHRAM ════════
  const UmrahStep(
    id: 'ihram',
    title: 'Ihram',
    subtitle: 'Persediaan & Niat',
    icon: 'assets/images/misc/ihram_land.png',
    textFile: 'adab_ihram.txt',
    subSteps: [
      UmrahSubStep(id: 'rukun_umrah',title: 'Rukun Umrah',duas: [
        DoaItem(title: 'Rukun Umrah',textFile: 'rukun_umrah.txt',autoPlay: false,),
        DoaItem(title: 'Panduan Ihram',imagePath: 'assets/images/misc/ihram_land.png',textFile: 'adab_ihram.txt',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'mandi_ihram',title: 'Mandi Sunat Ihram',duas: [
        DoaItem(title: 'Niat Mandi Ihram',imagePath: 'assets/images/doa/niat_mandi_ihram.png',audioPath: 'assets/audio/niat_mandi_ihram.ogg',textFile: 'niat_ihram_solat_sunat_ihram.txt',),
      ]),
      UmrahSubStep(id: 'solat_ihram',title: 'Solat Sunat Ihram',duas: [
        DoaItem(title: 'Niat Solat Sunat Ihram',imagePath: 'assets/images/doa/niat_solat_ihram.png',audioPath: 'assets/audio/niat_solat_ihram.ogg',),
      ]),
      UmrahSubStep(id: 'niat_umrah',title: 'Lafaz Niat Umrah',duas: [
        DoaItem(title: 'Lafaz Niat Umrah',imagePath: 'assets/images/doa/niat_umrah.png',audioPath: 'assets/audio/lafaz_niat_umrah.ogg',),
      ]),
      UmrahSubStep(id: 'talbiah',title: 'Talbiah',duas: [
        DoaItem(title: 'Bacaan Talbiah',imagePath: 'assets/images/doa/talbiah.png',audioPath: 'assets/audio/talbiah.ogg',isCheckpoint: true,),
      ]),
    ],
  ),


  // ════════ STEP 2: TAWAF (7 Pusingan + Hijir Ismail) ════════
  const UmrahStep(
    id: 'tawaf',
    title: 'Tawaf',
    subtitle: '7 Pusingan mengelilingi Ka\'abah',
    icon: 'assets/images/misc/icp_kaabah.jpg',
    textFile: 'tawaf_perlaksanaan.txt',
    subSteps: [
      UmrahSubStep(id: 'permulaan_tawaf',title: 'Permulaan Tawaf',duas: [
        DoaItem(title: 'Panduan Perlaksanaan Tawaf',imagePath: 'assets/images/misc/icp_kaabah.jpg',textFile: 'tawaf_perlaksanaan.txt',autoPlay: false,),
        DoaItem(title: 'Panduan Tawaf - FAQ',imagePath: 'assets/images/misc/icp_kaabah.jpg',textFile: 'tawaf_faq.txt',autoPlay: false,),
        DoaItem(title: 'Panduan Tawaf - Permasalahan',imagePath: 'assets/images/misc/icp_kaabah.jpg',textFile: 'tawaf_permasalahan.txt',autoPlay: false,),
        DoaItem(title: 'Panduan Tawaf - tips',imagePath: 'assets/images/misc/icp_kaabah.jpg',textFile: 'tawaf_tips.txt',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'niat_tawaf',title: 'Niat Tawaf',duas: [
        DoaItem(title: 'Niat Tawaf Umrah', imagePath: 'assets/images/doa/niat_tawaf_umrah.png', audioPath: 'assets/audio/niat_tawaf_umrah.ogg',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'tawaf_1',title: 'Pusingan 1 - Pertama',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Pertama 1', imagePath: 'assets/images/doa/doa_tawaf_pertama_1.png', audioPath: 'assets/audio/doa_tawaf_pertama_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Pertama 2', imagePath: 'assets/images/doa/doa_tawaf_pertama_2.png', audioPath: 'assets/audio/doa_tawaf_pertama_2.ogg'),
        DoaItem(title: 'Doa Tawaf Pertama 3', imagePath: 'assets/images/doa/doa_tawaf_pertama_3.png', audioPath: 'assets/audio/doa_tawaf_pertama_3.ogg'),
        DoaItem(title: 'Doa Tawaf Pertama 4', imagePath: 'assets/images/doa/doa_tawaf_pertama_4.png', audioPath: 'assets/audio/doa_tawaf_pertama_4.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_2',title: 'Pusingan 2 - Kedua',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Kedua 1', imagePath: 'assets/images/doa/doa_tawaf_kedua_1.png', audioPath: 'assets/audio/doa_tawaf_kedua_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Kedua 2', imagePath: 'assets/images/doa/doa_tawaf_kedua_2.png', audioPath: 'assets/audio/doa_tawaf_kedua_2.ogg'),
        DoaItem(title: 'Doa Tawaf Kedua 3', imagePath: 'assets/images/doa/doa_tawaf_kedua_3.png', audioPath: 'assets/audio/doa_tawaf_kedua_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_3',title: 'Pusingan 3 - Ketiga',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Ketiga 1', imagePath: 'assets/images/doa/doa_tawaf_ketiga_1.png', audioPath: 'assets/audio/doa_tawaf_ketiga_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Ketiga 2', imagePath: 'assets/images/doa/doa_tawaf_ketiga_2.png', audioPath: 'assets/audio/doa_tawaf_ketiga_2.ogg'),
        DoaItem(title: 'Doa Tawaf Ketiga 3', imagePath: 'assets/images/doa/doa_tawaf_ketiga_3.png', audioPath: 'assets/audio/doa_tawaf_ketiga_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_4',title: 'Pusingan 4 - Keempat',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Keempat 1', imagePath: 'assets/images/doa/doa_tawaf_keempat_1.png', audioPath: 'assets/audio/doa_tawaf_keempat_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Keempat 2', imagePath: 'assets/images/doa/doa_tawaf_keempat_2.png', audioPath: 'assets/audio/doa_tawaf_keempat_2.ogg'),
        DoaItem(title: 'Doa Tawaf Keempat 3', imagePath: 'assets/images/doa/doa_tawaf_keempat_3.png', audioPath: 'assets/audio/doa_tawaf_keempat_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_5',title: 'Pusingan 5 - Kelima',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Kelima 1', imagePath: 'assets/images/doa/doa_tawaf_kelima_1.png', audioPath: 'assets/audio/doa_tawaf_kelima_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Kelima 2', imagePath: 'assets/images/doa/doa_tawaf_kelima_2.png', audioPath: 'assets/audio/doa_tawaf_kelima_2.ogg'),
        DoaItem(title: 'Doa Tawaf Kelima 3', imagePath: 'assets/images/doa/doa_tawaf_kelima_3.png', audioPath: 'assets/audio/doa_tawaf_kelima_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_6',title: 'Pusingan 6 - Keenam',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Keenam 1', imagePath: 'assets/images/doa/doa_tawaf_keenam_1.png', audioPath: 'assets/audio/doa_tawaf_keenam_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Keenam 2', imagePath: 'assets/images/doa/doa_tawaf_keenam_2.png', audioPath: 'assets/audio/doa_tawaf_keenam_2.ogg'),
        DoaItem(title: 'Doa Tawaf Keenam 3', imagePath: 'assets/images/doa/doa_tawaf_keenam_3.png', audioPath: 'assets/audio/doa_tawaf_keenam_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tawaf_7',title: 'Pusingan 7 - Ketujuh',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Ketujuh 1', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_1.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Tawaf Ketujuh 2', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_2.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_2.ogg'),
        DoaItem(title: 'Doa Tawaf Ketujuh 3', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_3.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_3.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
    ],
  ),

  // ════════ STEP 3: SOLAT SUNAT TAWAF ════════
  const UmrahStep(
    id: 'solat_tawaf',
    title: 'Solat Sunat Tawaf',
    subtitle: 'Di Makam Ibrahim',
    icon: 'assets/images/locations/tempat_4_a.jpg',
    subSteps: [
      UmrahSubStep(id: 'niat_solat_tawaf',title: 'Niat Solat Sunat Tawaf',duas: [
        DoaItem(title: 'Niat Solat Sunat Tawaf', imagePath: 'assets/images/doa/niat_solat_sunat_tawaf.png', audioPath: 'assets/audio/niat_solat_sunat_tawaf.ogg',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'doa_makam_ibrahim',title: 'Doa di Makam Ibrahim',duas: [
        DoaItem(title: 'Doa Makam Ibrahim 1', imagePath: 'assets/images/doa/doa_makam_ibrahim_1.png', audioPath: 'assets/audio/doa_makam_ibrahim_1.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 2', imagePath: 'assets/images/doa/doa_makam_ibrahim_2.png', audioPath: 'assets/audio/doa_makam_ibrahim_2.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 3', imagePath: 'assets/images/doa/doa_makam_ibrahim_3.png', audioPath: 'assets/audio/doa_makam_ibrahim_3.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 4', imagePath: 'assets/images/doa/doa_makam_ibrahim_4.png', audioPath: 'assets/audio/doa_makam_ibrahim_4.ogg',),
      ]),
      UmrahSubStep(id: 'air_zamzam', title: 'Minum Air Zam Zam',duas: [
        DoaItem(title: 'Doa Minum Air Zam Zam', imagePath: 'assets/images/doa/doa_semasa_minum_air_zam2.png', audioPath: 'assets/audio/doa_minum_air_zam2.ogg',autoPlay: false,isCheckpoint: true,),
      ]),
    ],
  ),

  // ════════ STEP 4: SA'IE (7 kali Safa–Marwah) ════════
  const UmrahStep(
    id: 'saie',
    title: 'Sa\'ie',
    subtitle: '7 kali Safa ke Marwah',
    icon: 'assets/images/misc/icp_saie.jpg',
    textFile: 'saie.txt',
    subSteps: [
      UmrahSubStep(id: 'permulaan_saie',title: 'Permulaan Sa\'ie',duas: [
        DoaItem(title: 'Panduan Sa\'ie',imagePath: 'assets/images/misc/icp_saie.jpg',textFile: 'saie.txt',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'niat_saie',title: 'Niat Sa\'ie',duas: [
        DoaItem(title: 'Niat Sa\'ie Umrah', imagePath: 'assets/images/doa/niat_saie_umrah.png', audioPath: 'assets/audio/niat_saie_umrah.ogg',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'doa_bab_safa',title: 'Doa di Pintu Bab al-Safa',duas: [
        DoaItem(title: 'Doa Bab al-Safa', imagePath: 'assets/images/doa/doa_bab_al_safa.png', audioPath: 'assets/audio/doa_bab_al_safa.ogg',autoPlay: false,),
      ]),
      UmrahSubStep(id: 'saie_1',title: 'Saie 1 - Safa ke Marwah',duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Pertama 1', imagePath: 'assets/images/doa/doa_saie_pertama_1.png', audioPath: 'assets/audio/doa_saie_pertama_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Pertama 2', imagePath: 'assets/images/doa/doa_saie_pertama_2.png', audioPath: 'assets/audio/doa_saie_pertama_2.ogg'),
        DoaItem(title: 'Doa Saie Pertama 3', imagePath: 'assets/images/doa/doa_saie_pertama_3.png', audioPath: 'assets/audio/doa_saie_pertama_3.ogg'),
        DoaItem(title: 'Doa Saie Pertama 4', imagePath: 'assets/images/doa/doa_saie_pertama_4.png', audioPath: 'assets/audio/doa_saie_pertama_4.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau 1', imagePath: 'assets/images/doa/doa_selepas_tiang_hijau_pertama_1.png', audioPath: 'assets/audio/doa_selepas_tiang_hijau_pertama_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Selepas Tiang Hijau 2', imagePath: 'assets/images/doa/doa_selepas_tiang_hijau_pertama_2.png', audioPath: 'assets/audio/doa_selepas_tiang_hijau_pertama_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau 3', imagePath: 'assets/images/doa/doa_selepas_tiang_hijau_pertama_3.png', audioPath: 'assets/audio/doa_selepas_tiang_hijau_pertama_3.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau 4', imagePath: 'assets/images/doa/doa_selepas_tiang_hijau_pertama_4.png', audioPath: 'assets/audio/doa_selepas_tiang_hijau_pertama_4.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 1', imagePath: 'assets/images/doa/doa_bukit_marwah_1.png', audioPath: 'assets/audio/doa_bukit_marwah_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 2', imagePath: 'assets/images/doa/doa_bukit_marwah_2.png', audioPath: 'assets/audio/doa_bukit_marwah_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 3', imagePath: 'assets/images/doa/doa_bukit_marwah_3.png', audioPath: 'assets/audio/doa_bukit_marwah_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_2', title: 'Saie 2 - Marwah ke Safa', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Kedua 1', imagePath: 'assets/images/doa/doa_saie_kedua_1.png', audioPath: 'assets/audio/doa_saie_kedua_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Kedua 2', imagePath: 'assets/images/doa/doa_saie_kedua_2.png', audioPath: 'assets/audio/doa_saie_kedua_2.ogg'),
        DoaItem(title: 'Doa Saie Kedua 3', imagePath: 'assets/images/doa/doa_saie_kedua_3.png', audioPath: 'assets/audio/doa_saie_kedua_3.ogg'),
        DoaItem(title: 'Doa Saie Kedua 4', imagePath: 'assets/images/doa/doa_saie_kedua_4.png', audioPath: 'assets/audio/doa_saie_kedua_4.ogg'),
        DoaItem(title: 'Doa Saie Kedua 5', imagePath: 'assets/images/doa/doa_saie_kedua_5.png', audioPath: 'assets/audio/doa_saie_kedua_5.ogg'),
        DoaItem(title: 'Doa Saie Kedua 6', imagePath: 'assets/images/doa/doa_saie_kedua_6.png', audioPath: 'assets/audio/doa_saie_kedua_6.ogg'),
        DoaItem(title: 'Doa Saie Kedua 7', imagePath: 'assets/images/doa/doa_saie_kedua_7.png', audioPath: 'assets/audio/doa_saie_kedua_7.ogg'),
        DoaItem(title: 'Doa Saie Kedua 8', imagePath: 'assets/images/doa/doa_saie_kedua_8.png', audioPath: 'assets/audio/doa_saie_kedua_8.ogg'),
        DoaItem(title: 'Doa Saie Kedua 9', imagePath: 'assets/images/doa/doa_saie_kedua_9.png', audioPath: 'assets/audio/doa_saie_kedua_9.ogg'),
        DoaItem(title: 'Doa Saie Kedua 10', imagePath: 'assets/images/doa/doa_saie_kedua_10.png', audioPath: 'assets/audio/doa_saie_kedua_10.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 1', imagePath: 'assets/images/doa/doa_bukit_safa_1.png', audioPath: 'assets/audio/doa_bukit_safa_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 2', imagePath: 'assets/images/doa/doa_bukit_safa_2.png', audioPath: 'assets/audio/doa_bukit_safa_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 3', imagePath: 'assets/images/doa/doa_bukit_safa_3.png', audioPath: 'assets/audio/doa_bukit_safa_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_3', title: 'Saie 3 - Safa ke Marwah', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Ketiga 1', imagePath: 'assets/images/doa/doa_saie_ketiga_1.png', audioPath: 'assets/audio/doa_saie_ketiga_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Ketiga 2', imagePath: 'assets/images/doa/doa_saie_ketiga_2.png', audioPath: 'assets/audio/doa_saie_ketiga_2.ogg'),
        DoaItem(title: 'Doa Saie Ketiga 3', imagePath: 'assets/images/doa/doa_saie_ketiga_3.png', audioPath: 'assets/audio/doa_saie_ketiga_3.ogg'),
        DoaItem(title: 'Doa Saie Ketiga 4', imagePath: 'assets/images/doa/doa_saie_ketiga_4.png', audioPath: 'assets/audio/doa_saie_ketiga_4.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 1', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_1.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 2', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_2.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 3', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_3.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_3.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 4', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_4.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_4.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 5', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_5.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_5.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 6', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_6.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_6.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketiga 7', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketiga_7.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketiga_7.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 1', imagePath: 'assets/images/doa/doa_bukit_marwah_1.png', audioPath: 'assets/audio/doa_bukit_marwah_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 2', imagePath: 'assets/images/doa/doa_bukit_marwah_2.png', audioPath: 'assets/audio/doa_bukit_marwah_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 3', imagePath: 'assets/images/doa/doa_bukit_marwah_3.png', audioPath: 'assets/audio/doa_bukit_marwah_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_4', title: 'Saie 4 - Marwah ke Safa', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Keempat 1', imagePath: 'assets/images/doa/doa_saie_keempat_1.png', audioPath: 'assets/audio/doa_saie_keempat_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Keempat 2', imagePath: 'assets/images/doa/doa_saie_keempat_2.png', audioPath: 'assets/audio/doa_saie_keempat_2.ogg'),
        DoaItem(title: 'Doa Saie Keempat 3', imagePath: 'assets/images/doa/doa_saie_keempat_3.png', audioPath: 'assets/audio/doa_saie_keempat_3.ogg'),
        DoaItem(title: 'Doa Saie Keempat 4', imagePath: 'assets/images/doa/doa_saie_keempat_4.png', audioPath: 'assets/audio/doa_saie_keempat_4.ogg'),
        DoaItem(title: 'Doa Saie Keempat 5', imagePath: 'assets/images/doa/doa_saie_keempat_5.png', audioPath: 'assets/audio/doa_saie_keempat_5.ogg'),
        DoaItem(title: 'Doa Saie Keempat 6', imagePath: 'assets/images/doa/doa_saie_keempat_6.png', audioPath: 'assets/audio/doa_saie_keempat_6.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 1', imagePath: 'assets/images/doa/doa_bukit_safa_1.png', audioPath: 'assets/audio/doa_bukit_safa_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 2', imagePath: 'assets/images/doa/doa_bukit_safa_2.png', audioPath: 'assets/audio/doa_bukit_safa_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 3', imagePath: 'assets/images/doa/doa_bukit_safa_3.png', audioPath: 'assets/audio/doa_bukit_safa_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_5', title: 'Saie 5 - Safa ke Marwah', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Kelima 1', imagePath: 'assets/images/doa/doa_saie_kelima_1.png', audioPath: 'assets/audio/doa_saie_kelima_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Kelima 2', imagePath: 'assets/images/doa/doa_saie_kelima_2.png', audioPath: 'assets/audio/doa_saie_kelima_2.ogg'),
        DoaItem(title: 'Doa Saie Kelima 3', imagePath: 'assets/images/doa/doa_saie_kelima_3.png', audioPath: 'assets/audio/doa_saie_kelima_3.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Kelima 1', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_kelima_1.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_kelima_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Selepas Tiang Hijau Kelima 2', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_kelima_2.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_kelima_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Kelima 3', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_kelima_3.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_kelima_3.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Kelima 4', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_kelima_4.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_kelima_4.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 1', imagePath: 'assets/images/doa/doa_bukit_marwah_1.png', audioPath: 'assets/audio/doa_bukit_marwah_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 2', imagePath: 'assets/images/doa/doa_bukit_marwah_2.png', audioPath: 'assets/audio/doa_bukit_marwah_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 3', imagePath: 'assets/images/doa/doa_bukit_marwah_3.png', audioPath: 'assets/audio/doa_bukit_marwah_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_6', title: 'Saie 6 - Marwah ke Safa', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Keenam 1', imagePath: 'assets/images/doa/doa_saie_keenam_1.png', audioPath: 'assets/audio/doa_saie_keenam_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Keenam 2', imagePath: 'assets/images/doa/doa_saie_keenam_2.png', audioPath: 'assets/audio/doa_saie_keenam_2.ogg'),
        DoaItem(title: 'Doa Saie Keenam 3', imagePath: 'assets/images/doa/doa_saie_keenam_3.png', audioPath: 'assets/audio/doa_saie_keenam_3.ogg'),
        DoaItem(title: 'Doa Saie Keenam 4', imagePath: 'assets/images/doa/doa_saie_keenam_4.png', audioPath: 'assets/audio/doa_saie_keenam_4.ogg'),
        DoaItem(title: 'Doa Saie Keenam 5', imagePath: 'assets/images/doa/doa_saie_keenam_5.png', audioPath: 'assets/audio/doa_saie_keenam_5.ogg'),
        DoaItem(title: 'Doa Saie Keenam 6', imagePath: 'assets/images/doa/doa_saie_keenam_6.png', audioPath: 'assets/audio/doa_saie_keenam_6.ogg'),
        DoaItem(title: 'Doa Saie Keenam 7', imagePath: 'assets/images/doa/doa_saie_keenam_7.png', audioPath: 'assets/audio/doa_saie_keenam_7.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 1', imagePath: 'assets/images/doa/doa_bukit_safa_1.png', audioPath: 'assets/audio/doa_bukit_safa_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 2', imagePath: 'assets/images/doa/doa_bukit_safa_2.png', audioPath: 'assets/audio/doa_bukit_safa_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Safa 3', imagePath: 'assets/images/doa/doa_bukit_safa_3.png', audioPath: 'assets/audio/doa_bukit_safa_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'saie_7', title: 'Saie 7 - Safa ke Marwah (Akhir)', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Ketujuh 1', imagePath: 'assets/images/doa/doa_saie_ketujuh_1.png', audioPath: 'assets/audio/doa_saie_ketujuh_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Saie Ketujuh 2', imagePath: 'assets/images/doa/doa_saie_ketujuh_2.png', audioPath: 'assets/audio/doa_saie_ketujuh_2.ogg'),
        DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 1', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_1.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 2', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_2.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_2.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 3', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_3.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_3.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 4', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_4.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_4.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 5', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_5.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_5.ogg'),
        DoaItem(title: 'Doa Selepas Tiang Hijau Ketujuh 6', imagePath: 'assets/images/doa/doa_selepas_tiang2_hijau_ketujuh_6.png', audioPath: 'assets/audio/doa_selepas_tiang2_hijau_ketujuh_6.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 1', imagePath: 'assets/images/doa/doa_bukit_marwah_1.png', audioPath: 'assets/audio/doa_bukit_marwah_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 2', imagePath: 'assets/images/doa/doa_bukit_marwah_2.png', audioPath: 'assets/audio/doa_bukit_marwah_2.ogg'),
        DoaItem(title: 'Doa Ketika Mendaki Bukit Marwah 3', imagePath: 'assets/images/doa/doa_bukit_marwah_3.png', audioPath: 'assets/audio/doa_bukit_marwah_3.ogg',isCheckpoint: true,),
      ]),
      UmrahSubStep(id: 'tamat_saie',title: 'Tamat Sa\'ie',duas: [
        DoaItem(title: 'Doa Selesai Sa\'ie 1', imagePath: 'assets/images/doa/doa_selesai_saie_1.png', audioPath: 'assets/audio/doa_selesai_saie_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Selesai Sa\'ie 2', imagePath: 'assets/images/doa/doa_selesai_saie_2.png', audioPath: 'assets/audio/doa_selesai_saie_2.ogg'),
      ]),
    ],
  ),

  // ════════ STEP 5: TAHALLUL ════════
  const UmrahStep(
  id: 'tahallul',
    title: 'Tahallul',
    subtitle: 'Bercukur atau Bergunting',
    icon: 'assets/images/misc/ihram.png',
    textFile: 'tahallul.txt',
    subSteps: [
      UmrahSubStep(id: 'doa_bercukur',title: 'Doa Bercukur / Bergunting',duas: [
        DoaItem(title: 'Doa Bercukur 1', imagePath: 'assets/images/doa/doa_bercukur_1.png', audioPath: 'assets/audio/doa_bercukur_1.ogg',autoPlay: false,),
        DoaItem(title: 'Doa Bercukur 2', imagePath: 'assets/images/doa/doa_bercukur_2.png', audioPath: 'assets/audio/doa_bercukur_2.ogg'),
        DoaItem(title: 'Doa Bercukur 3', imagePath: 'assets/images/doa/doa_bercukur_3.png', audioPath: 'assets/audio/doa_bercukur_3.ogg'),
        DoaItem(title: 'Doa Bercukur 4', imagePath: 'assets/images/doa/doa_bercukur_4.png', audioPath: 'assets/audio/doa_bercukur_4.ogg',isCheckpoint: true,),
      ]),
    ],
  ),

  // ════════ STEP 6: TAWAF WIDA' (Tawaf Selamat Tinggal) ════════
  const UmrahStep(
    id: 'tawaf_wida',
    title: 'Tawaf Wida\'',
    subtitle: 'Tawaf Selamat Tinggal',
    icon: 'assets/images/misc/ihram_land.png',
    subSteps: [
      UmrahSubStep(id: 'niat_tawaf_wida',title: 'Niat Tawaf Wida\'',duas: [
        DoaItem(title: 'Niat Tawaf Wida\'', imagePath: 'assets/images/doa/niat_tawaf_wada.png', audioPath: 'assets/audio/niat_tawaf_wida.ogg', autoPlay: false),
      ]),
      // Pusingan 1: doa_ketika_tawaf_wada 1–4
      UmrahSubStep(id: 'tawaf_wida_1', title: 'Pusingan 1 - Pertama', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 1', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_1.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 2', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_2.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_2.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 3', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_3.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_3.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 4', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_4.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_4.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 2: doa_ketika_tawaf_wada 5–8
      UmrahSubStep(id: 'tawaf_wida_2', title: 'Pusingan 2 - Kedua', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 5', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_5.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_5.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 6', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_6.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_6.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 7', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_7.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_7.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 8', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_8.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_8.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 3: doa_ketika_tawaf_wada 9–12
      UmrahSubStep(id: 'tawaf_wida_3', title: 'Pusingan 3 - Ketiga', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 9', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_9.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_9.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 10', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_10.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_10.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 11', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_11.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_11.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 12', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_12.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_12.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 4: doa_ketika_tawaf_wada 13–16
      UmrahSubStep(id: 'tawaf_wida_4', title: 'Pusingan 4 - Keempat', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 13', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_13.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_13.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 14', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_14.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_14.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 15', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_15.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_15.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 16', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_16.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_16.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 5: doa_ketika_tawaf_wada 17–20
      UmrahSubStep(id: 'tawaf_wida_5', title: 'Pusingan 5 - Kelima', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 17', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_17.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_17.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 18', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_18.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_18.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 19', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_19.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_19.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 20', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_20.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_20.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 6: doa_ketika_tawaf_wada 21–24
      UmrahSubStep(id: 'tawaf_wida_6', title: 'Pusingan 6 - Keenam', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 21', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_21.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_21.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 22', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_22.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_22.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 23', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_23.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_23.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 24', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_24.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_24.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Pusingan 7: doa_ketika_tawaf_wada 25–27
      UmrahSubStep(id: 'tawaf_wida_7', title: 'Pusingan 7 - Ketujuh', duas: [
        DoaItem(title: 'Zikir Melambai Ka\'abah', imagePath: 'assets/images/doa/zikir_melambai_kaabah.png', audioPath: 'assets/audio/zikir_melambai_kaabah.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 25', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_25.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_25.ogg', autoPlay: false),
        DoaItem(title: 'Doa Tawaf Wida\' 26', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_26.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_26.ogg'),
        DoaItem(title: 'Doa Tawaf Wida\' 27', imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_27.png', audioPath: 'assets/audio/doa_ketika_tawaf_wada_27.ogg'),
        DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg', autoPlay: false),
      ]),
      // Tamat Tawaf Wida' — Solat Sunat Tawaf
      UmrahSubStep(id: 'niat_solat_tawaf_wida',title: 'Solat Sunat Tawaf',duas: [
        DoaItem(title: 'Niat Solat Sunat Tawaf', imagePath: 'assets/images/doa/niat_solat_sunat_tawaf.png', audioPath: 'assets/audio/niat_solat_sunat_tawaf.ogg', autoPlay: false),
      ]),
      UmrahSubStep(id: 'doa_makam_ibrahim_wida',title: 'Doa di Makam Ibrahim',duas: [
        DoaItem(title: 'Doa Makam Ibrahim 1', imagePath: 'assets/images/doa/doa_makam_ibrahim_1.png', audioPath: 'assets/audio/doa_makam_ibrahim_1.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 2', imagePath: 'assets/images/doa/doa_makam_ibrahim_2.png', audioPath: 'assets/audio/doa_makam_ibrahim_2.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 3', imagePath: 'assets/images/doa/doa_makam_ibrahim_3.png', audioPath: 'assets/audio/doa_makam_ibrahim_3.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 4', imagePath: 'assets/images/doa/doa_makam_ibrahim_4.png', audioPath: 'assets/audio/doa_makam_ibrahim_4.ogg'),
      ]),
      UmrahSubStep(id: 'air_zamzam_wida',title: 'Minum Air Zam Zam',duas: [
        DoaItem(title: 'Doa Minum Air Zam Zam', imagePath: 'assets/images/doa/doa_semasa_minum_air_zam2.png', audioPath: 'assets/audio/doa_minum_air_zam2.ogg', autoPlay: false),
      ]),
    ],
  ),

  // ════════ STEP 7: LAIN-LAIN DOA (LAIN-LAIN DOA) ════════
  const UmrahStep(
    id: 'lain_lain',
    title: 'Lain-lain Doa',
    subtitle: 'Doa lain berkaitan ibadah',
    icon: 'assets/images/misc/ihram_land.png',
    subSteps: [
      // 1. Doa Memulakan Musafir (7 items, images moved from overview/ to doa/)
      UmrahSubStep(id: 'permulaan_safar',title: 'Doa Memulakan Musafir',duas: [
        DoaItem(title: 'Doa Memulakan Musafir 1', imagePath: 'assets/images/doa/permulaan_safar_1a.png', audioPath: 'assets/audio/doa_safar_1a.ogg', autoPlay: false),
        DoaItem(title: 'Doa Memulakan Musafir 2', imagePath: 'assets/images/doa/permulaan_safar_1b.png', audioPath: 'assets/audio/doa_safar_1b.ogg'),
        DoaItem(title: 'Doa Memulakan Musafir 3', imagePath: 'assets/images/doa/permulaan_safar_1c.png', audioPath: 'assets/audio/doa_safar_1c.ogg'),
        DoaItem(title: 'Doa Memulakan Musafir 4', imagePath: 'assets/images/doa/permulaan_safar_2a.png', audioPath: 'assets/audio/doa_safar_2a.ogg'),
        DoaItem(title: 'Doa Memulakan Musafir 5', imagePath: 'assets/images/doa/permulaan_safar_2b.png', audioPath: 'assets/audio/doa_safar_2b.ogg'),
        DoaItem(title: 'Doa Memulakan Musafir 6', imagePath: 'assets/images/doa/permulaan_safar_3a.png', audioPath: 'assets/audio/doa_safar_3a.ogg'),
        DoaItem(title: 'Doa Memulakan Musafir 7', imagePath: 'assets/images/doa/permulaan_safar_3b.png', audioPath: 'assets/audio/doa_safar_3b.ogg'),
      ]),
      // 2. Doa Masuk Bab al-Salam (2 items)
      UmrahSubStep(id: 'doa_bab_salam',title: 'Doa Masuk Bab al-Salam',duas: [
        DoaItem(title: 'Doa Masuk Bab al-Salam 1', imagePath: 'assets/images/doa/doa_masuk_babussalam_1.png', audioPath: 'assets/audio/doa_masuk_babussalam_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Masuk Bab al-Salam 2', imagePath: 'assets/images/doa/doa_masuk_babussalam_2.png', audioPath: 'assets/audio/doa_masuk_babussalam_2.ogg'),
      ]),
      // 3. Doa di Pintu Bani Syaibah (2 items)
      UmrahSubStep(id: 'bani_syaibah',title: 'Doa di Pintu Bani Syaibah',duas: [
        DoaItem(title: 'Doa Bani Syaibah 1', imagePath: 'assets/images/doa/doa_bani_syaibah_1.png', audioPath: 'assets/audio/doa_bani_syaibah_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Bani Syaibah 2', imagePath: 'assets/images/doa/doa_bani_syaibah_2.png', audioPath: 'assets/audio/doa_bani_syaibah_2.ogg'),
      ]),
      // 4. Doa Semasa Minum Air Zam Zam
      UmrahSubStep(id: 'doa_semasa_zamzam',title: 'Doa Semasa Minum Air Zam Zam',duas: [
        DoaItem(title: 'Doa Semasa Minum Air Zam Zam', imagePath: 'assets/images/doa/doa_semasa_minum_air_zam2.png', audioPath: 'assets/audio/doa_minum_air_zam2.ogg', autoPlay: false),
      ]),
      // 5. Doa di Multazam (2 items; no matching audio)
      UmrahSubStep(id: 'doa_di_multazam',title: 'Doa di Multazam',duas: [
        DoaItem(title: 'Doa di Multazam 1', imagePath: 'assets/images/doa/doa_di_multazam_1.png', audioPath: 'assets/audio/doa_di_multazam_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa di Multazam 2', imagePath: 'assets/images/doa/doa_di_multazam_2.png', audioPath: 'assets/audio/doa_di_multazam_2.ogg'),
        DoaItem(title: 'Doa di Multazam 3', imagePath: 'assets/images/doa/doa_di_multazam_3.png', audioPath: 'assets/audio/doa_di_multazam_3.ogg'),
        DoaItem(title: 'Doa di Multazam 4', imagePath: 'assets/images/doa/doa_di_multazam_4.png', audioPath: 'assets/audio/doa_di_multazam_4.ogg'),
      ]),
      // 6. doa di hijir ismail)
      UmrahSubStep(id: 'hijir_ismail',title: 'Doa di Hijir Ismail',duas: [
        DoaItem(title: 'Doa Hijir Ismail 1', imagePath: 'assets/images/doa/doa_hijir_ismail_1.png', audioPath: 'assets/audio/doa_hijir_ismail_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Hijir Ismail 2', imagePath: 'assets/images/doa/doa_hijir_ismail_2.png', audioPath: 'assets/audio/doa_hijir_ismail_2.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 3', imagePath: 'assets/images/doa/doa_hijir_ismail_3.png', audioPath: 'assets/audio/doa_hijir_ismail_3.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 4', imagePath: 'assets/images/doa/doa_hijir_ismail_4.png', audioPath: 'assets/audio/doa_hijir_ismail_4.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 5', imagePath: 'assets/images/doa/doa_hijir_ismail_5.png', audioPath: 'assets/audio/doa_hijir_ismail_5.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 6', imagePath: 'assets/images/doa/doa_hijir_ismail_6.png', audioPath: 'assets/audio/doa_hijir_ismail_6.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 7', imagePath: 'assets/images/doa/doa_hijir_ismail_7.png', audioPath: 'assets/audio/doa_hijir_ismail_7.ogg'),
        DoaItem(title: 'Doa Hijir Ismail 8', imagePath: 'assets/images/doa/doa_hijir_ismail_8.png', audioPath: 'assets/audio/doa_hijir_ismail_8.ogg'),
      ]),
      // 7. doa di makam ibrahim)
      UmrahSubStep(id: 'doa_makam_ibrahim',title: 'Doa di Makam Ibrahim',duas: [
        DoaItem(title: 'Doa Makam Ibrahim 1', imagePath: 'assets/images/doa/doa_makam_ibrahim_1.png', audioPath: 'assets/audio/doa_makam_ibrahim_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Makam Ibrahim 2', imagePath: 'assets/images/doa/doa_makam_ibrahim_2.png', audioPath: 'assets/audio/doa_makam_ibrahim_2.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 3', imagePath: 'assets/images/doa/doa_makam_ibrahim_3.png', audioPath: 'assets/audio/doa_makam_ibrahim_3.ogg'),
        DoaItem(title: 'Doa Makam Ibrahim 4', imagePath: 'assets/images/doa/doa_makam_ibrahim_4.png', audioPath: 'assets/audio/doa_makam_ibrahim_4.ogg'),
      ]),
      UmrahSubStep(id: 'doa_masuk_makkah',title: 'Doa Masuk Kota Makkah',duas: [
        DoaItem(title: 'Doa Masuk Makkah 1', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_1.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_1.ogg', autoPlay: false),
        DoaItem(title: 'Doa Masuk Makkah 2', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_2.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_2.ogg'),
        DoaItem(title: 'Doa Masuk Makkah 3', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_3.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_3.ogg'),
        DoaItem(title: 'Doa Masuk Makkah 4', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_4.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_4.ogg'),
        DoaItem(title: 'Doa Masuk Makkah 5', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_5.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_5.ogg'),
      ]),
      UmrahSubStep(id: 'doa_kaabah',title: 'Doa Melihat Ka\'abah',duas: [
        DoaItem(title: 'Doa Melihat Ka\'abah 1', imagePath: 'assets/images/doa/doa_melihat_kaabah_1.png', audioPath: 'assets/audio/doa_melihat_kaabah_1.ogg'),
        DoaItem(title: 'Doa Melihat Ka\'abah 2', imagePath: 'assets/images/doa/doa_melihat_kaabah_2.png', audioPath: 'assets/audio/doa_melihat_kaabah_2.ogg'),
        DoaItem(title: 'Doa Melihat Ka\'abah 3', imagePath: 'assets/images/doa/doa_melihat_kaabah_3.png', audioPath: 'assets/audio/doa_melihat_kaabah_3.ogg'),
        DoaItem(title: 'Doa Melihat Ka\'abah 4', imagePath: 'assets/images/doa/doa_melihat_kaabah_4.png', audioPath: 'assets/audio/doa_melihat_kaabah_4.ogg'),
      ]),
    ],
  ),
  // ════════ STEP 10: PANDUAN DAN TIPS (DOA DAN TIPS) ════════
  const UmrahStep(
    id: 'panduan',
    title: 'Panduan dan Tips',
    subtitle: 'Panduan dan tips untuk jemaah',
    icon: 'assets/images/misc/ihram_land.png',
    subSteps: [
      // 1. Sujud Sajadah (5 items; images moved from locations/ and misc/ to doa/)
      UmrahSubStep(id: 'ayat_sajadah',title: 'Sujud Sajadah',duas: [
        DoaItem(title: 'Solat Subuh',textFile: 'sembahyang_subuh.txt',autoPlay: false,),
        DoaItem(title: 'Sujud Sajadah 1',  imagePath: 'assets/images/doa/al_sajadah_1.png',  audioPath: 'assets/audio/al_sajadah_1.ogg', autoPlay: false),
        DoaItem(title: 'Sujud Sajadah 2',  imagePath: 'assets/images/doa/al_sajadah_2.png',  audioPath: 'assets/audio/al_sajadah_2.ogg'),
        DoaItem(title: 'Sujud Sajadah 3',  imagePath: 'assets/images/doa/al_sajadah_3.png',  audioPath: 'assets/audio/al_sajadah_3.ogg'),
        DoaItem(title: 'Sujud Sajadah 15', imagePath: 'assets/images/doa/al_sajadah_15.png', audioPath: 'assets/audio/al_sajadah_15.ogg'),
        DoaItem(title: 'Doa Ketika Sujud', imagePath: 'assets/images/doa/sujud.png',         audioPath: 'assets/audio/doa_ketika_sujud.ogg'),
      ]),
      // 2. solat jenazah
      UmrahSubStep(id: 'solat_jenazah',title: 'Solat Jenazah',duas: [
        DoaItem(title: 'Panduan Solat Jenazah',textFile: 'solat_jenazah.txt',autoPlay: false,),
      ]),
      //3 peringatan wanita
      UmrahSubStep(id: 'tips_wanita',title: 'Peringatan Wanita',duas: [
        DoaItem(title: 'Peringatan Wanita',textFile: 'peringatan_wanita.txt',autoPlay: false,),
      ]),
      //4 tawaf sunat
      UmrahSubStep(id: 'tawaf_sunat',title: 'Tawaf Sunat',duas: [
        DoaItem(title: 'Tawaf Sunat dan kelebihan Umrah',textFile: 'umrah_tawaf_sunat.txt',autoPlay: false,),
      ]),
      //5 wuduk
      UmrahSubStep(id: 'wuduk',title: 'Permasalahan Wuduk',duas: [
        DoaItem(title: 'Permasalahan Wuduk',textFile: 'wuduk.txt',autoPlay: false,),
      ]),
    ],
  ),

];
