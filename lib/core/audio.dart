import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import 'arabic.dart';
import 'data.dart';

enum PlayResult { done, stopped, failed }

/// Shayx Mishari Roshid al-Afasiy qiroati va sun'iy ovoz (arabcha / o'zbekcha).
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  double speed = 0.75;
  int _run = 0;
  bool reciterOk = true;
  bool? _uzVoice;
  void Function(String message)? onNotice;

  Future<void> init() async {
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  static String _url(String code) => 'https://everyayah.com/data/Alafasy_128kbps/$code.mp3';

  Future<void> stop() async {
    _run++;
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<PlayResult> _playReciter(String code, int run) async {
    try {
      await _player.setUrl(_url(code));
      if (run != _run) return PlayResult.stopped;
      await _player.setSpeed(speed);
      unawaited(_player.play());
      final state = await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed || s == ProcessingState.idle)
          .timeout(const Duration(minutes: 3));
      if (run != _run) return PlayResult.stopped;
      return state == ProcessingState.completed ? PlayResult.done : PlayResult.stopped;
    } catch (_) {
      return run != _run ? PlayResult.stopped : PlayResult.failed;
    }
  }

  Future<void> speakArabic(String text, {double rate = 0.75}) async {
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.5 * rate);
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Oyat yoki uning qismini o'qiydi. Qur'on oyatida doim Mishari ovozi, bo'lmasa sun'iy ovoz.
  Future<bool> playSegs(Item item, List<Seg> segs) async {
    final run = ++_run;
    for (final g in segs) {
      if (run != _run) return false;
      final u = item.units[g.u];
      if (u.code != null && reciterOk) {
        final r = await _playReciter(u.code!, run);
        if (r == PlayResult.done) continue;
        if (r == PlayResult.stopped) return false;
        reciterOk = false;
        onNotice?.call("Qori ovozi yuklanmadi. Internetni tekshiring. Hozircha sun'iy ovozda o'qilyapti.");
      }
      final words = arWords(u.ar).sublist(g.from, g.to + 1).join(' ');
      await speakArabic(words, rate: speed);
    }
    return run == _run;
  }

  Future<void> playCode(String code, String arFallback) async {
    final run = ++_run;
    reciterOk = true;
    final r = await _playReciter(code, run);
    if (r == PlayResult.failed && run == _run) await speakArabic(arFallback, rate: speed);
  }

  /// O'zbekcha matnni ovozda o'qiydi. O'zbekcha ovoz bo'lmasa, kirillga o'girib ruscha ovozda.
  Future<void> speakUz(String text) async {
    final run = ++_run;
    try {
      await _tts.stop();
      _uzVoice ??= (await _tts.isLanguageAvailable('uz-UZ')) == true;
    } catch (_) {
      _uzVoice = false;
    }
    final useUz = _uzVoice == true;
    final parts = RegExp(r'[ء-ي][؀-ۿ\s]*[؀-ۿ]|[ء-ي]|[^؀-ۿ]+')
        .allMatches(text.replaceAll(RegExp(r'\s+'), ' '))
        .map((m) => m.group(0)!)
        .where((p) => p.trim().isNotEmpty);
    for (final p in parts) {
      if (run != _run) return;
      if (RegExp(r'[ء-ي]').hasMatch(p)) {
        await speakArabic(p, rate: 0.8);
        continue;
      }
      final sentences = RegExp(r'[^.!?;:\n]+[.!?;:]*').allMatches(p).map((m) => m.group(0)!.trim());
      for (var x in sentences) {
        if (!RegExp('[a-zA-Z0-9]').hasMatch(x)) continue;
        while (x.isNotEmpty) {
          if (run != _run) return;
          var cut = x.length > 180 ? x.lastIndexOf(' ', 180) : x.length;
          if (cut < 40) cut = x.length < 180 ? x.length : 180;
          final chunk = x.substring(0, cut);
          try {
            await _tts.setLanguage(useUz ? 'uz-UZ' : 'ru-RU');
            await _tts.setSpeechRate(0.47);
            await _tts.speak(useUz ? chunk : uzToCyr(chunk));
          } catch (_) {}
          x = x.substring(cut).trim();
        }
      }
    }
  }

  bool isCurrent(int run) => run == _run;
}
