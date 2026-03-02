import 'package:latlong2/latlong.dart';

class UmrahLocation {
  final String id;
  final String name;
  final String nameMalay;
  final LatLng? center;
  final double? radiusMeters;
  /// An optional list of points describing a polygonal boundary. If provided,
  /// zone detection uses this instead of the circular center/radius model.
  final List<LatLng>? polygon;
  final String? stepId;
  final String? substepId;
  final String description;

  const UmrahLocation({
    required this.id,
    required this.name,
    required this.nameMalay,
    this.center,
    this.radiusMeters,
    this.polygon,
    this.stepId,
    this.substepId,
    required this.description,
  });
}

/// Predefined zones in and around Masjidil Haram
const List<UmrahLocation> umrahLocations = [
  UmrahLocation(
    id: 'kaabah',
    name: "Ka'abah",
    nameMalay: "Ka'abah (Tawaf)",
    center: LatLng(21.422524,39.826190),
    radiusMeters: 80,
    stepId: 'tawaf',
    substepId: 'tawaf_1',
    description: 'Kiblat umat Islam. Tawaf dilakukan mengelilingi Ka\'abah sebanyak 7 pusingan berlawanan arah jam.',
  ),
  UmrahLocation(
    id: 'hijir_ismail',
    name: 'Hijir Ismail',
    nameMalay: 'Hijir Ismail (Bahagian Tawaf)',
    center: LatLng(21.422596, 39.826126),
    radiusMeters: 5,
    // optionally define polygon instead of circle:
    polygon: [
      LatLng(21.422601, 39.826174),
      LatLng(21.422629, 39.826134),
      LatLng(21.422626, 39.826099),
      LatLng(21.422596, 39.826089),
      LatLng(21.422561, 39.826097),
      LatLng(21.422534, 39.826115),
      LatLng(21.422579, 39.826190),
    ],
    stepId: 'lain_lain',
    substepId: 'hijir_ismail',
    description: 'Kawasan separuh bulatan di sebelah barat laut Ka\'abah. Merupakan sebahagian dari Ka\'abah, Dilarang menyentuh semasa Tawaf.',
  ),
  UmrahLocation(
    id: 'makam_ibrahim',
    name: 'Makam Ibrahim',
    nameMalay: 'Makam Ibrahim',
    center: LatLng(21.422774, 39.826601),
    radiusMeters: 1,
    polygon: [
      LatLng(21.422576, 39.826311),
      LatLng(21.422619, 39.826802),
      LatLng(21.423056, 39.826735),
    ],
    stepId: 'lain_lain',
    substepId: 'doa_makam_ibrahim',
    description: 'Tempat Nabi Ibrahim a.s. berdiri semasa membina Ka\'abah. Solat sunat 2 rakaat selepas Tawaf.',
  ),
  UmrahLocation(
    id: 'multazam',
    name: 'Multazam',
    nameMalay: 'Multazam (Tempat Mustajab Doa)',
    center: LatLng(21.422482, 39.826566),
    radiusMeters: 1,
    polygon: [
      LatLng(21.422506, 39.826244),
      LatLng(21.422656, 39.826797),
      LatLng(21.422299, 39.826842),
    ],
    stepId: 'lain_lain',
    substepId: 'doa_di_multazam',
    description: 'Kawasan antara Hajar Aswad dan pintu Ka\'abah. Tempat yang sangat mustajab untuk berdoa.',
  ),
  UmrahLocation(
    id: 'bukit_safa',
    name: 'Bukit Safa',
    nameMalay: "Bukit Safa (Permulaan Sa'ie)",
    center: LatLng(21.421797, 39.827440),
    radiusMeters: 10,
    stepId: 'saie',
    substepId: 'saie_1',
    description: "Sa'ie bermula di Bukit Safa dan berakhir di Bukit Marwah (7 perjalanan).",
  ),
  UmrahLocation(
    id: 'bukit_marwah',
    name: 'Bukit Marwah',
    nameMalay: "Bukit Marwah (Penamat Sa'ie)",
    center: LatLng(21.425181, 39.827129),
    radiusMeters: 10,
    stepId: 'saie',
    substepId: 'tamat_saie',
    description: "Titik akhir setiap perjalanan Sa'ie (pusingan ganjil berakhir di Marwah).",
  ),
  UmrahLocation(
    id: 'BabusSalam',
    name: 'Pintu Bab al-Salam',
    nameMalay: "Pintu Bab al-Salam",
    center: LatLng(21.422843, 39.827617),
    radiusMeters: 5,
    stepId: 'lain_lain',
    substepId: 'doa_bab_salam',
    description: "Pintu yang digunakan Baginda Rasul-Allah SAW.",
  ),
];
