import 'package:latlong2/latlong.dart';

class UmrahLocation {
  final String id;
  final String name;
  final String nameMalay;
  final LatLng center;
  final double radiusMeters;
  final String? stepId;
  final String? substepId;
  final String description;

  const UmrahLocation({
    required this.id,
    required this.name,
    required this.nameMalay,
    required this.center,
    required this.radiusMeters,
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
    center: LatLng(21.4225, 39.8262),
    radiusMeters: 80,
    stepId: 'tawaf',
    substepId: 'tawaf_1',
    description: 'Kiblat umat Islam. Tawaf dilakukan mengelilingi Ka\'abah sebanyak 7 pusingan berlawanan arah jam.',
  ),
  UmrahLocation(
    id: 'hijir_ismail',
    name: 'Hijir Ismail',
    nameMalay: 'Hijir Ismail (Bahagian Tawaf)',
    center: LatLng(21.4231, 39.8257),
    radiusMeters: 25,
    stepId: 'tawaf',
    substepId: 'tawaf_1',
    description: 'Kawasan separuh bulatan di sebelah barat laut Ka\'abah. Perlu dilalui semasa Tawaf.',
  ),
  UmrahLocation(
    id: 'makam_ibrahim',
    name: 'Makam Ibrahim',
    nameMalay: 'Makam Ibrahim (Solat Sunat Tawaf)',
    center: LatLng(21.4228, 39.8264),
    radiusMeters: 15,
    stepId: 'solat_tawaf',
    substepId: 'solat_tawaf_makam',
    description: 'Tempat Nabi Ibrahim a.s. berdiri semasa membina Ka\'abah. Solat sunat 2 rakaat selepas Tawaf.',
  ),
  UmrahLocation(
    id: 'multazam',
    name: 'Multazam',
    nameMalay: 'Multazam (Tempat Mustajab Doa)',
    center: LatLng(21.4224, 39.8263),
    radiusMeters: 12,
    stepId: 'solat_tawaf',
    substepId: 'multazam',
    description: 'Kawasan antara Hajar Aswad dan pintu Ka\'abah. Tempat yang sangat mustajab untuk berdoa.',
  ),
  UmrahLocation(
    id: 'telaga_zamzam',
    name: 'Telaga Zamzam',
    nameMalay: 'Air Zam Zam',
    center: LatLng(21.4224, 39.8265),
    radiusMeters: 25,
    stepId: 'solat_tawaf',
    substepId: 'zamzam',
    description: 'Perigi bersejarah air Zam Zam. Minum air Zam Zam dengan niat dan doa.',
  ),
  UmrahLocation(
    id: 'bukit_safa',
    name: 'Bukit Safa',
    nameMalay: "Bukit Safa (Permulaan Sa'ie)",
    center: LatLng(21.4215, 39.8279),
    radiusMeters: 35,
    stepId: 'saie',
    substepId: 'saie_1',
    description: "Sa'ie bermula di Bukit Safa dan berakhir di Bukit Marwah (7 perjalanan).",
  ),
  UmrahLocation(
    id: 'bukit_marwah',
    name: 'Bukit Marwah',
    nameMalay: "Bukit Marwah (Penamat Sa'ie)",
    center: LatLng(21.4234, 39.8279),
    radiusMeters: 35,
    stepId: 'saie',
    substepId: 'saie_1',
    description: "Titik akhir setiap perjalanan Sa'ie (pusingan ganjil berakhir di Marwah).",
  ),
];
