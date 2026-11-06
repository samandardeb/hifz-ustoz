import 'dart:async';

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/arabic.dart';
import '../core/data.dart';
import 'intro.dart';
import 'surah.dart';

/// Eshitilgan qiroatni tanish: 7 soniya tinglaydi, o'zi to'xtaydi va oyatni topadi.
class FinderScreen extends StatefulWidget {
  const FinderScreen({super.key});
  @override
  State<FinderScreen> createState() => _FinderScreenState();
}

class _FinderScreenState extends State<FinderScreen> {
  static const listenSeconds = 7;
  final app = App.i;
  bool on = false;
  String text = '', status = "Tugmani bosing va telefonni qiroatga yaqin tuting. Dastur 7 soniya tinglab, o'zi aniqlaydi.";
  List<Found> results = [];
  int _sess = 0;
  Timer? _timer, _tick;
  DateTime _t0 = DateTime.now();
  final _typed = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _sess++;
    _timer?.cancel();
    _tick?.cancel();
    _debounce?.cancel();
    app.speech.cancel();
    app.audio.stop();
    _typed.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (!app.speech.ready) {
      setState(() => status = 'Mikrofon ishga tushyapti…');
      final ok = await app.speech.init();
      if (!mounted) return;
      if (!ok) {
        setState(() => status = "Ovozni tanish ishlamayapti. Mikrofonga ruxsat bering yoki eshitgan so'zlaringizni pastga yozing.");
        return;
      }
    }
    await app.audio.stop();
    final sess = ++_sess;
    _t0 = DateTime.now();
    setState(() {
      on = true;
      text = '';
      results = [];
    });
    _tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || sess != _sess) return;
      final left = (listenSeconds - DateTime.now().difference(_t0).inMilliseconds / 1000).ceil().clamp(0, listenSeconds);
      setState(() => status = "Tinglayapman… $left soniya. Erta to'xtatish uchun tugmani bosing.");
    });
    _timer = Timer(const Duration(seconds: listenSeconds), () => _finish(sess));
    try {
      await app.speech.listen(
        listenFor: const Duration(seconds: listenSeconds + 1),
        pauseFor: const Duration(seconds: 3),
        onEnd: () => _finish(sess),
        onText: (t, isFinal, alts) {
          if (!mounted || sess != _sess) return;
          setState(() => text = t);
          if (norm(t).split(' ').where((x) => x.isNotEmpty).length >= 4) {
            final r = app.data.findAyahs(t);
            if (r.isNotEmpty && r.first.r >= .85 && (r.length < 2 || r.first.r - r[1].r >= .08)) _finish(sess);
          }
        },
      );
    } catch (_) {
      _finish(sess);
    }
  }

  void _finish(int sess) {
    if (!mounted || sess != _sess || !on) return;
    _sess++;
    _timer?.cancel();
    _tick?.cancel();
    app.speech.stop();
    final r = text.isEmpty ? <Found>[] : app.data.findAyahs(text);
    setState(() {
      on = false;
      results = r;
      status = text.isEmpty
          ? 'Ovoz eshitilmadi. Telefonni qiroatga yaqinroq tutib, qayta bosing.'
          : (r.isEmpty ? "Aniqlab bo'lmadi. Qiroatning aniqroq joyida qayta bosing yoki eshitgan so'zlaringizni yozing." : 'Topildi.');
    });
  }

  void _search(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => results = app.data.findAyahs(v));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Eshitgan qiroatni tanish', style: heading(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            const Text(
              "Biror joyda chiroyli qiroat eshitdingizmi? Telefonni ovozga yaqinlashtiring yoki eshitgan oyatingizni o'zingiz o'qing. Dastur qaysi suraning nechanchi oyati ekanini, o'qilishi va ma'nosini topadi.",
              style: TextStyle(fontSize: 15.5, height: 1.5),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => on ? _finish(_sess) : _start(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: on ? C.bad : C.accent,
                    boxShadow: on ? [BoxShadow(color: C.bad.withAlpha(77), blurRadius: 24, spreadRadius: 8)] : null,
                  ),
                  child: Icon(on ? Icons.stop_rounded : Icons.mic_rounded, size: 56, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(status, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
            if (text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(text, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arabic(20, color: C.muted)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _typed,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: "Yoki eshitgan so'zlaringizni arabcha yozing",
                hintTextDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: C.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 16),
            if (results.isNotEmpty) const Label('Natija'),
            for (var k = 0; k < results.length; k++) ...[
              if (k == 1) const Padding(padding: EdgeInsets.only(top: 10), child: Label("Boshqa o'xshash oyatlar")),
              _ResultCard(found: results[k], top: k == 0),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Found found;
  final bool top;
  const _ResultCard({required this.found, required this.top});

  @override
  Widget build(BuildContext context) {
    final data = App.i.data;
    final (s, a) = data.locate(found.index);
    final ay = data.ayah(s, a);
    final su = data.surah(s);
    final dars = data.darsOf(s).firstWhere((d) => a >= d[0] && a <= d[1]);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: top ? C.accent : C.line, width: top ? 2 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${su.uz} surasi, $a-oyat', style: heading(18)),
        Text('$s:$a · moslik ${(found.r * 100).round()}%${found.pair ? ' · keyingi oyat bilan' : ''}',
            style: const TextStyle(color: C.muted, fontSize: 12.5)),
        const SizedBox(height: 6),
        Text(ay.ar, textDirection: TextDirection.rtl, style: arabic(24)),
        Text(ay.tr, style: const TextStyle(fontStyle: FontStyle.italic)),
        const SizedBox(height: 4),
        Text(ay.uz, style: const TextStyle(height: 1.45)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mishari ovozida tinglash'),
            onPressed: () => App.i.audio.playCode(ay.code!, ay.ar),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Shu oyatni yodlash'),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IntroScreen(item: data.quranItem(s, dars[0], dars[1])))),
          ),
          OutlinedButton(
            child: const Text('Butun sura'),
            onPressed: () {
              final d = data.darsOf(s);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => d.length > 1 ? SurahScreen(s: s) : IntroScreen(item: data.quranItem(s, d[0][0], d[0][1]))));
            },
          ),
        ]),
      ]),
    );
  }
}
