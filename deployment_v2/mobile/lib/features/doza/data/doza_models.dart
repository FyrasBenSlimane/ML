import '../../avatar/avatar_profile.dart';

/// One "what-if" factor that weighed most for this patient (an explanation,
/// never an actionable counterfactual).
class DozaFactor {
  const DozaFactor({required this.champ, required this.reponse, required this.impact});

  factory DozaFactor.fromJson(Map<String, dynamic> j) => DozaFactor(
        champ: j['champ'] as String,
        reponse: j['reponse'] as String,
        impact: (j['impact'] as num).toInt(),
      );

  final String champ;    // ex. "provenance"
  final String reponse;  // ex. "urgences"
  final int impact;      // amplitude de |Δp| en points de %
}

/// Parsed response of POST /api/v1/doza/predict.
class DozaResult {
  DozaResult(this.raw);

  final Map<String, dynamic> raw;

  double get proba => (raw['proba'] as num).toDouble();
  int get pourcentage => (raw['pourcentage'] as num).toInt();
  int get classe => (raw['classe'] as num).toInt();
  double get seuil => (raw['seuil'] as num).toDouble();
  String get zone => raw['zone'] as String;
  int? get zoneTaux => (raw['zone_taux'] as num?)?.toInt();

  bool get changeProbable => classe == 1;

  List<DozaFactor> get facteurs => (raw['facteurs'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(DozaFactor.fromJson)
      .toList();

  List<SpeechSegment> get narrative => (raw['narrative'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(SpeechSegment.fromJson)
      .toList();
}
