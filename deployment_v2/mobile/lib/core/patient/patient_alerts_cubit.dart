import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/api_client.dart';

/// One benevolent alert a doctor sent to this patient. It never carries a model
/// result — only the message the doctor chose to share.
class PatientAlert extends Equatable {
  const PatientAlert({
    required this.id,
    required this.module,
    required this.niveau,
    required this.titre,
    required this.message,
    required this.lu,
    required this.medecin,
    required this.createdAt,
  });

  factory PatientAlert.fromJson(Map<String, dynamic> j) => PatientAlert(
        id: (j['id'] as num).toInt(),
        module: j['module'] as String? ?? '',
        niveau: j['niveau'] as String? ?? 'info',
        titre: j['titre'] as String? ?? '',
        message: j['message'] as String? ?? '',
        lu: j['lu'] as bool? ?? false,
        medecin: j['medecin'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
      );

  final int id;
  final String module;
  final String niveau;
  final String titre;
  final String message;
  final bool lu;
  final String medecin;
  final DateTime createdAt;

  PatientAlert copyWith({bool? lu}) => PatientAlert(
        id: id,
        module: module,
        niveau: niveau,
        titre: titre,
        message: message,
        lu: lu ?? this.lu,
        medecin: medecin,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, lu];
}

enum AlertsStatus { loading, ready, error }

class PatientAlertsState extends Equatable {
  const PatientAlertsState({
    this.status = AlertsStatus.loading,
    this.alerts = const [],
    this.error,
  });

  final AlertsStatus status;
  final List<PatientAlert> alerts;
  final String? error;

  int get unread => alerts.where((a) => !a.lu).length;

  PatientAlertsState copyWith(
          {AlertsStatus? status, List<PatientAlert>? alerts, String? error}) =>
      PatientAlertsState(
        status: status ?? this.status,
        alerts: alerts ?? this.alerts,
        error: error,
      );

  @override
  List<Object?> get props => [status, alerts, error];
}

class PatientAlertsCubit extends Cubit<PatientAlertsState> {
  PatientAlertsCubit(this._api) : super(const PatientAlertsState());

  final ApiClient _api;

  Future<void> load() async {
    emit(state.copyWith(status: AlertsStatus.loading));
    try {
      final list = await _api.getList('/api/v1/notifications');
      final alerts = list
          .cast<Map<String, dynamic>>()
          .map(PatientAlert.fromJson)
          .toList();
      emit(state.copyWith(status: AlertsStatus.ready, alerts: alerts));
    } on ApiException catch (e) {
      emit(state.copyWith(status: AlertsStatus.error, error: e.message));
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.postJson('/api/v1/notifications/$id/read', const {});
      final updated = [
        for (final a in state.alerts) a.id == id ? a.copyWith(lu: true) : a,
      ];
      emit(state.copyWith(status: AlertsStatus.ready, alerts: updated));
    } on ApiException {
      // Keep the list as-is; the badge simply stays until the next refresh.
    }
  }
}
