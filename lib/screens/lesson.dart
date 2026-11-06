import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/arabic.dart';
import '../core/data.dart';
import 'intro.dart';

class _Attempt {
  final bool pass;
  final int pct;
  final List<String> missed;
  final String heard;
  final bool peekBlocked;
  const _Attempt(this.pass, this.pct, this.missed, this.heard, {this.peekBlocked = false});
}

/// Dars: har oyat — Ustoz 3 marta o'qiydi, 3 marta birga o'qiladi, so'ng o'quvchi o'zi aytadi.
class LessonScreen extends StatefulWidget {
  final Item item;
  const LessonScreen({super.key, required this.item});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final app = App.i;
  late final List<Stage> stages = app.data.stagesFor(widget.item);
  int si = 0;
  int phase = 0; // 0 boshlanmagan, 1 tinglash, 2 birga o'qish, 3 o'zi aytish
  int phaseN = 0;
  bool listened = false, peeked = false, recActive = false, finished = false;
  String heard = '', status = '';
  List<bool>? live;
  _Attempt? last;
  int _run = 0, _recSess = 0;
  Timer? _recTimer;
  VoidCallback? _finishRec;

  Item get item => widget.item;
  Stage get st => stages[si];
  List<String> get tw => app.data.stageWords(item, st);
  bool get busy => phase == 1 || phase == 2;

  @override
  void initState() {
    super.initState();
    final p = app.progress[item.id];
    if (p != null && !p.learned && p.total != 0 && p.total != stages.length) {
      p.done = 0;
      p.total = stages.length;
    }
    si = (p != null && !p.learned) ? math.min(p.done, stages.length - 1) : 0;
    _initStage();
  }

  @override
  void dispose() {
    _run++;
    _recSess++;
    _recTimer?.cancel();
    app.audio.stop();
    app.speech.cancel();
    super.dispose();
  }

  void _initStage() {
    phase = st.hide ? 3 : 0;
    phaseN = 0;
    listened = st.hide;
    peeked = false;
    last = null;
    heard = '';
    live = null;
    status = st.hide
        ? 'Endi yoddan ayting. Kerak bo\'lsa avval bir marta tinglang.'
        : "«Boshlash»ni bosing: Ustoz 3 marta o'qiydi, keyin u bilan birga 3 marta o'qiysiz.";
  }

  String get _partialNote =>
      st.segs.any((g) => g.from != 0 || g.to != arWords(item.units[g.u].ar).length - 1) && item.kind == 'q'
          ? " Qori butun oyatni o'qiydi, sizga kerakli qism ajratilgan."
          : '';

  Future<void> _stopRec() async {
    if (!recActive) return;
    _recSess++;
    _recTimer?.cancel();
    await app.speech.cancel();
    if (mounted) setState(() => recActive = false);
  }

  Future<void> _runGuided() async {
    final run = ++_run;
    await _stopRec();
    app.audio.reciterOk = true;
    setState(() => last = null);
    for (final ph in [1, 2]) {
      for (var r = 1; r <= 3; r++) {
        if (!mounted || run != _run) return;
        setState(() {
          phase = ph;
          phaseN = r;
          status = (ph == 1 ? 'Ustozni diqqat bilan tinglang · $r/3' : "Ustoz bilan birga ovoz chiqarib o'qing · $r/3") +
              (r == 1 ? _partialNote : '');
        });
        await app.audio.playSegs(item, st.segs);
        if (!mounted || run != _run) return;
        await Future.delayed(Duration(milliseconds: ph == 1 ? 600 : 1000));
      }
    }
    if (!mounted || run != _run) return;
    setState(() {
      phase = 3;
      listened = true;
      status = "Endi o'zingiz ayting: «Aytib ko'rish» tugmasini bosing.";
    });
  }

  Future<void> _playOnce() async {
    final run = ++_run;
    await _stopRec();
    app.audio.reciterOk = true;
    setState(() {
      phase = 1;
      phaseN = 0;
      status = 'Ustozni tinglang…$_partialNote';
    });
    await app.audio.playSegs(item, st.segs);
    if (!mounted || run != _run) return;
    setState(() {
      phase = 3;
      listened = true;
      status = "Endi «Aytib ko'rish» tugmasini bosib, o'zingiz ayting.";
    });
  }

  void _stopGuided() {
    _run++;
    app.audio.stop();
    setState(() {
      phase = listened ? 3 : 0;
      status = listened ? "Tayyor bo'lsangiz, «Aytib ko'rish»ni bosing." : '';
    });
  }

  void _skipToRecite() {
    _run++;
    app.audio.stop();
    setState(() {
      phase = 3;
      listened = true;
      status = "Endi «Aytib ko'rish»ni bosing.";
    });
  }

