import '../../avatar/avatar_profile.dart';

/// One of Sora's two sub-models (suivi or contrôle).
class SoraBloc {
  const SoraBloc({
    required this.proba,
    required this.pourcentage,
    required this.classe,
    required this.seuil,
    required this.resultat,
    this.message,
  });

  factory SoraBloc.fromJson(Map<String, dynamic> j) => SoraBloc(
        proba: (j['proba'] as num).toDouble(),
        pourcentage: (j['pourcentage'] as num).toInt(),
        classe: (j['classe'] as num).toInt(),
        seuil: (j['seuil'] as num).toDouble(),
        resultat: j['resultat'] as String,
        message: j['message'] as String?,
      );

  final double proba;
  final int pourcentage;
  final int classe;
  final double seuil;
  final String resultat;
  final String? message;
}

/// Parsed response of POST /api/v1/sora/predict (M1 Suivi + M2 Contrôle).
class SoraResult {
  SoraResult(this.raw);

  final Map<String, dynamic> raw;

  SoraBloc get suivi => SoraBloc.fromJson(raw['suivi'] as Map<String, dynamic>);
  SoraBloc get controle => SoraBloc.fromJson(raw['controle'] as Map<String, dynamic>);
  String get profil => raw['profil'] as String;

  List<SpeechSegment> get narrative => (raw['narrative'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(SpeechSegment.fromJson)
      .toList();
}
