import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../../core/settings/settings_cubit.dart';
import '../avatar_profile.dart';
import 'speech_engines.dart';

enum VoiceStatus { idle, loading, speaking, paused, finished, error }

class AvatarVoiceState extends Equatable {
  const AvatarVoiceState({
    required this.segments,
    this.index = 0,
    this.charEnd = 0,
    this.status = VoiceStatus.idle,
    this.notice,
  });

  final List<SpeechSegment> segments;
  final int index;

  /// Character offset reached in the current segment (drives the karaoke).
  final int charEnd;
  final VoiceStatus status;

  /// One-off message, e.g. "switched to device voice".
  final String? notice;

  SpeechSegment get current => segments[index];

  /// The avatar should be moving while a line is playing or about to play.
  bool get isAnimating => status == VoiceStatus.speaking || status == VoiceStatus.loading;

  AvatarVoiceState copyWith({
    int? index,
    int? charEnd,
    VoiceStatus? status,
    String? notice,
    bool clearNotice = false,
  }) =>
      AvatarVoiceState(
        segments: segments,
        index: index ?? this.index,
        charEnd: charEnd ?? this.charEnd,
        status: status ?? this.status,
        notice: clearNotice ? null : (notice ?? this.notice),
      );

  @override
  List<Object?> get props => [segments, index, charEnd, status, notice];
}

/// Plays an avatar's script line by line.
///
/// Every playback loop carries a generation number; skipping, pausing or
/// closing bumps it, so a stale loop that wakes up later simply exits.
class AvatarVoiceCubit extends Cubit<AvatarVoiceState> {
  AvatarVoiceCubit({
    required List<SpeechSegment> segments,
    required ApiClient api,
    required VoiceEngine preferred,
  }) : _engine = preferred == VoiceEngine.neural ? NeuralSpeechEngine(api) : DeviceSpeechEngine(),
        super(AvatarVoiceState(segments: segments)) {
    if (segments.isNotEmpty) _engine.prefetch(segments.first.text);
  }

  SpeechEngine _engine;
  int _generation = 0;
  bool _pausedInPlace = false;

  bool get usingDeviceVoice => _engine is DeviceSpeechEngine;

  void start() => _run(0);

  Future<void> togglePlay() async {
    switch (state.status) {
      case VoiceStatus.speaking:
      case VoiceStatus.loading:
        if (_engine.canPauseInPlace && state.status == VoiceStatus.speaking) {
          _pausedInPlace = true;
          await _engine.pause();
        } else {
          _pausedInPlace = false;
          _generation++;
          await _engine.stop();
        }
        emit(state.copyWith(status: VoiceStatus.paused));
      case VoiceStatus.paused:
        if (_pausedInPlace) {
          _pausedInPlace = false;
          await _engine.resume();
          emit(state.copyWith(status: VoiceStatus.speaking));
        } else {
          _run(state.index);
        }
      case VoiceStatus.idle:
      case VoiceStatus.finished:
      case VoiceStatus.error:
        _run(0);
    }
  }

  Future<void> next() => _jump(state.index + 1);

  Future<void> previous() => _jump(state.index - 1);

  Future<void> restart() => _jump(0);

  Future<void> _jump(int to) async {
    if (state.segments.isEmpty) return;
    _generation++;
    _pausedInPlace = false;
    await _engine.stop();
    _run(to.clamp(0, state.segments.length - 1));
  }

  Future<void> _run(int from) async {
    final gen = ++_generation;
    _pausedInPlace = false;
    for (var i = from; i < state.segments.length; i++) {
      if (gen != _generation || isClosed) return;
      emit(state.copyWith(index: i, charEnd: 0, status: VoiceStatus.loading));
      if (i + 1 < state.segments.length) _engine.prefetch(state.segments[i + 1].text);
      try {
        await _engine.speak(
          state.segments[i].text,
          onStart: () {
            if (gen == _generation && !isClosed) {
              emit(state.copyWith(status: VoiceStatus.speaking));
            }
          },
          onProgress: (c) {
            if (gen == _generation && !isClosed && c >= state.charEnd) {
              emit(state.copyWith(charEnd: c));
            }
          },
        );
      } catch (_) {
        if (gen != _generation || isClosed) return;
        if (_engine is NeuralSpeechEngine) {
          // Server voice unavailable (offline / no internet on the server):
          // carry on with the device's female voice from the same line.
          _engine.dispose();
          _engine = DeviceSpeechEngine();
          emit(state.copyWith(notice: 'Server voice unavailable — using the device voice'));
          i--;
          continue;
        }
        emit(state.copyWith(status: VoiceStatus.error, notice: 'Voice playback failed'));
        return;
      }
      if (gen != _generation || isClosed) return;
      await Future<void>.delayed(const Duration(milliseconds: 380));
    }
    if (gen == _generation && !isClosed) {
      emit(state.copyWith(status: VoiceStatus.finished, charEnd: state.current.text.length));
    }
  }

  void clearNotice() => emit(state.copyWith(clearNotice: true));

  @override
  Future<void> close() {
    _generation++;
    _engine.dispose();
    return super.close();
  }
}
