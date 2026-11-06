import 'package:flutter/material.dart';

import '../app.dart';
import '../core/arabic.dart';
import '../core/data.dart';
import 'intro.dart';
import 'surah.dart';

class SuraListScreen extends StatefulWidget {
  const SuraListScreen({super.key});
  @override
  State<SuraListScreen> createState() => _SuraListScreenState();
}

class _SuraListScreenState extends State<SuraListScreen> {
  String _q = '';
  bool _juz30 = false;

  String _low(String s) => s.toLowerCase().replaceAll(RegExp('[‘’ʻʼ`]'), "'");

  Future<void> openSurah(int s) async {
    final d = App.i.data.darsOf(s);
    final page = d.length > 1 ? SurahScreen(s: s) : IntroScreen(item: App.i.data.quranItem(s, d[0][0], d[0][1]));
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  Future<void> openItem(Item it) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => IntroScreen(item: it)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final data = App.i.data;
    final q = _low(_q.trim());
    final children = <Widget>[];

    final ref = RegExp(r'^(\d{1,3})\s*[:.]\s*(\d{1,3})(?:\s*-\s*(\d{1,3}))?$').firstMatch(q);
    if (ref != null) {
      final s = int.parse(ref.group(1)!), a = int.parse(ref.group(2)!);
      final b = int.parse(ref.group(3) ?? ref.group(2)!);
      if (s >= 1 && s <= 114 && a >= 1 && b >= a && b <= data.surah(s).count) {
        final t = b > a + 9 ? a + 9 : b;
        final it = data.quranItem(s, a, t);
        children.add(const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 4), child: Label('Oyat')));
        children.add(ListTile(
          leading: ProgressRing(value: 0, label: '$s'),
          title: Text(it.sub, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(it.units.first.uz, maxLines: 2, overflow: TextOverflow.ellipsis),
          onTap: () => openItem(it),
        ));
      }
    }

    var list = [for (final s in data.surahs) if (!_juz30 || s.juz == 30) s];
    if (q.isNotEmpty && ref == null) {
      final nq = norm(_q);
      list = list
          .where((s) =>
              '${s.n}' == q ||
              _low(s.uz).contains(q) ||
              _low(s.latin).contains(q) ||
              _low(s.en).contains(q) ||
              (nq.isNotEmpty && norm(s.ar).contains(nq)))
          .toList();
    }
    if (q.isNotEmpty && list.isNotEmpty) {
      children.add(const Padding(padding: EdgeInsets.fromLTRB(4, 12, 4, 4), child: Label('Suralar')));
    }
    for (final s in list) {
      children.add(_SurahRow(s: s, onTap: () => openSurah(s.n)));
    }

    if (q.length >= 3 && ref == null) {
      final nq = norm(_q);
      final hits = <(int, int, int)>[];
      outer:
      for (var s = 1; s <= 114; s++) {
        for (var a = 1; a <= data.surah(s).count; a++) {
          final i = data.offsets[s - 1] + a - 1;
          if (_low(data.uz[i]).contains(q) || (nq.isNotEmpty && norm(data.ar[i]).contains(nq))) {
            hits.add((s, a, i));
            if (hits.length >= 25) break outer;
          }
        }
      }
      if (hits.isNotEmpty) {
        children.add(Padding(padding: const EdgeInsets.fromLTRB(4, 16, 4, 4), child: Label('Ma\'nosida "${_q.trim()}" bor oyatlar')));
        for (final h in hits) {
          children.add(ListTile(
            leading: ProgressRing(value: 0, label: '${h.$1}'),
            title: Text('${data.surah(h.$1).uz}, ${h.$2}-oyat', style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(data.uz[h.$3], maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => openItem(data.quranItem(h.$1, h.$2, h.$2)),
          ));
        }
      }
    }
    if (children.isEmpty) {
      children.add(const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Hech narsa topilmadi. Sura nomini (masalan \"Mulk\"), raqamini yoki \"67:1\" ko'rinishida yozing.", style: TextStyle(color: C.muted)),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Suralar', style: heading(20))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Masalan: Mulk, 67 yoki 2:255',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: C.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.line)),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Faqat 30-pora (qisqa suralar)'),
                selected: _juz30,
                onSelected: (v) => setState(() => _juz30 = v),
              ),
            ),
            const SizedBox(height: 10),
            const NoticeCard(),
            const SizedBox(height: 6),
            _StartHere(onOpen: openSurah),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  final Surah s;
  final VoidCallback onTap;
  const _SurahRow({required this.s, required this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: ProgressRing(value: App.i.surahProgress(s.n), label: '${s.n}'),
        title: Text(s.uz, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${s.count} oyat · ${s.madani ? 'Madaniy' : 'Makkiy'} · ${s.juz}-pora', style: const TextStyle(color: C.muted, fontSize: 12.5)),
        trailing: Text(s.ar, style: arabic(19, color: C.gold)),
        onTap: onTap,
      );
}

class _StartHere extends StatelessWidget {
  final void Function(int) onOpen;
  const _StartHere({required this.onOpen});
  @override
  Widget build(BuildContext context) {
    final app = App.i;
    final path = recommendedPath.take(8).toList();
    final next = recommendedPath.firstWhere((n) => app.surahProgress(n) < 1, orElse: () => recommendedPath.first);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        initiallyExpanded: app.progress.items.isEmpty,
        title: Text('Qaysi suradan boshlash kerak?', style: heading(16)),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        children: [
          const Text(
            "Qisqa suralardan boshlash osonroq. Qisqa sura 1–2 kunda yodlanadi, uni darhol namozda o'qiysiz, talaffuz ham qisqa oyatlarda tezroq o'rganiladi. Tavsiya etilgan tartib: Fotiha, Nos, Falaq, Ixlos, keyin 30-pora oxiridan boshiga qarab.",
            style: TextStyle(fontSize: 14.5, height: 1.45),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var k = 0; k < path.length; k++)
              ActionChip(
                avatar: CircleAvatar(
                  backgroundColor: app.surahProgress(path[k]) >= 1 ? C.ok : (path[k] == next ? C.accent : C.soft),
                  child: app.surahProgress(path[k]) >= 1
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${k + 1}', style: TextStyle(fontSize: 11, color: path[k] == next ? Colors.white : C.muted)),
                ),
                label: Text(app.data.surah(path[k]).uz),
                side: BorderSide(color: path[k] == next ? C.accent : C.line, width: path[k] == next ? 2 : 1),
                onPressed: () => onOpen(path[k]),
              ),
          ]),
        ],
      ),
    );
  }
}