  Future<void> _startRec() async {
    if (!app.speech.ready) {
      setState(() => status = 'Mikrofon ishga tushyapti…');
      final ok = await app.speech.init();
      if (!mounted) return;
      if (!ok) {
        setState(() => status =
            "Ovozni tanish ishlamayapti. Ilovaga mikrofon ruxsatini bering va telefonda Google ilovasi o'rnatilganini tekshiring.");
        return;
      }
    }
    _run++;
    await app.audio.stop();
    final sess = ++_recSess;
    final words = tw;
    setState(() {
      recActive = true;
      last = null;
      live = null;
      heard = '';
      status = "Eshityapman… Aytib bo'lgach jim tursangiz, o'zi tekshiradi.";
    });
    void finish() {
      if (!mounted || sess != _recSess || !recActive) return;
      _recSess++;
      _recTimer?.cancel();
      _finishRec = null;
      app.speech.stop();
      setState(() => recActive = false);
      _evaluate(heard);
    }

    _finishRec = finish;
    _recTimer = Timer(Duration(seconds: math.min(60, 6 + (words.length * 1.3).round())), finish);
    try {
      await app.speech.listen(
        listenFor: Duration(seconds: math.min(60, 6 + (words.length * 1.3).round())),
        onEnd: finish,
        onText: (t, isFinal, alts) {
          if (!mounted || sess != _recSess) return;
          var best = t;
          var bs = score(words, t).ratio;
          for (final a in alts) {
            final r = score(words, a).ratio;
            if (r > bs) {
              bs = r;
              best = a;
            }
          }
          final sc = score(words, best);
          setState(() {
            heard = best;
            live = sc.words;
          });
          if (sc.ratio >= 1) Future.delayed(const Duration(milliseconds: 300), finish);
        },
      );
    } catch (_) {
      finish();
    }
  }

  void _evaluate(String said) {
    if (said.trim().isEmpty) {
      setState(() => status = "Hech narsa tanib olinmadi. Mikrofonga yaqinroq, balandroq ayting." +
          (app.speech.lastError != null ? ' (${app.speech.lastError})' : ''));
      return;
    }
    final words = tw;
    final sc = score(words, said);
    final pct = (sc.ratio * 100).round();
    final blocked = st.hide && peeked;
    final pass = sc.ratio >= .8 && !blocked;
    final missed = [for (var i = 0; i < words.length; i++) if (!sc.words[i]) words[i]];
    app.progress.logMiss(item.id, missed);
    final stageNow = si;
    setState(() {
      live = sc.words;
      last = _Attempt(pass, pct, missed, said, peekBlocked: blocked);
      if (pass) {
        app.progress.markStage(item.id, si, stages.length);
        status = 'Barakalla!';
      } else if (!st.hide) {
        listened = false;
        phase = 3;
        status = "Qayta tinglang, so'ng yana ayting.";
      } else {
        status = 'Yana bir bor yoddan ayting.';
      }
    });
    if (pass) {
      Future.delayed(const Duration(milliseconds: 1700), () {
        if (mounted && si == stageNow && !finished) _next();
      });
    }
  }

  void _next() {
    _run++;
    app.audio.stop();
    _stopRec();
    setState(() {
      if (si < stages.length - 1) {
        si++;
        _initStage();
      } else {
        finished = true;
      }
    });
  }

  void _prev() {
    if (si == 0) return;
    _run++;
    app.audio.stop();
    _stopRec();
    setState(() {
      si--;
      _initStage();
    });
  }

  Item? _nextLesson() {
    if (item.kind == 'q') {
      final d = app.data.darsOf(item.s);
      final i = d.indexWhere((x) => x[0] == item.f && x[1] == item.t);
      if (i >= 0 && i < d.length - 1) return app.data.quranItem(item.s, d[i + 1][0], d[i + 1][1]);
    } else if (item.kind == 'asma') {
      final d = app.data.asmaDars;
      final i = d.indexWhere((x) => x[0] == item.f);
      if (i >= 0 && i < d.length - 1) return app.data.asmaItem(d[i + 1][0], d[i + 1][1]);
    }
    return null;
  }

