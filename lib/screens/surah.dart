import 'package:flutter/material.dart';

import '../app.dart';
import '../core/arabic.dart';
import '../core/data.dart';
import 'intro.dart';

/// Uzun sura: darslar ro'yxati.
class SurahScreen extends StatefulWidget {
  final int s;
  const SurahScreen({super.key, required this.s});
  @override
  State<SurahScreen> createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  @override
  Widget build(BuildContext context) {
    final data = App.i.data;
    final su = data.surah(widget.s);
    final dars = data.darsOf(widget.s);
    return Scaffold(
      appBar: AppBar(title: Text('${su.uz} surasi', style: heading(20))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(su.ar, textDirection: TextDirection.rtl, style: arabic(28, color: C.gold)),
            Text('${su.n}-sura · ${su.count} oyat · ${su.madani ? 'Madaniy' : 'Makkiy'}', style: const TextStyle(color: C.muted)),
            if (aboutText['${su.n}'] != null) ...[
              const SizedBox(height: 10),
              Text(aboutText['${su.n}']!, style: const TextStyle(fontSize: 16, height: 1.5)),
            ],
            const SizedBox(height: 14),
            MethodCard(darsCount: dars.length, unit: 'oyat'),
            const SizedBox(height: 16),
            const Label('Darslar'),
            const SizedBox(height: 8),
            for (var i = 0; i < dars.length; i++)
              DarsCard(
                index: i,
                range: dars[i][0] == dars[i][1] ? '${dars[i][0]}-oyat' : '${dars[i][0]}–${dars[i][1]}-oyatlar',
                preview: arWords(data.ayah(widget.s, dars[i][0]).ar).take(5).join(' '),
                progress: App.i.progress['q${widget.s}-${dars[i][0]}-${dars[i][1]}'],
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => IntroScreen(item: data.quranItem(widget.s, dars[i][0], dars[i][1]))));
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}

class MethodCard extends StatelessWidget {
  final int darsCount;
  final String unit;
  const MethodCard({super.key, required this.darsCount, required this.unit});
  @override
  Widget build(BuildContext context) => Panel(
        color: C.bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Qanday yodlanadi', style: heading(15)),
          const SizedBox(height: 6),
          Text(
            '1. ${darsCount > 1 ? '$darsCount ta darsga bo\'lingan.' : 'Bitta dars.'}\n'
            "2. Avval o'zbekcha ma'nosini o'qiysiz.\n"
            "3. Har $unit she'r yodlagandek butunligicha o'rganiladi: Ustoz 3 marta o'qiydi, keyin u bilan birga 3 marta o'qiysiz.\n"
            "4. So'ng o'zingiz aytasiz. Ustoz talaffuzni tekshiradi va to'g'ri bo'lsa keyingisiga o'tkazadi.\n"
            '5. Oxirida hammasini yoddan aytasiz.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ]),
      );
}

class DarsCard extends StatelessWidget {
  final int index;
  final String range, preview;
  final dynamic progress; // ItemProgress?
  final VoidCallback onTap;
  const DarsCard({super.key, required this.index, required this.range, required this.preview, required this.progress, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = progress;
    final String state;
    final Color color;
    if (p != null && p.learned == true) {
      state = 'Yodlangan';
      color = C.ok;
    } else if (p != null && (p.done as int) > 0 && (p.total as int) > 0) {
      state = 'Davom etish · ${((p.done as int) / (p.total as int) * 100).round()}%';
      color = C.accent;
    } else {
      state = 'Boshlanmagan';
      color = C.muted;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${index + 1}-dars', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(range, style: const TextStyle(color: C.muted, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(state, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
                ]),
              ),
              Flexible(
                child: Text(preview, textDirection: TextDirection.rtl, maxLines: 1, overflow: TextOverflow.ellipsis, style: arabic(18, color: C.gold)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
