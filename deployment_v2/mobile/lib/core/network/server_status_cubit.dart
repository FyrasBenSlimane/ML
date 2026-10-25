import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'api_client.dart';

enum ServerHealth { checking, online, offline }

class ServerStatus extends Equatable {
  const ServerStatus(this.health, {this.modules = const [], this.message});

  final ServerHealth health;

  /// Module ids the backend has mounted (e.g. ["teemo"]).
  final List<String> modules;
  final String? message;

  bool hasModule(String id) => modules.contains(id);

  @override
  List<Object?> get props => [health, modules, message];
}

/// Polls /health so every screen can show a live "online" indicator.
class ServerStatusCubit extends Cubit<ServerStatus> {
  ServerStatusCubit(this._api) : super(const ServerStatus(ServerHealth.checking)) {
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => refresh(silent: true));
  }

  final ApiClient _api;
  Timer? _timer;

  Future<void> refresh({bool silent = false}) async {
    if (!silent) emit(const ServerStatus(ServerHealth.checking));
    try {
      final body = await _api.getJson('/health', timeout: const Duration(seconds: 5));
      final modules = (body['modules'] as List? ?? []).cast<String>();
      if (!isClosed) emit(ServerStatus(ServerHealth.online, modules: modules));
    } on ApiException catch (e) {
      if (!isClosed) emit(ServerStatus(ServerHealth.offline, message: e.message));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
