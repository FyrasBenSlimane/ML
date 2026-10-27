import '../../avatar/avatar_profile.dart';
import '../../teemo/data/teemo_models.dart';

/// Lenient readers: the backend turns NaN into null, so every number may be missing.
double _d(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
int _i(Object? v, [int fallback = 0]) => v is num ? v.round() : fallback;
String _s(Object? v, [String fallback = '']) => v == null ? fallback : '$v';
List<String> _strings(Object? v) => (v as List? ?? const []).map((e) => '$e').toList();
Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? v) =>
    (v as List? ?? const []).whereType<Map>().map(Map<String, dynamic>.from).toList();

List<SpeechSegment> _narrative(Object? v) => _maps(v).map(SpeechSegment.fromJson).toList();

/// Value used in the form for "no answer" (FieldOption values cannot be null).
const bsNone = '__none__';

/// One input of the "Check a patient" form, as described by GET /bedsense/meta.
class BsField {
  BsField({
    required this.key,
    required this.type,
    required this.defaultValue,
    required this.options,
    required this.help,
    this.min = 0,
    this.max = 0,
  });

  factory BsField.fromJson(String key, Map<String, dynamic> j) {
    final labels = _map(j['labels']);
    String label(Object? v) {
      final k = v == null ? 'None' : '$v';
      return labels[k]?.toString() ?? (v == null ? 'Not given' : '$v');
    }

    return BsField(
      key: key,
      type: _s(j['type'], 'choice'),
      defaultValue: j['default'] ?? bsNone,
      options: (j['options'] as List? ?? const [])
          .map((o) => FieldOption(o ?? bsNone, label(o)))
          .toList(),
      help: _s(j['help'], key),
      min: _i(j['min']),
      max: _i(j['max']),
    );
  }

  final String key;
  final String type; // "choice" | "number"
  final Object defaultValue;
  final List<FieldOption> options;
  final String help;
  final int min;
  final int max;

  bool get isNumber => type == 'number';

  FieldSpec get spec => FieldSpec(
        type: type,
        defaultValue: defaultValue,
        options: options,
        min: min,
        max: max,
      );
}

class BsMeta {
  BsMeta(this.raw)
      : fields = {
          for (final e in _map(raw['fields']).entries)
            e.key: BsField.fromJson(e.key, _map(e.value)),
        },
        services = _strings(raw['services']);

  final Map<String, dynamic> raw;
  final Map<String, BsField> fields;
  final List<String> services;

  Map<String, dynamic> get config => _map(raw['config']);
  String get disclaimer => _s(raw['disclaimer']);
  String get placeholderNote => _s(config['placeholder_note']);
}

/// Response of POST /bedsense/predict.
class BsPrediction {
  BsPrediction(this.raw);

  final Map<String, dynamic> raw;

  double get probability => _d(raw['probability']);
  int get percent => _i(raw['percent']);
  String get level => _s(raw['level'], 'low');
  String get levelLabel => _s(raw['level_label'], 'Risk');
  double get riskRank => _d(raw['risk_rank']);
  Map<String, dynamic> get _stay => _map(raw['stay']);
  int get likelyDays => _i(_stay['likely_days'], 1);
  double get stayLow => _d(_stay['q10']);
  double get stayHigh => _d(_stay['q90']);
  String get rangeText => _s(_stay['range_text']);
  double get bedDays => _d(raw['bed_days']);
  String get headline => _s(raw['headline']);
  String get sentence => _s(raw['sentence']);
  String get staySentence => _s(raw['stay_sentence']);
  String get advice => _s(raw['advice']);
  List<String> get facts => _strings(raw['facts']);
  String get arrival => _s(raw['arrival']);
  String get leavingTo => _s(raw['leaving_to']);
  String get disclaimer => _s(raw['disclaimer']);
  List<SpeechSegment> get narrative => _narrative(raw['narrative']);
}

class BsDay {
  BsDay(Map<String, dynamic> j)
      : date = DateTime.tryParse(_s(j['date'])) ?? DateTime.now(),
        needed = _d(j['beds_needed']),
        safe = _d(j['beds_safe']),
        capacity = _d(j['capacity']),
        freeBeds = _i(j['free_beds']),
        occupancy = _d(j['occupancy']),
        status = _s(j['status'], 'ok'),
        current = _d(j['current_patients']),
        newPatients = _d(j['new_patients']),
        returns = _d(j['expected_returns']),
        nursesNeeded = _i(j['nurses_needed']),
        nursesOnDuty = _i(j['nurses_on_duty']);

