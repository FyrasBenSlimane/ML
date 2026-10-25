import '../../avatar/avatar_profile.dart';

/// A selectable value for a coded field, e.g. {value: 6, label: "Home with home-health"}.
class FieldOption {
  const FieldOption(this.value, this.label);

  final Object value;
  final String label;
}

class FieldSpec {
  const FieldSpec({
    required this.type,
    required this.defaultValue,
    this.options = const [],
    this.min,
    this.max,
  });

  factory FieldSpec.fromJson(Map<String, dynamic> j) => FieldSpec(
        type: j['type'] as String,
        defaultValue: j['default'] as Object,
        options: (j['options'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map((o) => FieldOption(o['value'] as Object, o['label'] as String))
            .toList(),
        min: (j['min'] as num?)?.toInt(),
        max: (j['max'] as num?)?.toInt(),
      );

  final String type; // "choice" | "number"
  final Object defaultValue;
  final List<FieldOption> options;
  final int? min;
  final int? max;

  String labelFor(Object? value) =>
      options.where((o) => o.value == value).map((o) => o.label).firstOrNull ?? '$value';
}

class SamplePatient {
  const SamplePatient(this.label, this.expectedProbability, this.patient);

  final String label;
  final double expectedProbability;
  final Map<String, dynamic> patient;
}

class ModelMetrics {
  const ModelMetrics(this.raw);

  final Map<String, dynamic> raw;

  double get rocAuc => (raw['roc_auc'] as num).toDouble();
  double get prAuc => (raw['pr_auc'] as num).toDouble();
  double get brier => (raw['brier'] as num).toDouble();
  double get baselineRate => (raw['baseline_rate'] as num).toDouble();
  double get prLift => (raw['pr_lift'] as num).toDouble();
  int get nTest => (raw['n_test'] as num).toInt();
  int get nTrain => (raw['n_train'] as num).toInt();
  int get nFeatures => (raw['n_features'] as num).toInt();
}

class TeemoMeta {
  const TeemoMeta({
    required this.fields,
    required this.model,
    required this.metrics,
    required this.samples,
    required this.bands,
  });

  factory TeemoMeta.fromJson(Map<String, dynamic> j) {
    final model = j['model'] as Map<String, dynamic>;
    return TeemoMeta(
      fields: (j['fields'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, FieldSpec.fromJson(v as Map<String, dynamic>))),
      model: model,
      metrics: ModelMetrics(model['metrics'] as Map<String, dynamic>),
      samples: (j['samples'] as List)
          .cast<Map<String, dynamic>>()
          .map((s) => SamplePatient(
                s['label'] as String,
                (s['expected_probability'] as num).toDouble(),
                Map<String, dynamic>.from(s['patient'] as Map),
              ))
          .toList(),
      bands: (j['bands'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, ((v as Map)['observed_rate'] as num?)?.toDouble() ?? 0)),
    );
  }

  final Map<String, FieldSpec> fields;
  final Map<String, dynamic> model;
  final ModelMetrics metrics;
  final List<SamplePatient> samples;

  /// Observed readmission rate per risk band on the test set.
  final Map<String, double> bands;

  Map<String, dynamic> get defaults =>
      fields.map((k, v) => MapEntry(k, v.defaultValue));
}

class Driver {
  const Driver({
    required this.key,
    required this.title,
    required this.value,
    required this.explanation,
    required this.up,
    required this.share,
    required this.modifiable,
  });

  factory Driver.fromJson(Map<String, dynamic> j) => Driver(
        key: j['key'] as String,
        title: j['title'] as String,
        value: j['value'] as String,
        explanation: j['explanation'] as String,
        up: j['direction'] == 'up',
        share: (j['share'] as num).toDouble(),
        modifiable: j['modifiable'] as bool,
      );

  final String key;
  final String title;
  final String value;
  final String explanation;
  final bool up;
  final double share;
  final bool modifiable;
}

class CareAction {
  const CareAction(this.icon, this.title, this.detail, this.priority);

  factory CareAction.fromJson(Map<String, dynamic> j) => CareAction(
      j['icon'] as String, j['title'] as String, j['detail'] as String, j['priority'] as String);

  final String icon;
  final String title;
  final String detail;
  final String priority;
}

class TeemoResult {
  TeemoResult(this.raw, {this.label});

  /// Keeps the server JSON so history can be stored and restored losslessly.
  final Map<String, dynamic> raw;

  /// Optional nickname typed by the nurse ("Room 214").
  final String? label;

  String get id => raw['id'] as String;
  DateTime get createdAt => DateTime.parse(raw['created_at'] as String).toLocal();
  double get probability => (raw['probability'] as num).toDouble();
  double get percentage => (raw['percentage'] as num).toDouble();
  String get level => raw['level'] as String;
  double get baselineRate => (raw['baseline_rate'] as num).toDouble();
  double get relativeRisk => (raw['relative_risk'] as num).toDouble();
  int? get percentile => (raw['percentile'] as num?)?.toInt();
  double? get bandObservedRate => (raw['band_observed_rate'] as num?)?.toDouble();
  bool get interventionRecommended => raw['intervention_recommended'] as bool;
  Map<String, dynamic> get thresholds => raw['thresholds'] as Map<String, dynamic>;
  Map<String, dynamic> get patient => raw['patient'] as Map<String, dynamic>;
  List<String> get defaultedFields => (raw['defaulted_fields'] as List).cast<String>();
  Map<String, dynamic> get model => raw['model'] as Map<String, dynamic>;
  ModelMetrics get metrics => ModelMetrics(model['metrics'] as Map<String, dynamic>);

  List<Driver> get drivers => (raw['drivers'] as List)
      .cast<Map<String, dynamic>>()
      .map(Driver.fromJson)
      .toList();

  List<CareAction> get actions => (raw['actions'] as List)
      .cast<Map<String, dynamic>>()
      .map(CareAction.fromJson)
      .toList();

  List<SpeechSegment> get narrative => (raw['narrative'] as List)
      .cast<Map<String, dynamic>>()
      .map(SpeechSegment.fromJson)
      .toList();

  String get levelLabel => switch (level) {
        'HIGH' => 'High risk',
        'MODERATE' => 'Moderate risk',
        _ => 'Low risk',
      };

  Map<String, dynamic> toJson() => {'raw': raw, 'label': label};

  factory TeemoResult.fromJson(Map<String, dynamic> j) =>
      TeemoResult(Map<String, dynamic>.from(j['raw'] as Map), label: j['label'] as String?);
}
