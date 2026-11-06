import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/audio.dart';
import 'core/data.dart';
import 'core/progress.dart';
import 'core/speech.dart';

/// Ilova bo'ylab umumiy holat.
class App {
  App._();
  static final App i = App._();
  final QuranData data = QuranData();
  final ProgressStore progress = ProgressStore();
  final AudioService audio = AudioService();
  final Recognizer speech = Recognizer();

  Future<void> init() async {
    await Future.wait([data.load(), progress.load(), audio.init()]);
  }

  double surahProgress(int s) {
    final d = data.darsOf(s);
    var done = 0.0;
    for (final x in d) {
      final p = progress['q$s-${x[0]}-${x[1]}'];
      if (p == null) continue;
      if (p.learned) {
        done += 1;
      } else if (p.total > 0) {
        done += p.done / p.total * .9;
      }
    }
    return done / d.length;
  }

  int get learnedSurahs => [for (var s = 1; s <= 114; s++) surahProgress(s)].where((p) => p >= 1).length;

  int get learnedNames {
    var n = 0;
    for (final d in data.asmaDars) {
      if (progress['asma-${d[0]}-${d[1]}']?.learned == true) n += d[1] - d[0] + 1;
    }
    return n;
  }
}

class C {
  static const bg = Color(0xFFEEF2E8);
  static const surface = Colors.white;
  static const soft = Color(0xFFE2EADB);
  static const ink = Color(0xFF1E2A22);
  static const muted = Color(0xFF5C6B5F);
  static const line = Color(0xFFD3DCCB);
  static const accent = Color(0xFF2F6150);
  static const gold = Color(0xFFA0762A);
  static const ok = Color(0xFF2C7A4C);
  static const okSoft = Color(0xFFDCEFE3);
  static const bad = Color(0xFFB0432C);
  static const badSoft = Color(0xFFF6E1DA);
}

TextStyle arabic(double size, {Color color = C.ink, FontWeight? weight}) =>
    GoogleFonts.amiri(fontSize: size, color: color, height: 1.9, fontWeight: weight);

TextStyle heading(double size, {Color color = C.ink}) => GoogleFonts.lora(fontSize: size, color: color, fontWeight: FontWeight.w600);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.accent, primary: C.accent, surface: C.surface),
    scaffoldBackgroundColor: C.bg,
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(backgroundColor: C.bg, foregroundColor: C.ink, elevation: 0, scrolledUnderElevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.accent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.ink,
        side: const BorderSide(color: C.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
      ),
    ),
  );
}

/// Oq kartochka.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color border;
  const Panel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = C.surface, this.border = C.line});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
        child: child,
      );
}

class Label extends StatelessWidget {
  final String text;
  const Label(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: const TextStyle(fontSize: 11.5, letterSpacing: 1, fontWeight: FontWeight.w600, color: C.muted));
}

const xatmNotice =
    "Hifz Ustoz faqat yodlashga yordam beruvchi ustoz vazifasini bajaradi. Dasturda o'qilgan yoki tinglangan suralar Qur'on xatmi hisoblanmaydi. Xatm uchun Qur'onni mushafdan boshidan oxirigacha o'qing. Yodlaganlaringizni imkon bo'lsa, qori yoki ustoz huzurida tekshirtiring.";

class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.gold, width: 1.5),
        ),
        child: Text.rich(TextSpan(children: [
          const TextSpan(text: 'Muhim eslatma. ', style: TextStyle(fontWeight: FontWeight.w700, color: C.gold)),
          const TextSpan(text: xatmNotice),
        ]), style: const TextStyle(fontSize: 14, height: 1.45, color: C.ink)),
      );
}

/// Natija halqasi (ro'yxatdagi raqam atrofida).
class ProgressRing extends StatelessWidget {
  final double value;
  final String label;
  const ProgressRing({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 36,
        height: 36,
        child: Stack(alignment: Alignment.center, children: [
          if (value > 0)
            CircularProgressIndicator(
              value: value.clamp(0.0, 1.0).toDouble(),
              strokeWidth: 2.5,
              color: value >= 1 ? C.ok : C.accent,
              backgroundColor: Colors.transparent,
            ),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.muted)),
        ]),
      );
}