  // ---------- ko'rinish ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(item.title, style: heading(19))),
      body: SafeArea(child: finished ? _finishedView() : _lessonView()),
    );
  }

  Widget _finishedView() {
    final nxt = _nextLesson();
    return ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 24),
      Text('مَا شَاءَ اللَّهُ', textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arabic(36, color: C.gold)),
      const SizedBox(height: 8),
      Text('${item.title} — ${item.sub} yodlandi', textAlign: TextAlign.center, style: heading(20)),
      const SizedBox(height: 10),
      const Text(
        "Mustahkamlash uchun ertaga va bir haftadan keyin yana yoddan aytib ko'ring. Yodlaganingizni qori yoki ustoz huzurida tekshirtirib olsangiz yanada yaxshi.",
        textAlign: TextAlign.center,
        style: TextStyle(color: C.muted, height: 1.5),
      ),
      const SizedBox(height: 6),
      const Text('Eslatma: dasturdagi mashq yodlash uchun, u xatm hisoblanmaydi.',
          textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12.5)),
      const SizedBox(height: 20),
      if (nxt != null)
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => IntroScreen(item: nxt))),
          child: Text('Keyingi dars: ${nxt.sub}'),
        ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() {
          finished = false;
          si = stages.length - 1;
          _initStage();
        }),
        child: const Text('Yana yoddan aytish'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(
        onPressed: () => setState(() {
          finished = false;
          si = 0;
          _initStage();
        }),
        child: const Text('Boshidan takrorlash'),
      ),
    ]);
  }

  Widget _lessonView() {
    final words = tw;
    final hidden = st.hide && !peeked;
    final done = app.progress[item.id]?.done ?? 0;
    final units = st.segs.map((g) => g.u).toSet().toList();
    final partial = st.segs.any((g) => g.from != 0 || g.to != arWords(item.units[g.u].ar).length - 1);
    final colors = live;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Row(children: [
          Expanded(child: Text(item.sub, style: const TextStyle(color: C.muted))),
          Text('${si + 1}-qadam / ${stages.length}', style: const TextStyle(color: C.muted, fontFeatures: [FontFeature.tabularFigures()])),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(value: si / stages.length, minHeight: 6, backgroundColor: C.soft, color: C.accent),
        ),
        const SizedBox(height: 12),
        // ---- oyat varag'i ----
        Panel(
          color: C.bg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(st.kind.toUpperCase(), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 11.5, letterSpacing: 1)),
            const SizedBox(height: 6),
            ImageFiltered(
              enabled: hidden,
              imageFilter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 2, children: [
                  for (var i = 0; i < words.length; i++)
                    GestureDetector(
                      onTap: hidden ? null : () => app.audio.speakArabic(words[i], rate: 0.55),
                      child: Text(
                        words[i],
                        style: arabic(
                          (MediaQuery.of(context).size.width / 12).clamp(24.0, 38.0).toDouble(),
                          color: colors == null
                              ? C.ink
                              : (i < colors.length && colors[i]
                                  ? C.ok
                                  : (recActive ? C.ink : C.bad)),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
            if (st.hide)
              Center(
                child: TextButton.icon(
                  icon: Icon(peeked ? Icons.visibility_off : Icons.visibility),
                  label: Text(peeked ? 'Matnni yopish' : "Qiynalsangiz, matnni ko'ring"),
                  onPressed: () => setState(() => peeked = !peeked),
                ),
              ),
            if (!hidden && !partial)
              Text(units.map((k) => item.units[k].tr).join(' · '),
                  textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(children: [
                TextSpan(text: partial ? "Oyat ma'nosi: " : "Ma'nosi: ", style: const TextStyle(fontWeight: FontWeight.w700, color: C.ink)),
                TextSpan(text: units.map((k) => item.units[k].uz).join(' ')),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(color: C.muted, height: 1.45),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        if (!st.hide) _phases(),
        const SizedBox(height: 12),
        _controls(),
        const SizedBox(height: 10),
        Text(status, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
        if (heard.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(heard, textAlign: TextAlign.center, textDirection: TextDirection.rtl, style: arabic(19, color: C.muted)),
          ),
        if (last != null) ...[const SizedBox(height: 10), _resultCard()],
        const SizedBox(height: 12),
        if (!hidden) _tips(words),
        if (!hidden)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text("Istalgan arabcha so'zni bossangiz, o'sha so'z alohida va sekin o'qiladi.",
                textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12.5)),
          ),
        const Divider(height: 28),
        Row(children: [
          OutlinedButton.icon(onPressed: si == 0 ? null : _prev, icon: const Icon(Icons.chevron_left), label: const Text('Orqaga')),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: done > si ? _next : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Keyingi'),
          ),
        ]),
      ],
    );
  }

  Widget _phases() {
    Widget chip(String t, int p) {
      final isDone = phase > p || (p == 3 && last?.pass == true);
      final now = phase == p;
      final cnt = now && p < 3 && phaseN > 0 ? ' $phaseN/3' : (p < 3 ? ' 3×' : '');
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: now ? C.accent : C.line, width: now ? 1.6 : 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: isDone ? C.ok : (now ? C.accent : C.soft),
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text('$p', style: TextStyle(fontSize: 11, color: now ? Colors.white : C.muted, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Text(t, style: TextStyle(fontSize: 12.5, color: now ? C.ink : C.muted, fontWeight: now ? FontWeight.w600 : FontWeight.w400)),
          Text(cnt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: C.muted)),
        ]),
      );
    }

    return Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
      chip('Ustozni tinglash', 1),
      chip("Birga o'qish", 2),
      chip("O'zingiz aytish", 3),
    ]);
  }

  Widget _controls() {
    final buttons = <Widget>[];
    if (busy) {
      buttons.add(OutlinedButton.icon(onPressed: _stopGuided, icon: const Icon(Icons.stop), label: const Text("To'xtatish")));
      buttons.add(TextButton(onPressed: _skipToRecite, child: const Text('Tayyorman, aytaman')));
    } else if (!st.hide && phase == 0) {
      buttons.add(FilledButton.icon(
        onPressed: _runGuided,
        icon: const Icon(Icons.play_arrow),
        label: const Text("Boshlash: tinglash va birga o'qish"),
      ));
    } else {
      if (recActive) {
        buttons.add(FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: C.bad),
          onPressed: () => _finishRec?.call(),
          icon: const Icon(Icons.stop),
          label: const Text("To'xtatish"),
        ));
      } else {
        buttons.add(FilledButton.icon(
          onPressed: listened ? _startRec : null,
          icon: const Icon(Icons.mic),
          label: const Text("Aytib ko'rish"),
        ));
        if (!st.hide) {
          buttons.add(OutlinedButton.icon(onPressed: _runGuided, icon: const Icon(Icons.replay), label: const Text('Yana 3+3 tinglash')));
        }
        buttons.add(OutlinedButton.icon(onPressed: _playOnce, icon: const Icon(Icons.play_arrow), label: const Text('Bir marta tinglash')));
      }
    }
    return Column(children: [
      Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: buttons),
      if (!busy && !recActive) ...[
        const SizedBox(height: 10),
        SegmentedButton<double>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 0.5, label: Text('0.5×')),
            ButtonSegment(value: 0.75, label: Text('0.75×')),
            ButtonSegment(value: 1.0, label: Text('1×')),
          ],
          selected: {app.audio.speed},
          onSelectionChanged: (v) => setState(() => app.audio.speed = v.first),
        ),
      ],
    ]);
  }

  Widget _resultCard() {
    final a = last!;
    if (a.pass) {
      return Panel(
        color: C.okSoft,
        border: C.ok,
        child: Text("Barakalla! To'g'ri aytdingiz. Aniqlik: ${a.pct}%. Keyingi qadamga o'tyapmiz.",
            style: const TextStyle(color: C.ok, fontWeight: FontWeight.w700)),
      );
    }
    return Panel(
      color: C.badSoft,
      border: C.bad,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          CircleAvatar(radius: 16, backgroundColor: C.bad, child: Text('م', style: TextStyle(color: Colors.white))),
          SizedBox(width: 10),
          Text('Ustoz: qayta ayting', style: TextStyle(color: C.bad, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        const SizedBox(height: 8),
        if (a.peekBlocked)
          const Text("Matn ochiq turganda urinish hisoblanmaydi. Matnni yopib, yoddan ayting.")
        else ...[
          Text('Aniqlik ${a.pct}%, kamida 80% kerak.'),
          if (a.missed.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text("Quyidagi so'zlar noto'g'ri aytildi yoki tushib qoldi. So'zni bosing, to'g'risini eshitasiz:"),
            const SizedBox(height: 8),
            for (final w in a.missed.take(6))
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  OutlinedButton(
                    onPressed: () => app.audio.speakArabic(w, rate: 0.5),
                    child: Text(w, style: arabic(20, color: C.bad)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tipsForWord(w).take(2).map((t) => '${t.sign} ${t.name}: ${t.how}').join('\n').ifEmpty(
                          "So'zni sekin, bo'g'inlab ayting va unlilarni aniq chiqaring."),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ]),
              ),
          ],
        ],
        const SizedBox(height: 6),
        if (!st.hide)
          OutlinedButton.icon(onPressed: _playOnce, icon: const Icon(Icons.play_arrow), label: const Text('Qayta tinglash')),
      ]),
    );
  }

  Widget _tips(List<String> words) {
    final tips = tipsFor(words);
    if (tips.isEmpty) return const SizedBox.shrink();
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text("Talaffuz yordamchisi: qiyin harflar (${tips.length})", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          children: [
            for (final t in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 40, child: Text(t.tip.sign, textAlign: TextAlign.center, style: arabic(26, color: C.gold))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '${t.tip.name} — ', style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: t.tip.how),
                      ])),
                      TextButton(
                        onPressed: () => app.audio.speakArabic(t.example, rate: 0.5),
                        child: Text('${t.example} ▸', style: arabic(18, color: C.accent)),
                      ),
                    ]),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String other) => isEmpty ? other : this;
}
