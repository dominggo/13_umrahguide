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
  /// If false, this doa acts as a manual break-point: audio auto-chain stops
  /// here and the user must tap Play manually. Default is true.
  final bool autoPlay;
  /// When set, opening this doa starts journey checkpoint N.
  final int? checkPointStart;
  /// When set, this doa closes journey checkpoint N.
  final int? checkPointEnd;
  /// Label for the next section, shown on the checkpoint-end button.
  final String? nextLabel;
  /// Optional override name for this checkpoint in journey history.
  /// If null, the substep title is used as the checkpoint name.
  final String? checkPointName;

  const DoaItem({
    required this.title,
    this.imagePath,
    this.audioPath,
    this.description,
    this.textFile,
    this.autoPlay = true,
    this.checkPointStart,
    this.checkPointEnd,
    this.nextLabel,
    this.checkPointName,
  });
}
