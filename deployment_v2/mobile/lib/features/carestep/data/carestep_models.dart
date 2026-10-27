import 'package:flutter/material.dart';

import '../../avatar/avatar_profile.dart';
import '../../teemo/data/teemo_models.dart';

/// One question of the CareStep form, as described by GET /api/v1/carestep/meta.
class CareStepField {
  const CareStepField({required this.key, required this.label, required this.spec, this.help});

  factory CareStepField.fromJson(String key, Map<String, dynamic> j) => CareStepField(
        key: key,
        label: j['label'] as String? ?? key,
        help: j['help'] as String?,
        spec: FieldSpec.fromJson(j),
      );

  final String key;
  final String label;
  final String? help;
  final FieldSpec spec;

  bool get isChoice => spec.type == 'choice';
  int get min => spec.min ?? 0;
  int get max => spec.max ?? 99;
}

/// Parsed GET /api/v1/carestep/meta.
class CareStepMeta {
  const CareStepMeta({required this.fields, required this.model, required this.hospitalAveragePercent});

  factory CareStepMeta.fromJson(Map<String, dynamic> j) => CareStepMeta(
        fields: {
          for (final e in (j['fields'] as Map<String, dynamic>).entries)
            e.key: CareStepField.fromJson(e.key, e.value as Map<String, dynamic>),
        },
        model: j['model'] as Map<String, dynamic>? ?? const {},
        hospitalAveragePercent: (j['hospital_average_percent'] as num?)?.toInt() ?? 11,
      );

  /// Ordered as the server lists them (the 12 answers).
  final Map<String, CareStepField> fields;
  final Map<String, dynamic> model;
  final int hospitalAveragePercent;

  bool get modelAvailable => model['available'] as bool? ?? true;

  /// The server's defaults, i.e. the starting answers of the form.
  Map<String, Object> get defaults =>
      {for (final f in fields.values) f.key: f.spec.defaultValue};
}

class PlanItem {
  const PlanItem(this.icon, this.text);

  final String icon;
  final String text;

  IconData get iconData => switch (icon) {
        'pill' => Icons.medication_rounded,
        'calendar' => Icons.event_rounded,
        'blood' => Icons.water_drop_rounded,
        'organizer' => Icons.grid_view_rounded,
        'alarm' => Icons.alarm_rounded,
        'lab' => Icons.science_rounded,
        'hospital' => Icons.local_hospital_rounded,
        'phone' => Icons.phone_in_talk_rounded,
        'walk' => Icons.directions_walk_rounded,
        'diet' => Icons.restaurant_rounded,
        'target' => Icons.track_changes_rounded,
        'note' => Icons.edit_note_rounded,
        'progress' => Icons.emoji_events_rounded,
        'alert' => Icons.emergency_rounded,
        _ => Icons.check_circle_outline_rounded,
      };
}

class PlanWeek {
  const PlanWeek({required this.title, required this.subtitle, required this.color, required this.items});

  factory PlanWeek.fromJson(Map<String, dynamic> j) => PlanWeek(
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        color: parseHexColor(j['color'] as String?),
        items: (j['items'] as List? ?? [])
            .cast<Map<String, dynamic>>()
            .map((i) => PlanItem(i['icon'] as String? ?? '', i['text'] as String? ?? ''))
            .toList(),
      );

  final String title;
  final String subtitle;
  final Color color;
  final List<PlanItem> items;
}

/// "#059669" -> Color(0xFF059669); falls back to CareStep blue.
Color parseHexColor(String? hex) {
  final h = (hex ?? '').replaceFirst('#', '');
  final v = int.tryParse(h, radix: 16);
  if (v == null || h.length != 6) return const Color(0xFF3B82F6);
  return Color(0xFF000000 | v);
}

class CareTeamSummary {
  const CareTeamSummary(this.raw);

  final Map<String, dynamic> raw;

  Map<String, dynamic> get profile => raw['profile'] as Map<String, dynamic>? ?? const {};
  List<String> get keyFactors => _strings(raw['key_factors']);
  List<String> get recommendedActions => _strings(raw['recommended_actions']);
  List<String> get questionsForDoctor => _strings(raw['questions_for_doctor']);
  String get summary => raw['summary'] as String? ?? '';
}

List<String> _strings(Object? v) => (v as List? ?? const []).map((e) => '$e').toList();

/// Parsed response of POST /api/v1/carestep/predict.
class CareStepResult {
  const CareStepResult(this.raw);

  final Map<String, dynamic> raw;

  double get probability => (raw['probability'] as num).toDouble();
  int get percent => (raw['percent'] as num? ?? probability * 100).round();
  String get level => raw['level'] as String? ?? 'LOW';
  String get advice => raw['advice'] as String? ?? '';
  int get hospitalAveragePercent => (raw['hospital_average_percent'] as num?)?.toInt() ?? 11;
  List<String> get reasons => _strings(raw['reasons']);
  List<String> get actions => _strings(raw['actions']);
  List<PlanWeek> get plan => (raw['plan'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(PlanWeek.fromJson)
      .toList();
  CareTeamSummary get careTeam =>
      CareTeamSummary(raw['care_team'] as Map<String, dynamic>? ?? const {});
  List<SpeechSegment> get narrative => (raw['narrative'] as List? ?? [])
      .cast<Map<String, dynamic>>()
      .map(SpeechSegment.fromJson)
      .toList();

  bool get aboveAverage => percent > hospitalAveragePercent;

  /// Plain-language level name.
  String get levelLabel => switch (level) {
        'HIGH' => 'High risk',
        'MEDIUM' => 'Medium risk',
        _ => 'Low risk',
      };

  /// Level colour, using the app's shared level palette (MEDIUM = MODERATE).
  String get paletteLevel => level == 'MEDIUM' ? 'MODERATE' : level;
}