  final DateTime date;
  final double needed;
  final double safe;
  final double capacity;
  final int freeBeds;
  final double occupancy;
  final String status; // ok | tight | over
  final double current;
  final double newPatients;
  final double returns;
  final int nursesNeeded;
  final int nursesOnDuty;
}

class BsWeek {
  BsWeek(Map<String, dynamic> j)
      : label = _s(j['label']),
        start = DateTime.tryParse(_s(j['start'])),
        end = DateTime.tryParse(_s(j['end'])),
        peakBeds = _i(j['peak_beds']),
        capacity = _i(j['capacity']),
        margin = _i(j['margin']),
        criticalDays = _i(j['critical_days']),
        tightDays = _i(j['tight_days']);

  final String label;
  final DateTime? start;
  final DateTime? end;
  final int peakBeds;
  final int capacity;
  final int margin;
  final int criticalDays;
  final int tightDays;
}

class BsAlert {
  BsAlert(Map<String, dynamic> j)
      : severity = _s(j['severity'], 'tight'),
        title = _s(j['title']),
        action = _s(j['action']),
        shortfall = _i(j['shortfall']);

  final String severity; // over | tight
  final String title;
  final String action;
  final int shortfall;
}

/// Response of GET /bedsense/plan.
class BsPlan {
  BsPlan(this.raw)
      : days = _maps(raw['days']).map(BsDay.new).toList(),
        weeks = _maps(raw['weeks']).map(BsWeek.new).toList(),
        alerts = _maps(raw['alerts']).map(BsAlert.new).toList();

  final Map<String, dynamic> raw;
  final List<BsDay> days;
  final List<BsWeek> weeks;
  final List<BsAlert> alerts;

  Map<String, dynamic> get summary => _map(raw['summary']);
  int get bedsNeededToday => _i(summary['beds_needed_today']);
  int get freeBedsToday => _i(summary['free_beds_today']);
  int get capacity => _i(summary['capacity']);
  int get highRiskPatients => _i(summary['high_risk_patients']);
  int get criticalDays => _i(summary['critical_days']);
  int get tightDays => _i(summary['tight_days']);
  int get horizon => _i(raw['horizon'], days.length);
  String get safeBandText => _s(_map(raw['safe_band'])['text']);
  int get nursesPerShift => _i(_map(raw['capacity'])['nurses_per_shift']);
  String get disclaimer => _s(raw['disclaimer']);
  List<SpeechSegment> get narrative => _narrative(raw['narrative']);
}

class BsPatient {
  BsPatient(Map<String, dynamic> j)
      : pid = _s(j['pid']),
        where = _s(j['where']),
        when = _s(j['when']),
        ageBand = _s(j['age_band']),
        gender = _s(j['gender']),
        service = _s(j['service']),
        mainReason = _s(j['main_reason']),
        percent = _i(j['percent']),
        level = _s(j['level'], 'low'),
        stayLikely = _i(j['stay_likely'], 1),
        stayText = _s(j['stay_text']),
        bedDays = _d(j['bed_days']),
        advice = _s(j['advice']),
        headline = _s(j['headline']),
        sentence = _s(j['sentence']),
        staySentence = _s(j['stay_sentence']),
        facts = _strings(j['facts']),
        arrival = _s(j['arrival']),
        leavingTo = _s(j['leaving_to']);

  final String pid;
  final String where;
  final String when;
  final String ageBand;
  final String gender;
  final String service;
  final String mainReason;
  final int percent;
  final String level;
  final int stayLikely;
  final String stayText;
  final double bedDays;
  final String advice;
  final String headline;
  final String sentence;
  final String staySentence;
  final List<String> facts;
  final String arrival;
  final String leavingTo;
}

/// Response of GET /bedsense/followup.
class BsFollowup {
  BsFollowup(this.raw) : patients = _maps(raw['patients']).map(BsPatient.new).toList();

  final Map<String, dynamic> raw;
  final List<BsPatient> patients;

  int get total => _i(raw['total']);
  int get shown => _i(raw['shown'], patients.length);
  int countFor(String level) => _i(_map(raw['by_level'])[level]);
  String get disclaimer => _s(raw['disclaimer']);
}
