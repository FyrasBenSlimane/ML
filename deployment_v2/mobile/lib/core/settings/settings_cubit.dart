import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VoiceEngine { neural, device }

class AppSettings extends Equatable {
  const AppSettings({
    required this.serverUrl,
    this.voiceEngine = VoiceEngine.neural,
    this.userName = '',
    this.subtitles = true,
  });

  /// Where the FastAPI backend runs.
  /// * Chrome / Windows on the same PC -> http://localhost:8000
  /// * Android emulator              -> http://10.0.2.2:8000 (the host PC)
  /// * Real phone                     -> `http://<PC Wi-Fi IP>:8000`
  final String serverUrl;
  final VoiceEngine voiceEngine;
  final String userName;
  final bool subtitles;

  static String get defaultServerUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  AppSettings copyWith({
    String? serverUrl,
    VoiceEngine? voiceEngine,
    String? userName,
    bool? subtitles,
  }) =>
      AppSettings(
        serverUrl: serverUrl ?? this.serverUrl,
        voiceEngine: voiceEngine ?? this.voiceEngine,
        userName: userName ?? this.userName,
        subtitles: subtitles ?? this.subtitles,
      );

  @override
  List<Object?> get props => [serverUrl, voiceEngine, userName, subtitles];
}

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._prefs, AppSettings initial) : super(initial);

  final SharedPreferences _prefs;

  static Future<SettingsCubit> create() async {
    final prefs = await SharedPreferences.getInstance();
    final initial = AppSettings(
      serverUrl: prefs.getString('serverUrl') ?? AppSettings.defaultServerUrl,
      voiceEngine: VoiceEngine.values.asNameMap()[prefs.getString('voiceEngine')] ??
          VoiceEngine.neural,
      userName: prefs.getString('userName') ?? '',
      subtitles: prefs.getBool('subtitles') ?? true,
    );
    return SettingsCubit(prefs, initial);
  }

  void setServerUrl(String url) {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    if (!clean.startsWith('http')) clean = 'http://$clean';
    _prefs.setString('serverUrl', clean);
    emit(state.copyWith(serverUrl: clean));
  }

  void setVoiceEngine(VoiceEngine engine) {
    _prefs.setString('voiceEngine', engine.name);
    emit(state.copyWith(voiceEngine: engine));
  }

  void setUserName(String name) {
    _prefs.setString('userName', name.trim());
    emit(state.copyWith(userName: name.trim()));
  }

  void setSubtitles(bool on) {
    _prefs.setBool('subtitles', on);
    emit(state.copyWith(subtitles: on));
  }
}
