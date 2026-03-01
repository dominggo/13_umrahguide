class UmrahStep {
  final String id;
  final String title;
  final String subtitle;
  final String icon; // asset path
  final List<UmrahSubStep> subSteps;
  final String? textFile; // optional text guide in assets/text/

  const UmrahStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.subSteps,
    this.textFile,
  });
}

class UmrahSubStep {
  final String id;
  final String title;
  final List<DoaItem> duas;

  const UmrahSubStep({
    required this.id,
    required this.title,
    required this.duas,
  });
}

class DoaItem {
  final String title;
  final String? imagePath; // assets/images/doa/xxx.png
  final String? audioPath; // assets/audio/xxx.ogg
  final String? description;
  final String? textFile; // filename in assets/text/ (HTML-formatted)
  /// If false, this doa acts as a manual break-point: auto-play stops here,
  /// the user must tap Play manually. Default is true.
  final bool autoPlay;

  const DoaItem({
    required this.title,
    this.imagePath,
    this.audioPath,
    this.description,
    this.textFile,
    this.autoPlay = true,
  });
}
