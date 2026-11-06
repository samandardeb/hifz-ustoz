import 'package:flutter/material.dart';

import '../app.dart';
import 'intro.dart';
import 'surah.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _Learned {
  final String kind, name, ar;
  final int at;
  final VoidCallback open;
  _Learned(this.kind, this.name, this.ar, this.at, this.open);
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final app = App.i;
    final data = app.data;
    final learned = <_Learned>[];
    void open(Widget w) async {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));
      if (mounted) setState(() {});
    }

    for (final su in data.surahs) {
      if (app.surahProgress(su.n) < 1) continue;
      final d = data.darsOf(su.n);
      var at = 0;
      for (final x in d) {
        final p = app.progress['q${su.n}-${x[0]}-${x[1]}'];
        if (p != null && p.at > at) at = p.at;
      }
      learned.add(_Learned('Sura', '${su.uz} surasi', su.ar, at,
          () => open(d.length > 1 ? SurahScreen(s: su.n) : IntroScreen(item: data.quranItem(su.n, 1, su.count)))));
    }
    for (final d in data.asmaDars) {
      final p = app.progress['asma-${d[0]}-${d[1]}'];
      if (p != null && p.learned) {
        learned.add(_Learned("Allohning ismlari", '${d[0]}–${d[1]}-ismlar', data.asma[d[0] - 1][0], p.at,
            () => open(IntroScreen(item: data.asmaItem(d[0], d[1])))));
      }
    }
    learned.sort((a, b) => b.at.compareTo(a.at));
    final going = app.progress.items.values.where((p) => p.done > 0 && !p.learned).length;

    Widget card(int n, int total, String label) => Expanded(
          child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: '$n', style: heading(30)),
                TextSpan(text: ' / $total', style: const TextStyle(color: C.muted, fontSize: 14)),
              ])),
              Text(label, style: const TextStyle(color: C.muted, fontSize: 13)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: total == 0 ? 0 : n / total, minHeight: 5, backgroundColor: C.soft, color: C.accent),
              ),
            ]),
          ),
        );

    String date(int ms) {
      if (ms == 0) return '';
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      return ' · ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    }

    return Scaffold(
      appBar: AppBar(title: Text('Natijalarim', style: heading(20))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            if (going > 0) Text('$going ta dars davom etmoqda', style: const TextStyle(color: C.muted)),
            const SizedBox(height: 8),
            Row(children: [
              card(app.learnedSurahs, 114, 'sura yodlangan'),
              const SizedBox(width: 10),
              card(app.learnedNames, 99, 'Allohning ismi'),
            ]),
            const SizedBox(height: 18),
            const Label('Yodlanganlar'),
            const SizedBox(height: 6),
            if (learned.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "Hali hech narsa to'liq yodlanmagan. Suralar bo'limidan Fotiha surasini boshlang. Dars oxirida hammasini yoddan aytganingizda shu yerda ko'rinadi.",
                  style: TextStyle(color: C.muted, height: 1.5),
                ),
              ),
            for (final x in learned)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: C.ok, child: Icon(Icons.check, color: Colors.white)),
                title: Text(x.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${x.kind}${date(x.at)}'),
                trailing: Text(x.ar, textDirection: TextDirection.rtl, style: arabic(18, color: C.gold)),
                onTap: x.open,
              ),
            const SizedBox(height: 10),
            const Text('Natijalar shu qurilmada saqlanadi.', style: TextStyle(color: C.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
