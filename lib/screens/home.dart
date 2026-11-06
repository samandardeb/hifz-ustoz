import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app.dart';
import 'asma.dart';
import 'finder.dart';
import 'results.dart';
import 'sura_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _go(Widget page) async {
    await App.i.audio.stop();
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {}); // natijalar yangilanadi
  }

  @override
  Widget build(BuildContext context) {
    final app = App.i;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hifz Ustoz', style: GoogleFonts.marcellus(fontSize: 24, color: C.ink)),
        actions: [
          IconButton(tooltip: 'Natijalarim', icon: const Icon(Icons.bar_chart_rounded), onPressed: () => _go(const ResultsScreen())),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Panel(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', textDirection: TextDirection.rtl, textAlign: TextAlign.left, style: arabic(24, color: C.gold)),
                const SizedBox(height: 4),
                Text("Qur'on va uning ma'nolarini eslab qoling", style: GoogleFonts.marcellus(fontSize: 28, height: 1.2, color: C.ink)),
                const SizedBox(height: 10),
                Text("Qur'on hidoyat yo'lidir, unga amal qilish jannatning kalitidir.",
                    style: GoogleFonts.lora(fontSize: 17, fontStyle: FontStyle.italic, color: C.gold, height: 1.5)),
                const SizedBox(height: 20),
                _SectionTile(title: 'Suralar', onTap: () => _go(const SuraListScreen())),
                const SizedBox(height: 12),
                _SectionTile(title: 'Allohning 99 ismi', onTap: () => _go(const AsmaScreen())),
                const SizedBox(height: 12),
                _WideTile(
                  icon: Icons.graphic_eq_rounded,
                  iconColor: C.accent,
                  title: 'Eshitgan qiroatni tanish',
                  subtitle: 'Qaysi suraning nechanchi oyati ekanini topadi',
                  onTap: () => _go(const FinderScreen()),
                ),
                const SizedBox(height: 12),
                _WideTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: C.gold,
                  title: 'Natijalarim',
                  subtitle: '${app.learnedSurahs} sura · ${app.learnedNames} ta ism yodlangan',
                  onTap: () => _go(const ResultsScreen()),
                  light: true,
                ),
                const SizedBox(height: 8),
                const _Habits(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _SectionTile({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
            child: Row(children: [
              Expanded(child: Text(title, style: heading(22))),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
        ),
      );
}

class _WideTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  final bool light;
  const _WideTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap, this.light = false});
  @override
  Widget build(BuildContext context) => Material(
        color: light ? C.surface : C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              CircleAvatar(radius: 24, backgroundColor: iconColor, child: Icon(icon, color: Colors.white)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: heading(17)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: C.muted, fontSize: 13.5)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
        ),
      );
}

class _Habits extends StatelessWidget {
  const _Habits();
  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Yodlashni oson qiladigan odatlar', style: heading(16)),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: const [
            _Bullet('Har kuni oz-ozdan', "Kuniga 1 ta dars (3–5 oyat) haftasiga bir marta ko'p o'tirishdan foydaliroq."),
            _Bullet("Avval ko'p tinglang", "Darsda Ustoz har oyatni 3 marta o'qiydi, keyin u bilan birga 3 marta o'qiysiz."),
            _Bullet('Bomdoddan keyin yodlang', 'Ertalab xotira tiniq bo\'ladi.'),
            _Bullet('Eskisini takrorlang', "Yangi dars oldidan kechagi darsni bir marta yoddan ayting."),
            _Bullet("Namozda o'qing", "Yodlangan sura namozda o'qilsa, esdan chiqmaydi."),
          ],
        ),
      );
}

class _Bullet extends StatelessWidget {
  final String b, t;
  const _Bullet(this.b, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(
          TextSpan(children: [TextSpan(text: '$b. ', style: const TextStyle(fontWeight: FontWeight.w700)), TextSpan(text: t)]),
          style: const TextStyle(fontSize: 14.5, height: 1.45, color: C.ink),
        ),
      );
}
