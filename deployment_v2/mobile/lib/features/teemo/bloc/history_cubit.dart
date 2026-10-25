import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/teemo_models.dart';

/// Past Teemo assessments, newest first, persisted on the device.
class HistoryCubit extends Cubit<List<TeemoResult>> {
  HistoryCubit() : super(const []) {
    _load();
  }

  static const _key = 'teemo_history_v1';
  static const _max = 40;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final items = <TeemoResult>[];
    for (final s in prefs.getStringList(_key) ?? const <String>[]) {
      try {
        items.add(TeemoResult.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // Skip entries written by an older, incompatible version.
      }
    }
    if (!isClosed) emit(items);
  }

  Future<void> add(TeemoResult r) async {
    final next = [r, ...state.where((e) => e.id != r.id)].take(_max).toList();
    emit(next);
    await _save(next);
  }

  Future<void> remove(String id) async {
    final next = state.where((e) => e.id != id).toList();
    emit(next);
    await _save(next);
  }

  Future<void> clear() async {
    emit(const []);
    await _save(const []);
  }

  Future<void> _save(List<TeemoResult> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items.map((e) => jsonEncode(e.toJson())).toList());
  }
}
