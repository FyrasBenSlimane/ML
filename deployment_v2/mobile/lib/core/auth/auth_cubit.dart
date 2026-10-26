import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// A signed-in account. The patient [code] (e.g. "PT-00042") is what a doctor
/// types to evaluate someone; a patient sees it on their profile.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.role,
    required this.code,
  });

  factory AuthUser.fromJson(Map<String, dynamic> j) => AuthUser(
        id: (j['id'] as num).toInt(),
        prenom: j['prenom'] as String? ?? '',
        nom: j['nom'] as String? ?? '',
        email: j['email'] as String? ?? '',
        role: j['role'] as String? ?? 'patient',
        code: j['code'] as String? ?? '',
      );

  final int id;
  final String prenom;
  final String nom;
  final String email;
  final String role;
  final String code;

  bool get isMedecin => role == 'medecin';
  String get fullName => '$prenom $nom'.trim();

  Map<String, dynamic> toJson() =>
      {'id': id, 'prenom': prenom, 'nom': nom, 'email': email, 'role': role, 'code': code};

  @override
  List<Object?> get props => [id, prenom, nom, email, role, code];
}

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.token});

  final AuthStatus status;
  final AuthUser? user;
  final String? token;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  @override
  List<Object?> get props => [status, user, token];
}

/// Holds the session, persists it in shared_preferences and keeps the shared
/// [ApiClient] stamped with the current bearer token.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit._(this._api, this._prefs, super.initial);

  final ApiClient _api;
  final SharedPreferences _prefs;

  static const _kToken = 'authToken';
  static const _kUser = 'authUser';

  /// Rebuilds the session from disk so a returning user stays logged in.
  factory AuthCubit.restore(ApiClient api, SharedPreferences prefs) {
    final token = prefs.getString(_kToken);
    final userRaw = prefs.getString(_kUser);
    if (token != null && userRaw != null) {
      api.authToken = token;
      final user = AuthUser.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
      return AuthCubit._(api, prefs,
          AuthState(status: AuthStatus.authenticated, user: user, token: token));
    }
    return AuthCubit._(api, prefs, const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> register({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    required String role,
    String? code,
  }) async {
    final body = {
      'prenom': prenom,
      'nom': nom,
      'email': email,
      'password': password,
      'role': role,
      if (code != null && code.isNotEmpty) 'code': code,
    };
    await _save(await _api.postJson('/api/v1/auth/register', body));
  }

  Future<void> login(String email, String password) async {
    await _save(await _api.postJson('/api/v1/auth/login',
        {'email': email, 'password': password}));
  }

  Future<void> _save(Map<String, dynamic> res) async {
    final token = res['token'] as String;
    final user = AuthUser.fromJson(res['user'] as Map<String, dynamic>);
    _api.authToken = token;
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    emit(AuthState(status: AuthStatus.authenticated, user: user, token: token));
  }

  Future<void> logout() async {
    _api.authToken = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
