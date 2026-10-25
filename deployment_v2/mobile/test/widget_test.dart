import 'package:flutter_test/flutter_test.dart';
import 'package:readmitguard/features/home/widgets/sky_scene.dart';
import 'package:readmitguard/features/teemo/data/teemo_models.dart';

void main() {
  group('sky palette', () {
    test('is fully night at midnight and fully day at noon', () {
      expect(nightness(0), 1);
      expect(nightness(12), 0);
    });

    test('blends smoothly through dusk', () {
      final n = nightness(18.5);
      expect(n, greaterThan(0));
      expect(n, lessThan(1));
    });
  });

  group('TeemoResult', () {
    final raw = {
      'id': 'abc',
      'created_at': '2026-10-25T10:00:00+00:00',
      'probability': 0.31,
      'percentage': 31.0,
      'level': 'HIGH',
      'thresholds': {'moderate': 0.08, 'high': 0.2},
      'baseline_rate': 0.1135,
      'relative_risk': 2.73,
      'percentile': 97,
      'band_observed_rate': 0.2543,
      'intervention_recommended': true,
      'drivers': [
        {
          'key': 'visits', 'title': 'Hospital visit history', 'value': '2 inpatient stays',
          'explanation': '...', 'direction': 'up', 'impact': 0.4, 'share': 0.3, 'modifiable': true,
        }
      ],
      'actions': [
        {'icon': 'call', 'title': 'Nurse call', 'detail': '...', 'priority': 'high'}
      ],
      'narrative': [
        {'kind': 'greeting', 'text': "Hi, I'm Teemo."}
      ],
      'patient': {'age': '[70-80)'},
      'defaulted_fields': <String>[],
      'model': {
        'name': 'Teemo',
        'metrics': {
          'roc_auc': 0.6675, 'pr_auc': 0.2226, 'brier': 0.0958, 'baseline_rate': 0.1135,
          'n_test': 19773, 'n_train': 79567, 'n_features': 38, 'pr_lift': 1.96,
        },
      },
    };

    test('parses the API payload', () {
      final r = TeemoResult(raw, label: 'Room 1');
      expect(r.level, 'HIGH');
      expect(r.levelLabel, 'High risk');
      expect(r.drivers.single.up, isTrue);
      expect(r.actions.single.priority, 'high');
      expect(r.narrative.single.kind, 'greeting');
      expect(r.metrics.nTest, 19773);
    });

    test('survives a history round-trip', () {
      final back = TeemoResult.fromJson(TeemoResult(raw, label: 'Room 1').toJson());
      expect(back.label, 'Room 1');
      expect(back.probability, 0.31);
    });
  });
}
