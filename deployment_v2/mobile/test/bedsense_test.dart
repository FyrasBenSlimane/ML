import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readmitguard/features/bedsense/data/bedsense_models.dart';
import 'package:readmitguard/features/bedsense/widgets/bed_load_chart.dart';

Map<String, dynamic> _day(String date, double needed, String status) => {
      'date': date,
      'current_patients': 120,
      'new_patients': 30,
      'expected_returns': 10.5,
      'beds_needed': needed,
      'beds_safe': needed + 6,
      'capacity': 200,
      'free_beds': (200 - needed).round(),
      'occupancy': needed / 200,
      'status': status,
      'nurses_needed': 31,
      'nurses_on_duty': 32,
    };

void main() {
  test('meta fields keep order and map the "no answer" option', () {
    final meta = BsMeta({
      'fields': {
        'age': {
          'type': 'choice',
          'default': '[60-70)',
          'options': ['[50-60)', '[60-70)'],
          'labels': {'[50-60)': '50-60 years', '[60-70)': '60-70 years'},
          'help': 'Age',
        },
        'race': {
          'type': 'choice',
          'default': null,
          'options': [null, 'Asian'],
          'labels': {'None': 'Prefer not to say'},
          'help': 'Background (optional)',
        },
        'time_in_hospital': {'type': 'number', 'default': 4, 'min': 1, 'max': 14, 'help': 'Days'},
      },
      'services': ['Surgery'],
    });
    expect(meta.fields.keys, ['age', 'race', 'time_in_hospital']);
    expect(meta.fields['race']!.defaultValue, bsNone);
    expect(meta.fields['race']!.options.first.label, 'Prefer not to say');
    expect(meta.fields['age']!.spec.labelFor('[60-70)'), '60-70 years');
    expect(meta.fields['time_in_hospital']!.isNumber, isTrue);
    expect(meta.services, ['Surgery']);
  });

  test('prediction and plan payloads parse, nulls tolerated', () {
    final p = BsPrediction({
      'probability': 0.094,
      'percent': 9,
      'level': 'low',
      'level_label': 'Low risk',
      'stay': {'q10': 1.8, 'q90': 9.6, 'likely_days': 4, 'range_text': '2 to 10 days'},
      'bed_days': 0.49,
      'facts': ['15 medicines during this stay'],
      'narrative': [
        {'kind': 'greeting', 'text': 'Hi'},
      ],
    });
    expect(p.likelyDays, 4);
    expect(p.rangeText, '2 to 10 days');
    expect(p.narrative.single.kind, 'greeting');

    final plan = BsPlan({
      'summary': {'beds_needed_today': 183, 'free_beds_today': 17, 'capacity': 200, 'first_critical': null},
      'days': [_day('2026-10-27', 183.5, 'tight')],
      'alerts': [
        {'severity': 'over', 'title': 'Mon 09 Nov: about 3 beds missing', 'action': 'Consider: open 3 extra beds.'},
      ],
      'weeks': [],
    });
    expect(plan.capacity, 200);
    expect(plan.days.single.date, DateTime(2026, 10, 27));
    expect(plan.alerts.single.severity, 'over');
  });

  testWidgets('bed load chart paints and reports taps', (tester) async {
    final days = [
      for (var i = 0; i < 14; i++)
        BsDay(_day('2026-11-${(i + 1).toString().padLeft(2, '0')}', 170.0 + i * 3, i > 10 ? 'over' : 'ok')),
    ];
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 360,
          child: BedLoadChart(days: days, onSelect: (i) => tapped = i),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(CustomPaint), findsWidgets);
    await tester.tapAt(tester.getTopRight(find.byType(BedLoadChart)) + const Offset(-4, 60));
    expect(tapped, 13);
  });
}
