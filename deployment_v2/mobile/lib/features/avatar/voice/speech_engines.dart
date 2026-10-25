import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/network/api_client.dart';

/// Speaks one piece of text and reports how far it got (character offset), so
/// the subtitle bar can highlight words in sync with the voice.
abstract class SpeechEngine {
  /// Completes when the text has been spoken or [stop] was called.
  /// [onStart] fires when sound actually begins (after any download).
  Future<void> speak(String text,
      {required void Function() onStart, required void Function(int charEnd) onProgress});

  /// Warm up the next line while the current one plays.
  void prefetch(String text) {}

  bool get canPauseInPlace;
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  void dispose();
}

// ----------------------------------------------------------------- neural
/// Female neural voice synthesized by the backend (/api/v1/tts, edge-tts).
class NeuralSpeechEngine extends SpeechEngine {
  NeuralSpeechEngine(this._api);

  final ApiClient _api;
  final AudioPlayer _player = AudioPlayer();
  final Map<String, Future<_Clip>> _clips = {};
  Completer<void>? _done;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<void>? _endSub;

  Future<_Clip> _clip(String text) {
    return _clips.putIfAbsent(text, () async {
      try {
        final body = await _api.postJson('/api/v1/tts', {'text': text},
            timeout: const Duration(seconds: 20));
        return _Clip.fromJson(body, text, _api.baseUrl);
      } catch (_) {
        _clips.remove(text); // allow a retry later
        rethrow;
      }
    });
  }

  @override
  void prefetch(String text) => _clip(text).ignore();

  @override
  Future<void> speak(String text,
      {required void Function() onStart, required void Function(int) onProgress}) async {
    final clip = await _clip(text);
    await _cleanup();
    final done = _done = Completer<void>();
    _posSub = _player.onPositionChanged
        .listen((pos) => onProgress(clip.charEndAt(pos.inMilliseconds)));
    _endSub = _player.onPlayerComplete.listen((_) {
      onProgress(text.length);
      if (!done.isCompleted) done.complete();
    });
    await _player.play(UrlSource(clip.audioUrl));
    onStart();
    return done.future;
  }

  Future<void> _cleanup() async {
    await _posSub?.cancel();
    await _endSub?.cancel();
    _posSub = null;
    _endSub = null;
  }

  @override
  bool get canPauseInPlace => true;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() async {
    await _player.stop();
    await _cleanup();
    if (_done != null && !_done!.isCompleted) _done!.complete();
  }

  @override
  void dispose() {
    stop();
    _player.dispose();
  }
}

class _Clip {
  _Clip(this.audioUrl, this._wordStartsMs, this._wordEnds);

  /// Aligns the server's word timings with character offsets in [text].
  factory _Clip.fromJson(Map<String, dynamic> j, String text, String baseUrl) {
    final lower = text.toLowerCase();
    final starts = <int>[];
    final ends = <int>[];
    var cursor = 0;
    for (final w in (j['words'] as List).cast<Map<String, dynamic>>()) {
      final token = (w['text'] as String).toLowerCase();
      final at = lower.indexOf(token, cursor);
      if (at >= 0) cursor = at + token.length;
      starts.add((w['start_ms'] as num).toInt());
      ends.add(cursor);
    }
    // Build the URL from the configured base so it works behind any host name.
    return _Clip('$baseUrl/api/v1/tts/audio/${j['id']}.mp3', starts, ends);
  }

  final String audioUrl;
  final List<int> _wordStartsMs;
  final List<int> _wordEnds;

  int charEndAt(int ms) {
    var end = 0;
    for (var i = 0; i < _wordStartsMs.length && _wordStartsMs[i] <= ms; i++) {
      end = _wordEnds[i];
    }
    return end;
  }
}

// ----------------------------------------------------------------- device
/// The phone's / browser's own TTS, forced to a female English voice.
/// Works offline — used when the server voice is unavailable.
class DeviceSpeechEngine extends SpeechEngine {
  DeviceSpeechEngine() {
    _ready = _init();
  }

  final FlutterTts _tts = FlutterTts();
  late final Future<void> _ready;
  Completer<void>? _done;
  void Function(int)? _onProgress;

  static final _femaleHint = RegExp(
    r'female|samantha|zira|aria|jenny|ava|emma|susan|karen|moira|tessa|victoria|'
    r'serena|allison|libby|sonia|google us english|en-us-x-sfg|en-us-x-tpf|en-gb-x-gba',
    caseSensitive: false,
  );

  Future<void> _init() async {
    await _tts.awaitSpeakCompletion(false);
    await _tts.setLanguage('en-US');
    // Android's 0.5 is "normal"; web/desktop use 1.0.
    await _tts.setSpeechRate(!kIsWeb && defaultTargetPlatform == TargetPlatform.android ? 0.5 : 1.0);
    await _tts.setPitch(1.08);
    _tts.setProgressHandler((text, start, end, word) => _onProgress?.call(end));
    _tts.setCompletionHandler(_finish);
    _tts.setCancelHandler(_finish);
    _tts.setErrorHandler((_) => _finish());
    try {
      final voices = (await _tts.getVoices as List?) ?? const [];
      Map? best;
      for (final v in voices.cast<Map>()) {
        final locale = '${v['locale']}'.toLowerCase();
        if (!locale.startsWith('en')) continue;
        final female = '${v['gender']}'.toLowerCase() == 'female' ||
            _femaleHint.hasMatch('${v['name']}');
        if (female) {
          best = v;
          if (locale.contains('us')) break;
        }
      }
      if (best != null) {
        await _tts.setVoice({'name': '${best['name']}', 'locale': '${best['locale']}'});
      }
    } catch (_) {
      // Voice list not available on this platform — keep the default voice.
    }
  }

  void _finish() {
    if (_done != null && !_done!.isCompleted) _done!.complete();
  }

  @override
  Future<void> speak(String text,
      {required void Function() onStart, required void Function(int) onProgress}) async {
    await _ready;
    _finish();
    final done = _done = Completer<void>();
    _onProgress = onProgress;
    onStart();
    await _tts.speak(text);
    await done.future;
    onProgress(text.length);
  }

  @override
  bool get canPauseInPlace => false;

  @override
  Future<void> pause() => stop();

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    await _tts.stop();
    _finish();
  }

  @override
  void dispose() {
    stop();
  }
}
