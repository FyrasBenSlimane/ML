import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:readmitguard/features/teemo/data/teemo_models.dart';

/// Parses real server responses captured from the backend.
void main() {
  test('meta fixture parses', () {
    final j = jsonDecode(File('test/meta_fixture.json').readAsStringSync());
    final meta = TeemoMeta.fromJson(j as Map<String, dynamic>);
    expect(meta.samples, hasLength(3));
    expect(meta.fields['age']!.options, isNotEmpty);
    expect(meta.metrics.nTest, greaterThan(1000));
    expect(meta.bands['HIGH'], greaterThan(meta.bands['LOW']!));
  });

  test('predict fixture parses', () {
    final j = jsonDecode(File('test/predict_fixture.json').readAsStringSync());
    final r = TeemoResult(j as Map<String, dynamic>);
    expect(r.drivers, isNotEmpty);
    expect(r.narrative.first.kind, 'greeting');
    expect(r.createdAt.year, greaterThan(2000));
  });
}
