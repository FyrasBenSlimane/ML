import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../data/teemo_models.dart';
import '../data/teemo_repository.dart';

enum FormStatus { loading, ready, error }

class AssessmentState extends Equatable {
  const AssessmentState({
    this.status = FormStatus.loading,
    this.meta,
    this.values = const {},
    this.step = 0,
    this.label = '',
    this.error,
    this.sampleLabel,
  });

  final FormStatus status;
  final TeemoMeta? meta;

  /// Raw field values exactly as the API expects them.
  final Map<String, dynamic> values;
  final int step;
  final String label;
  final String? error;

  /// Which demo patient (if any) is currently loaded.
  final String? sampleLabel;

  static const steps = ['Patient', 'Admission', 'Clinical', 'History', 'Medication'];

  Object? operator [](String field) => values[field];

  AssessmentState copyWith({
    FormStatus? status,
    TeemoMeta? meta,
    Map<String, dynamic>? values,
    int? step,
    String? label,
    String? error,
    String? sampleLabel,
    bool clearSample = false,
  }) =>
      AssessmentState(
        status: status ?? this.status,
        meta: meta ?? this.meta,
        values: values ?? this.values,
        step: step ?? this.step,
        label: label ?? this.label,
        error: error ?? this.error,
        sampleLabel: clearSample ? null : (sampleLabel ?? this.sampleLabel),
      );

  @override
  List<Object?> get props => [status, meta, values, step, label, error, sampleLabel];
}

class AssessmentCubit extends Cubit<AssessmentState> {
  AssessmentCubit(this._repo) : super(const AssessmentState()) {
    load();
  }

  final TeemoRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: FormStatus.loading));
    try {
      final meta = await _repo.meta();
      emit(state.copyWith(status: FormStatus.ready, meta: meta, values: _initial(meta)));
    } on ApiException catch (e) {
      emit(state.copyWith(status: FormStatus.error, error: e.message));
    }
  }

  Map<String, dynamic> _initial(TeemoMeta meta) {
    final v = Map<String, dynamic>.from(meta.defaults);
    // Let the server derive it from the medications the nurse actually picks.
    v.remove('diabetesMed');
    return v;
  }

  void set(String field, Object value) {
    emit(state.copyWith(values: {...state.values, field: value}, clearSample: true));
  }

  void setLabel(String label) => emit(state.copyWith(label: label));

  void loadSample(SamplePatient s) {
    final v = {..._initial(state.meta!), ...s.patient}..remove('diabetesMed');
    emit(state.copyWith(values: v, sampleLabel: s.label, label: s.label, step: 0));
  }

  void reset() {
    if (state.meta == null) return;
    emit(AssessmentState(status: FormStatus.ready, meta: state.meta, values: _initial(state.meta!)));
  }

  void goTo(int step) =>
      emit(state.copyWith(step: step.clamp(0, AssessmentState.steps.length - 1)));

  void next() => goTo(state.step + 1);

  void back() => goTo(state.step - 1);
}
