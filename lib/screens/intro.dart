import 'package:flutter/material.dart';

import '../app.dart';
import '../core/arabic.dart';
import '../core/data.dart';
import 'lesson.dart';

/// Darsdan oldin: ma'nosini tushunib olish.
class IntroScreen extends StatefulWidget {
  final Item item;
  const IntroScreen({super.key, required this.item});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool _playing = false, _speaking = false;

  @override
  void dispose() {
    App.i.audio.stop();
    super.dispose();
  }

  Future<void> _hearAll() async {
    final audio = App.i.audio;
    if (_playing) {
      await audio.stop();
      setState(() => _playing = false);
      return;
    }
    await audio.stop();
    setState(() {
      _playing = true;
      _speaking = false;
    });
    final it = widget.item;
    audio.reciterOk = true;
    await audio.playSegs(it, [for (var k = 0; k < it.units.length; k++) Seg(k, 0, arWords(it.units[k].ar).length - 1)]);
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _speakMeaning() async {
    final audio = App.i.audio;
    if (_speaking) {
      await audio.stop();
      setState(() => _speaking = false);
      return;
    }
    await audio.stop();
    setState(() {
      _speaking = true;
      _playing = false;
    });
    final it = widget.item;
    final text = [
      if (it.about.isNotEmpty) it.about,
      for (var i = 0; i < it.units.length; i++) '${it.base + i + 1}. ${it.units[i].uz}',
    ].join('. ');
    await audio.speakUz(text);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final p = App.i.progress[it.id];
    final miss = (p?.miss.entries.toList() ?? [])..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(title: Text(it.title, style: heading(20))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text(it.sub, style: const TextStyle(color: C.muted)),
            const SizedBox(height: 12),
            const Label("Darsdan oldin: ma'nosini tushunib oling"),
            if (it.about.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(it.about, style: const TextStyle(fontSize: 17, height: 1.55)),
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < it.units.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.line)),
                    child: Text('${it.base + i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.muted)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(it.units[i].ar, textDirection: TextDirection.rtl, style: arabic(22, color: C.gold)),
                      Text(it.units[i].tr, style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 2),
                      Text(it.units[i].uz, style: const TextStyle(height: 1.45)),
                    ]),
                  ),
                ]),
              ),
            if (it.kind == 'q')
              const Text("Qori: Shayx Mishari Roshid al-Afasiy. Ma'nolar: Alouddin Mansur tarjimasi. O'qilishi taxminiy, asl talaffuzni qori ovozidan oling.",
                  style: TextStyle(color: C.muted, fontSize: 12.5)),
            if (miss.isNotEmpty) ...[
              const SizedBox(height: 12),
              Panel(
                padding: const EdgeInsets.all(12),
                child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
                  const Text("Oldingi safar qiynalgan so'zlaringiz:"),
                  for (final e in miss.take(6)) Text(e.key, style: arabic(20, color: C.bad)),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Tushundim, darsni boshlash'),
              onPressed: () async {
                await App.i.audio.stop();
                if (!context.mounted) return;
                await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LessonScreen(item: it)));
              },
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              OutlinedButton.icon(
                icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                label: Text(_playing ? "To'xtatish" : 'Butunini bir tinglash'),
                onPressed: _hearAll,
              ),
              OutlinedButton.icon(
                icon: Icon(_speaking ? Icons.stop : Icons.record_voice_over_outlined),
                label: Text(_speaking ? "To'xtatish" : "Ma'nosini ovozda tinglash"),
                onPressed: _speakMeaning,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
