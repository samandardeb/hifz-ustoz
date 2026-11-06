import 'package:flutter/material.dart';

import '../app.dart';
import '../core/data.dart';
import 'intro.dart';
import 'surah.dart';

class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key});
  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  @override
  void dispose() {
    App.i.audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = App.i.data;
    final dars = data.asmaDars;
    return Scaffold(
      appBar: AppBar(title: Text('Allohning 99 ismi', style: heading(20))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text('الأسماء الحسنى', textDirection: TextDirection.rtl, style: arabic(28, color: C.gold)),
            const SizedBox(height: 6),
            const Text(asmaAbout, style: TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 14),
            const MethodCard(darsCount: 10, unit: 'ism'),
            const SizedBox(height: 16),
            const Label('Darslar'),
            const SizedBox(height: 8),
            for (var i = 0; i < dars.length; i++)
              DarsCard(
                index: i,
                range: '${dars[i][0]}–${dars[i][1]}-ismlar',
                preview: '${data.asma[dars[i][0] - 1][0]} · ${data.asma[dars[i][1] - 1][0]}',
                progress: App.i.progress['asma-${dars[i][0]}-${dars[i][1]}'],
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => IntroScreen(item: data.asmaItem(dars[i][0], dars[i][1]))));
                  if (mounted) setState(() {});
                },
              ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text("Barcha 99 ism ma'nosi bilan", style: heading(16)),
                children: [
                  for (var i = 0; i < data.asma.length; i++)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: ProgressRing(value: 0, label: '${i + 1}'),
                      title: Text('${data.asma[i][1]} — ${data.asma[i][2]}'),
                      trailing: Text(data.asma[i][0], textDirection: TextDirection.rtl, style: arabic(20, color: C.gold)),
                      onTap: () => App.i.audio.speakArabic(data.asma[i][0], rate: 0.6),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
