import '../models/umrah_step.dart';

final List<UmrahStep> umrahSteps = [
  // ─── 1. IHRAM ───────────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'ihram',
    title: 'Ihram',
    subtitle: 'Persediaan & Niat',
    icon: 'assets/images/misc/ihram_land.png',
    textFile: 'adab_ihram.txt',
    subSteps: [
      const UmrahSubStep(
        id: 'mandi_ihram',
        title: 'Mandi Sunat Ihram',
        duas: [
          const DoaItem(
            title: 'Niat Mandi Ihram',
            imagePath: 'assets/images/misc/niat_miqat.png',
            audioPath: 'assets/audio/niat_mandi_ihram.ogg',
          ),
        ],
      ),
      const UmrahSubStep(
        id: 'solat_ihram',
        title: 'Solat Sunat Ihram',
        duas: [
          const DoaItem(
            title: 'Niat Solat Sunat Ihram',
            audioPath: 'assets/audio/niat_solat_ihram.ogg',
          ),
        ],
      ),
      const UmrahSubStep(
        id: 'niat_umrah',
        title: 'Lafaz Niat Umrah',
        duas: [
          const DoaItem(
            title: 'Lafaz Niat Umrah',
            audioPath: 'assets/audio/lafaz_niat_umrah.ogg',
          ),
        ],
      ),
      const UmrahSubStep(
        id: 'talbiah',
        title: 'Talbiah',
        duas: [
          const DoaItem(
            title: 'Bacaan Talbiah',
            imagePath: 'assets/images/doa/talbiah.png',
            audioPath: 'assets/audio/talbiah.ogg',
          ),
        ],
      ),
      const UmrahSubStep(
        id: 'permulaan_safar',
        title: 'Doa Permulaan Safar',
        duas: [
          const DoaItem(
            title: 'Doa Permulaan Safar 1',
            imagePath: 'assets/images/overview/permulaan_safar_1a.png',
            audioPath: 'assets/audio/permulaan_safar_1.ogg',
          ),
        ],
      ),
    ],
  ),

  // ─── 2. MASUK MAKKAH ────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'masuk_makkah',
    title: 'Masuk Kota Makkah',
    subtitle: 'Doa Masuk Makkah',
    icon: 'assets/images/locations/img_kaabah_1.jpg',
    subSteps: [
      const UmrahSubStep(
        id: 'doa_masuk_makkah',
        title: 'Doa Masuk Kota Makkah',
        duas: [
          const DoaItem(title: 'Doa Masuk Makkah 1', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_1.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_1.ogg'),
          const DoaItem(title: 'Doa Masuk Makkah 2', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_2.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_2.ogg'),
          const DoaItem(title: 'Doa Masuk Makkah 3', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_3.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_3.ogg'),
          const DoaItem(title: 'Doa Masuk Makkah 4', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_4.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_4.ogg'),
          const DoaItem(title: 'Doa Masuk Makkah 5', imagePath: 'assets/images/doa/doa_masuk_kota_mekah_5.png', audioPath: 'assets/audio/doa_masuk_kota_mekah_5.ogg'),
        ],
      ),
    ],
  ),

  // ─── 3. MELIHAT KAABAH ──────────────────────────────────────────────────────
  const UmrahStep(
    id: 'melihat_kaabah',
    title: 'Melihat Ka\'abah',
    subtitle: 'Doa Pertama Melihat Ka\'abah',
    icon: 'assets/images/locations/img_kaabah_2.jpg',
    subSteps: [
      const UmrahSubStep(
        id: 'doa_kaabah',
        title: 'Doa Melihat Ka\'abah',
        duas: [
          const DoaItem(title: 'Doa Melihat Ka\'abah 1', imagePath: 'assets/images/doa/doa_melihat_kaabah_1.png', audioPath: 'assets/audio/doa_melihat_kaabah_1.ogg'),
          const DoaItem(title: 'Doa Melihat Ka\'abah 2', imagePath: 'assets/images/doa/doa_melihat_kaabah_2.png', audioPath: 'assets/audio/doa_melihat_kaabah_2.ogg'),
          const DoaItem(title: 'Doa Melihat Ka\'abah 3', imagePath: 'assets/images/doa/doa_melihat_kaabah_3.png', audioPath: 'assets/audio/doa_melihat_kaabah_3.ogg'),
          const DoaItem(title: 'Doa Melihat Ka\'abah 4', imagePath: 'assets/images/doa/doa_melihat_kaabah_4.png', audioPath: 'assets/audio/doa_melihat_kaabah_4.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'bani_syaibah',
        title: 'Doa di Pintu Bani Syaibah',
        duas: [
          const DoaItem(title: 'Doa Bani Syaibah 1', imagePath: 'assets/images/doa/doa_bani_syaibah_1.png', audioPath: 'assets/audio/doa_bani_syaibah_1.ogg'),
          const DoaItem(title: 'Doa Bani Syaibah 2', imagePath: 'assets/images/doa/doa_bani_syaibah_2.png', audioPath: 'assets/audio/doa_bani_syaibah_2.ogg'),
        ],
      ),
    ],
  ),

  // ─── 4. TAWAF ───────────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'tawaf',
    title: 'Tawaf',
    subtitle: '7 Pusingan mengelilingi Ka\'abah',
    icon: 'assets/images/misc/icp_kaabah.jpg',
    textFile: 'tawaf_perlaksanaan.txt',
    subSteps: [
      const UmrahSubStep(
        id: 'niat_tawaf',
        title: 'Niat Tawaf',
        duas: [
          const DoaItem(title: 'Niat Tawaf Umrah', imagePath: 'assets/images/doa/niat_tawaf_umrah.png', audioPath: 'assets/audio/niat_tawaf_umrah.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_1',
        title: 'Pusingan 1 - Pertama',
        duas: [
          const DoaItem(title: 'Doa Tawaf Pertama 1', imagePath: 'assets/images/doa/doa_tawaf_pertama_1.png', audioPath: 'assets/audio/doa_tawaf_pertama_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Pertama 2', imagePath: 'assets/images/doa/doa_tawaf_pertama_2.png', audioPath: 'assets/audio/doa_tawaf_pertama_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Pertama 3', imagePath: 'assets/images/doa/doa_tawaf_pertama_3.png', audioPath: 'assets/audio/doa_tawaf_pertama_3.ogg'),
          const DoaItem(title: 'Doa Tawaf Pertama 4', imagePath: 'assets/images/doa/doa_tawaf_pertama_4.png', audioPath: 'assets/audio/doa_tawaf_pertama_4.ogg'),
          const DoaItem(title: 'Doa Antara Dua Rukun', imagePath: 'assets/images/doa/doa_antara_dua_rukun.png', audioPath: 'assets/audio/doa_antara_dua_rukun.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_2',
        title: 'Pusingan 2 - Kedua',
        duas: [
          const DoaItem(title: 'Doa Tawaf Kedua 1', imagePath: 'assets/images/doa/doa_tawaf_kedua_1.png', audioPath: 'assets/audio/doa_tawaf_kedua_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Kedua 2', imagePath: 'assets/images/doa/doa_tawaf_kedua_2.png', audioPath: 'assets/audio/doa_tawaf_kedua_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Kedua 3', imagePath: 'assets/images/doa/doa_tawaf_kedua_3.png', audioPath: 'assets/audio/doa_tawaf_kedua_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_3',
        title: 'Pusingan 3 - Ketiga',
        duas: [
          const DoaItem(title: 'Doa Tawaf Ketiga 1', imagePath: 'assets/images/doa/doa_tawaf_ketiga_1.png', audioPath: 'assets/audio/doa_tawaf_ketiga_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Ketiga 2', imagePath: 'assets/images/doa/doa_tawaf_ketiga_2.png', audioPath: 'assets/audio/doa_tawaf_ketiga_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Ketiga 3', imagePath: 'assets/images/doa/doa_tawaf_ketiga_3.png', audioPath: 'assets/audio/doa_tawaf_ketiga_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_4',
        title: 'Pusingan 4 - Keempat',
        duas: [
          const DoaItem(title: 'Doa Tawaf Keempat 1', imagePath: 'assets/images/doa/doa_tawaf_keempat_1.png', audioPath: 'assets/audio/doa_tawaf_keempat_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Keempat 2', imagePath: 'assets/images/doa/doa_tawaf_keempat_2.png', audioPath: 'assets/audio/doa_tawaf_keempat_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Keempat 3', imagePath: 'assets/images/doa/doa_tawaf_keempat_3.png', audioPath: 'assets/audio/doa_tawaf_keempat_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_5',
        title: 'Pusingan 5 - Kelima',
        duas: [
          const DoaItem(title: 'Doa Tawaf Kelima 1', imagePath: 'assets/images/doa/doa_tawaf_kelima_1.png', audioPath: 'assets/audio/doa_tawaf_kelima_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Kelima 2', imagePath: 'assets/images/doa/doa_tawaf_kelima_2.png', audioPath: 'assets/audio/doa_tawaf_kelima_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Kelima 3', imagePath: 'assets/images/doa/doa_tawaf_kelima_3.png', audioPath: 'assets/audio/doa_tawaf_kelima_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_6',
        title: 'Pusingan 6 - Keenam',
        duas: [
          const DoaItem(title: 'Doa Tawaf Keenam 1', imagePath: 'assets/images/doa/doa_tawaf_keenam_1.png', audioPath: 'assets/audio/doa_tawaf_keenam_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Keenam 2', imagePath: 'assets/images/doa/doa_tawaf_keenam_2.png', audioPath: 'assets/audio/doa_tawaf_keenam_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Keenam 3', imagePath: 'assets/images/doa/doa_tawaf_keenam_3.png', audioPath: 'assets/audio/doa_tawaf_keenam_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'tawaf_7',
        title: 'Pusingan 7 - Ketujuh',
        duas: [
          const DoaItem(title: 'Doa Tawaf Ketujuh 1', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_1.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_1.ogg'),
          const DoaItem(title: 'Doa Tawaf Ketujuh 2', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_2.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_2.ogg'),
          const DoaItem(title: 'Doa Tawaf Ketujuh 3', imagePath: 'assets/images/doa/doa_tawaf_ketujuh_3.png', audioPath: 'assets/audio/doa_tawaf_ketujuh_3.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'hijir_ismail',
        title: 'Doa di Hijir Ismail',
        duas: [
          const DoaItem(title: 'Doa Hijir Ismail 1', imagePath: 'assets/images/doa/doa_hijir_ismail_1.png', audioPath: 'assets/audio/doa_hijir_ismail_1.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 2', imagePath: 'assets/images/doa/doa_hijir_ismail_2.png', audioPath: 'assets/audio/doa_hijir_ismail_2.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 3', imagePath: 'assets/images/doa/doa_hijir_ismail_3.png', audioPath: 'assets/audio/doa_hijir_ismail_3.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 4', imagePath: 'assets/images/doa/doa_hijir_ismail_4.png', audioPath: 'assets/audio/doa_hijir_ismail_4.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 5', imagePath: 'assets/images/doa/doa_hijir_ismail_5.png', audioPath: 'assets/audio/doa_hijir_ismail_5.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 6', imagePath: 'assets/images/doa/doa_hijir_ismail_6.png', audioPath: 'assets/audio/doa_hijir_ismail_6.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 7', imagePath: 'assets/images/doa/doa_hijir_ismail_7.png', audioPath: 'assets/audio/doa_hijir_ismail_7.ogg'),
          const DoaItem(title: 'Doa Hijir Ismail 8', imagePath: 'assets/images/doa/doa_hijir_ismail_8.png', audioPath: 'assets/audio/doa_hijir_ismail_8.ogg'),
        ],
      ),
    ],
  ),

  // ─── 5. SOLAT SUNAT TAWAF ───────────────────────────────────────────────────
  const UmrahStep(
    id: 'solat_tawaf',
    title: 'Solat Sunat Tawaf',
    subtitle: 'Di Makam Ibrahim',
    icon: 'assets/images/locations/tempat_4_a.jpg',
    subSteps: [
      const UmrahSubStep(
        id: 'niat_solat_tawaf',
        title: 'Niat Solat Sunat Tawaf',
        duas: [
          const DoaItem(title: 'Niat Solat Sunat Tawaf', audioPath: 'assets/audio/niat_solat_sunat_tawaf.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'doa_makam_ibrahim',
        title: 'Doa di Makam Ibrahim',
        duas: [
          const DoaItem(title: 'Doa Makam Ibrahim 1', imagePath: 'assets/images/doa/doa_makam_ibrahim_1.png', audioPath: 'assets/audio/doa_makam_ibrahim_1.ogg'),
          const DoaItem(title: 'Doa Makam Ibrahim 2', imagePath: 'assets/images/doa/doa_makam_ibrahim_2.png', audioPath: 'assets/audio/doa_makam_ibrahim_2.ogg'),
          const DoaItem(title: 'Doa Makam Ibrahim 3', imagePath: 'assets/images/doa/doa_makam_ibrahim_3.png', audioPath: 'assets/audio/doa_makam_ibrahim_3.ogg'),
          const DoaItem(title: 'Doa Makam Ibrahim 4', imagePath: 'assets/images/doa/doa_makam_ibrahim_4.png', audioPath: 'assets/audio/doa_makam_ibrahim_4.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'multazam',
        title: 'Doa di Multazam',
        duas: [
          const DoaItem(title: 'Doa di Multazam 1', imagePath: 'assets/images/doa/doa_di_multazam_1.png', audioPath: 'assets/audio/doa_di_multazam_1.ogg'),
          const DoaItem(title: 'Doa di Multazam 2', imagePath: 'assets/images/doa/doa_di_multazam_2.png', audioPath: 'assets/audio/doa_di_multazam_2.ogg'),
          const DoaItem(title: 'Doa di Multazam 3', imagePath: 'assets/images/doa/doa_di_multazam_3.png', audioPath: 'assets/audio/doa_di_multazam_3.ogg'),
          const DoaItem(title: 'Doa di Multazam 4', imagePath: 'assets/images/doa/doa_di_multazam_4.png', audioPath: 'assets/audio/doa_di_multazam_4.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'air_zamzam',
        title: 'Minum Air Zam Zam',
        duas: [
          const DoaItem(title: 'Doa Minum Air Zam Zam', audioPath: 'assets/audio/doa_minum_air_zam2.ogg'),
        ],
      ),
    ],
  ),

  // ─── 6. SAIE ────────────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'saie',
    title: 'Sa\'ie',
    subtitle: '7 kali Safa ke Marwah',
    icon: 'assets/images/misc/icp_saie.jpg',
    textFile: 'saie.txt',
    subSteps: [
      const UmrahSubStep(
        id: 'niat_saie',
        title: 'Niat Sa\'ie',
        duas: [
          const DoaItem(title: 'Niat Sa\'ie Umrah', audioPath: 'assets/audio/niat_saie_umrah.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'doa_bab_safa',
        title: 'Doa di Pintu Bab al-Safa',
        duas: [
          const DoaItem(title: 'Doa Bab al-Safa', imagePath: 'assets/images/doa/doa_bab_al_safa.png', audioPath: 'assets/audio/doa_bab_al_safa.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'saie_1',
        title: 'Saie 1 - Safa ke Marwah',
        duas: [
          const DoaItem(title: 'Doa di Bukit Safa 1', imagePath: 'assets/images/doa/doa_bukit_safa_1.png', audioPath: 'assets/audio/doa_bukit_safa_1.ogg'),
          const DoaItem(title: 'Doa di Bukit Safa 2', imagePath: 'assets/images/doa/doa_bukit_safa_2.png', audioPath: 'assets/audio/doa_bukit_safa_2.ogg'),
          const DoaItem(title: 'Doa di Bukit Safa 3', imagePath: 'assets/images/doa/doa_bukit_safa_3.png', audioPath: 'assets/audio/doa_bukit_safa_3.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 1', imagePath: 'assets/images/doa/doa_saie_pertama_1.png', audioPath: 'assets/audio/doa_saie_pertama_1.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 2', imagePath: 'assets/images/doa/doa_saie_pertama_2.png', audioPath: 'assets/audio/doa_saie_pertama_2.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 3', imagePath: 'assets/images/doa/doa_saie_pertama_3.png', audioPath: 'assets/audio/doa_saie_pertama_3.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 4', imagePath: 'assets/images/doa/doa_saie_pertama_4.png', audioPath: 'assets/audio/doa_saie_pertama_4.ogg'),
          const DoaItem(title: 'Doa Antara Tiang Hijau 1', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_1.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_1.ogg'),
          const DoaItem(title: 'Doa Antara Tiang Hijau 2', imagePath: 'assets/images/doa/doa_antara_tiang2_hijau_2.png', audioPath: 'assets/audio/doa_antara_tiang2_hijau_2.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 6', audioPath: 'assets/audio/doa_saie_pertama_6.ogg'),
          const DoaItem(title: 'Doa Saie Pertama 7', audioPath: 'assets/audio/doa_saie_pertama_7.ogg'),
          const DoaItem(title: 'Doa di Bukit Marwah 1', imagePath: 'assets/images/doa/doa_bukit_marwah_1.png', audioPath: 'assets/audio/doa_bukit_marwah_1.ogg'),
          const DoaItem(title: 'Doa di Bukit Marwah 2', imagePath: 'assets/images/doa/doa_bukit_marwah_2.png', audioPath: 'assets/audio/doa_bukit_marwah_2.ogg'),
          const DoaItem(title: 'Doa di Bukit Marwah 3', imagePath: 'assets/images/doa/doa_bukit_marwah_3.png', audioPath: 'assets/audio/doa_bukit_marwah_3.ogg'),
        ],
      ),
      const UmrahSubStep(id: 'saie_2', title: 'Saie 2 - Marwah ke Safa', duas: [
        const DoaItem(title: 'Doa Saie Kedua 1', imagePath: 'assets/images/doa/doa_saie_kedua_1.png', audioPath: 'assets/audio/doa_saie_kedua_1.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 2', imagePath: 'assets/images/doa/doa_saie_kedua_2.png', audioPath: 'assets/audio/doa_saie_kedua_2.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 3', imagePath: 'assets/images/doa/doa_saie_kedua_3.png', audioPath: 'assets/audio/doa_saie_kedua_3.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 4', imagePath: 'assets/images/doa/doa_saie_kedua_4.png', audioPath: 'assets/audio/doa_saie_kedua_4.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 5', imagePath: 'assets/images/doa/doa_saie_kedua_5.png', audioPath: 'assets/audio/doa_saie_kedua_5.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 6', imagePath: 'assets/images/doa/doa_saie_kedua_6.png', audioPath: 'assets/audio/doa_saie_kedua_6.ogg'),
        const DoaItem(title: 'Doa Saie Kedua 7', imagePath: 'assets/images/doa/doa_saie_kedua_7.png', audioPath: 'assets/audio/doa_saie_kedua_7.ogg'),
      ]),
      const UmrahSubStep(id: 'saie_3', title: 'Saie 3 - Safa ke Marwah', duas: [
        const DoaItem(title: 'Doa Saie Ketiga 1', imagePath: 'assets/images/doa/doa_saie_ketiga_1.png', audioPath: 'assets/audio/doa_saie_ketiga_1.ogg'),
        const DoaItem(title: 'Doa Saie Ketiga 2', imagePath: 'assets/images/doa/doa_saie_ketiga_2.png', audioPath: 'assets/audio/doa_saie_ketiga_2.ogg'),
        const DoaItem(title: 'Doa Saie Ketiga 3', imagePath: 'assets/images/doa/doa_saie_ketiga_3.png', audioPath: 'assets/audio/doa_saie_ketiga_3.ogg'),
        const DoaItem(title: 'Doa Saie Ketiga 4', imagePath: 'assets/images/doa/doa_saie_ketiga_4.png', audioPath: 'assets/audio/doa_saie_ketiga_4.ogg'),
      ]),
      const UmrahSubStep(id: 'saie_4', title: 'Saie 4 - Marwah ke Safa', duas: [
        const DoaItem(title: 'Doa Saie Keempat 1', imagePath: 'assets/images/doa/doa_saie_keempat_1.png', audioPath: 'assets/audio/doa_saie_keempat_1.ogg'),
        const DoaItem(title: 'Doa Saie Keempat 2', imagePath: 'assets/images/doa/doa_saie_keempat_2.png', audioPath: 'assets/audio/doa_saie_keempat_2.ogg'),
        const DoaItem(title: 'Doa Saie Keempat 3', imagePath: 'assets/images/doa/doa_saie_keempat_3.png', audioPath: 'assets/audio/doa_saie_keempat_3.ogg'),
        const DoaItem(title: 'Doa Saie Keempat 4', imagePath: 'assets/images/doa/doa_saie_keempat_4.png', audioPath: 'assets/audio/doa_saie_keempat_4.ogg'),
        const DoaItem(title: 'Doa Saie Keempat 5', imagePath: 'assets/images/doa/doa_saie_keempat_5.png', audioPath: 'assets/audio/doa_saie_keempat_5.ogg'),
        const DoaItem(title: 'Doa Saie Keempat 6', imagePath: 'assets/images/doa/doa_saie_keempat_6.png', audioPath: 'assets/audio/doa_saie_keempat_6.ogg'),
      ]),
      const UmrahSubStep(id: 'saie_5', title: 'Saie 5 - Safa ke Marwah', duas: [
        const DoaItem(title: 'Doa Saie Kelima 1', imagePath: 'assets/images/doa/doa_saie_kelima_1.png', audioPath: 'assets/audio/doa_saie_kelima_1.ogg'),
        const DoaItem(title: 'Doa Saie Kelima 2', imagePath: 'assets/images/doa/doa_saie_kelima_2.png', audioPath: 'assets/audio/doa_saie_kelima_2.ogg'),
        const DoaItem(title: 'Doa Saie Kelima 3', imagePath: 'assets/images/doa/doa_saie_kelima_3.png', audioPath: 'assets/audio/doa_saie_kelima_3.ogg'),
      ]),
      const UmrahSubStep(id: 'saie_6', title: 'Saie 6 - Marwah ke Safa', duas: [
        const DoaItem(title: 'Doa Saie Keenam 1', imagePath: 'assets/images/doa/doa_saie_keenam_1.png', audioPath: 'assets/audio/doa_saie_keenam_1.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 2', imagePath: 'assets/images/doa/doa_saie_keenam_2.png', audioPath: 'assets/audio/doa_saie_keenam_2.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 3', imagePath: 'assets/images/doa/doa_saie_keenam_3.png', audioPath: 'assets/audio/doa_saie_keenam_3.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 4', imagePath: 'assets/images/doa/doa_saie_keenam_4.png', audioPath: 'assets/audio/doa_saie_keenam_4.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 5', imagePath: 'assets/images/doa/doa_saie_keenam_5.png', audioPath: 'assets/audio/doa_saie_keenam_5.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 6', imagePath: 'assets/images/doa/doa_saie_keenam_6.png', audioPath: 'assets/audio/doa_saie_keenam_6.ogg'),
        const DoaItem(title: 'Doa Saie Keenam 7', imagePath: 'assets/images/doa/doa_saie_keenam_7.png', audioPath: 'assets/audio/doa_saie_keenam_7.ogg'),
      ]),
      const UmrahSubStep(id: 'saie_7', title: 'Saie 7 - Safa ke Marwah (Akhir)', duas: [
        const DoaItem(title: 'Doa Saie Ketujuh 1', imagePath: 'assets/images/doa/doa_saie_ketujuh_1.png', audioPath: 'assets/audio/doa_saie_ketujuh_1.ogg'),
        const DoaItem(title: 'Doa Saie Ketujuh 2', imagePath: 'assets/images/doa/doa_saie_ketujuh_2.png', audioPath: 'assets/audio/doa_saie_ketujuh_2.ogg'),
      ]),
    ],
  ),

  // ─── 7. TAHALLUL ────────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'tahallul',
    title: 'Tahallul',
    subtitle: 'Bercukur atau Bergunting',
    icon: 'assets/images/misc/ihram.png',
    textFile: 'tahallul.txt',
    subSteps: [
      const UmrahSubStep(
        id: 'doa_bercukur',
        title: 'Doa Bercukur / Bergunting',
        duas: [
          const DoaItem(title: 'Doa Bercukur 1', imagePath: 'assets/images/doa/doa_bercukur_1.png', audioPath: 'assets/audio/doa_bercukur_1.ogg'),
          const DoaItem(title: 'Doa Bercukur 2', imagePath: 'assets/images/doa/doa_bercukur_2.png', audioPath: 'assets/audio/doa_bercukur_2.ogg'),
          const DoaItem(title: 'Doa Bercukur 3', imagePath: 'assets/images/doa/doa_bercukur_3.png', audioPath: 'assets/audio/doa_bercukur_3.ogg'),
          const DoaItem(title: 'Doa Bercukur 4', imagePath: 'assets/images/doa/doa_bercukur_4.png', audioPath: 'assets/audio/doa_bercukur_4.ogg'),
        ],
      ),
    ],
  ),

  // ─── 8. TAWAF WIDA ──────────────────────────────────────────────────────────
  const UmrahStep(
    id: 'tawaf_wida',
    title: 'Tawaf Wida\'',
    subtitle: 'Tawaf Selamat Tinggal',
    icon: 'assets/images/misc/ihram_land.png',
    subSteps: [
      const UmrahSubStep(
        id: 'niat_tawaf_wida',
        title: 'Niat Tawaf Wida\'',
        duas: [
          const DoaItem(title: 'Niat Tawaf Wida\'', audioPath: 'assets/audio/niat_tawaf_wida.ogg'),
        ],
      ),
      const UmrahSubStep(
        id: 'doa_tawaf_wida',
        title: 'Doa Ketika Tawaf Wida\'',
        duas: List.generate(
          27,
          (i) => DoaItem(
            title: 'Doa Tawaf Wida\' ${i + 1}',
            imagePath: 'assets/images/doa/doa_ketika_tawaf_wada_${i + 1}.png',
            audioPath: 'assets/audio/doa_ketika_tawaf_wada_${i + 1}.ogg',
          ),
        ),
      ),
    ],
  ),
];
