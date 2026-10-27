import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readmitguard/core/network/api_client.dart';
import 'package:readmitguard/core/patient/active_patient_cubit.dart';
import 'package:readmitguard/features/carestep/carestep_screen.dart';
import 'package:readmitguard/features/carestep/data/carestep_models.dart';
import 'package:readmitguard/features/carestep/screens/carestep_result_screen.dart';

const _meta = {
  'model': {'name': 'CareStep', 'available': true},
  'hospital_average_percent': 11,
  'fields': {
    'age': {
      'label': 'Your age range',
      'type': 'choice',
      'default': 6,
      'options': [
        {'value': 6, 'label': '60-70'},
        {'value': 7, 'label': '70-80'},
      ],
    },
    'gender': {
      'label': 'Gender',
      'type': 'choice',
      'default': 'Female',
      'options': [
        {'value': 'Female', 'label': 'Female'},
        {'value': 'Male', 'label': 'Male'},
      ],
    },
    'time_hosp': {'label': 'Days spent in hospital this stay', 'type': 'int', 'min': 1, 'max': 14, 'default': 5},
    'inpatient': {
      'label': 'Hospital stays in the past year',
      'type': 'int',
      'min': 0,
      'max': 10,
      'default': 0,
      'help': 'How many times you were admitted as an inpatient',
    },
  },
};

final _result = <String, dynamic>{
  'probability': 0.27,
  'percent': 27,
  'level': 'HIGH',
  'advice': 'Your risk is elevated.',
  'hospital_average_percent': 11,
  'reasons': ['Insulin therapy requires careful monitoring after discharge'],
  'actions': ['Book a follow-up appointment within 7 days of discharge'],
  'plan': [
    {
      'title': 'Week 1 — Intensive Phase',
      'subtitle': 'Days 1–7',
      'color': '#059669',
      'items': [
        {'icon': 'pill', 'text': 'Take all medications exactly as prescribed'},
      ],
    },
  ],
  'care_team': {
    'profile': {'age_range': '60-70', 'gender': 'Female'},
    'key_factors': <String>[],
    'recommended_actions': ['Urgent follow-up within 48 hours of discharge'],
    'questions_for_doctor': ['What warning signs should I watch for at home?'],
    'summary': 'Patient at HIGH risk.',
  },
  'narrative': [
    {'kind': 'greeting', 'text': "Hi, I'm CareStep."},
  ],
};

Widget _wrap(Widget child, {ApiClient? api}) => RepositoryProvider.value(
      value: api ?? ApiClient(() => 'http://test'),
      child: BlocProvider(
        create: (_) => ActivePatientCubit(),
        child: MaterialApp(home: child),
      ),
    );

void main() {
  group('CareStep models', () {
    test('parses meta and its defaults', () {
      final m = CareStepMeta.fromJson(_meta);
      expect(m.fields.keys, ['age', 'gender', 'time_hosp', 'inpatient']);
      expect(m.defaults, {'age': 6, 'gender': 'Female', 'time_hosp': 5, 'inpatient': 0});
      expect(m.fields['inpatient']!.help, isNotNull);
      expect(m.fields['age']!.spec.labelFor(7), '70-80');
    });

    test('parses the predict payload', () {
      final r = CareStepResult(_result);
      expect(r.levelLabel, 'High risk');
      expect(r.paletteLevel, 'HIGH');
      expect(r.aboveAverage, isTrue);
      expect(r.plan.single.color, const Color(0xFF059669));
      expect(r.plan.single.items.single.iconData, Icons.medication_rounded);
      expect(r.careTeam.recommendedActions, hasLength(1));
      expect(r.narrative.single.kind, 'greeting');
    });
  });

  testWidgets('questionnaire renders the fields loaded from /meta', (tester) async {
    final api = ApiClient(() => 'http://test',
        client: MockClient((req) async => http.Response(jsonEncode(_meta), 200)));
    await tester.pumpWidget(_wrap(const CareStepScreen(), api: api));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Your age range'), findsOneWidget);
    expect(find.text('Check the recovery risk'), findsOneWidget);
  });

  testWidgets('questionnaire shows the server error with a retry', (tester) async {
    final api = ApiClient(() => 'http://test',
        client: MockClient((req) async => http.Response('{"detail":"boom"}', 503)));
    await tester.pumpWidget(_wrap(const CareStepScreen(), api: api));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('result screen shows level, plan and care team', (tester) async {
    tester.view.physicalSize = const Size(1200, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(CareStepResultScreen(result: CareStepResult(_result))));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('HIGH RISK'), findsOneWidget);
    expect(find.text('Week 1 — Intensive Phase'), findsOneWidget);
    expect(find.text('Care-team summary'), findsOneWidget);
  });
}
