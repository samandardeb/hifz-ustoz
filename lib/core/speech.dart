import 'dart:async';

import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Telefonning o'z nutqni tanish tizimi (Google) orqali arabcha ovozni matnga aylantiradi.
class Recognizer {
  final SpeechToText _stt = SpeechToText();
  bool ready = false;
  String? lastError;
  String _localeId = 'ar_SA';
  void Function()? _onEnd;

  Future<bool> init() async {
    if (ready) return true;
    try {
      ready = await _stt.initialize(
        onError: (SpeechRecognitionError e) {
          lastError = e.errorMsg;
          _end();
        },
        onStatus: (String s) {
          if (s == 'done' || s == 'notListening') {
            // Oxirgi natija biroz kechikib kelishi mumkin.
            Future.delayed(const Duration(milliseconds: 500), _end);
          }
        },
      );
      if (ready) {
        final locales = await _stt.locales();
        final arabic = locales.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();
        if (arabic.isNotEmpty) {
          _localeId = arabic
              .firstWhere((l) => l.localeId.toUpperCase().contains('SA'), orElse: () => arabic.first)
              .localeId;
        }
      }
    } catch (e) {
      lastError = e.toString();
      ready = false;
    }
    return ready;
  }

  void _end() {
    final f = _onEnd;
    _onEnd = null;
    f?.call();
  }

  /// [onText] har yangi natijada chaqiriladi: (matn, yakuniymi, muqobil variantlar).
  Future<void> listen({
    required void Function(String text, bool isFinal, List<String> alternates) onText,
    required void Function() onEnd,
    required Duration listenFor,
    Duration pauseFor = const Duration(milliseconds: 2500),
  }) async {
    lastError = null;
    _onEnd = onEnd;
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) {
        onText(r.recognizedWords, r.finalResult, r.alternates.map((a) => a.recognizedWords).toList());
        if (r.finalResult) _end();
      },
      localeId: _localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Darhol to'xtatadi. Natijani kutmaydi.
  Future<void> stop() async {
    _onEnd = null;
    try {
      await _stt.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    _onEnd = null;
    try {
      await _stt.cancel();
    } catch (_) {}
  }
}
