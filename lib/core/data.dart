import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

import 'arabic.dart';

class Surah {
  final int n;
  final String uz, ar, latin, en;
  final bool madani;
  final int count, juz;
  const Surah(this.n, this.uz, this.ar, this.latin, this.en, this.madani, this.count, this.juz);
}

class Unit {
  final String ar, tr, uz;
  final String? code; // Mishari audio fayli (masalan 112001)
  const Unit(this.ar, this.tr, this.uz, [this.code]);
}

class Item {
  final String id, kind, unitName, title, arTitle, sub, about;
  final int s, f, t, base;
  final List<Unit> units;
  const Item({
    required this.id,
    required this.kind,
    required this.unitName,
    required this.title,
    required this.arTitle,
    required this.sub,
    required this.about,
    required this.units,
    this.s = 0,
    this.f = 0,
    this.t = 0,
    this.base = 0,
  });
}

class Seg {
  final int u, from, to;
  const Seg(this.u, this.from, this.to);
}

class Stage {
  final List<Seg> segs;
  final String kind;
  final bool hide;
  const Stage(this.segs, this.kind, {this.hide = false});
}

class Found {
  final int index;
  final double r;
  final bool pair;
  final double k;
  const Found(this.index, this.r, this.pair, this.k);
}

const aboutText = {
  '1': "Qur'onni ochuvchi sura. Allohga hamd aytiladi, Uning mehribonligi va Qiyomat kunining egasi ekani e'tirof etiladi. Banda faqat Unga ibodat qilib, faqat Undan yordam so'rashini aytadi va to'g'ri yo'lni so'raydi. Har rakat namozda o'qiladi.",
  '112': "Allohning yagonaligi haqida: U hech kimga muhtoj emas, hamma Unga muhtoj. U tug'magan va tug'ilmagan, Unga teng hech kim yo'q.",
  '113': "Yaratilgan narsalar yomonligidan, tun zulmatidan, sehrgarlar va hasadchilar yomonligidan Allohdan panoh so'rash.",
  '114': "Odamlarning Robbi, Podshohi va Ilohi bo'lgan Allohdan inson ko'ngliga yashirincha vasvasa soluvchi jin va odamlar yomonligidan panoh so'rash.",
  '2:255': "Qur'ondagi eng ulug' oyat. Alloh tirik, hech qachon mudramaydi va uxlamaydi; osmon va yerdagi hamma narsa Uniki; ilmi hamma narsani qamrab olgan.",
};

const asmaAbout =
    "Payg'ambarimiz (s.a.v.): \"Allohning to'qson to'qqizta ismi bor. Kim ularni yod olsa, jannatga kiradi\" deganlar (Buxoriy va Muslim rivoyati).";

/// Tavsiya etilgan tartib: Fotiha, keyin 30-pora oxiridan boshiga.
const recommendedPath = [1, 114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95, 94, 93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78];

String _pad(int n) => n.toString().padLeft(3, '0');

class QuranData {
  late final List<Surah> surahs;
  late final List<String> ar, uz, tr;
  late final List<int> offsets;
  late final List<List<String>> asma; // [arabcha, o'qilishi, ma'nosi]

  final Map<int, List<List<int>>> _darsCache = {};
  Map<String, List<int>>? _index;
  List<List<String>>? _normWords;

  Future<void> load() async {
    final q = jsonDecode(await rootBundle.loadString('assets/quran.json')) as Map<String, dynamic>;
    final s = (q['s'] as List).cast<List>();
    surahs = [
      for (var i = 0; i < s.length; i++)
        Surah(i + 1, s[i][0] as String, s[i][1] as String, s[i][2] as String, s[i][3] as String, (s[i][4] as num) == 1,
            (s[i][5] as num).toInt(), (s[i][6] as num).toInt()),
    ];
    ar = (q['ar'] as List).cast<String>();
    uz = (q['uz'] as List).cast<String>();
    tr = (q['tr'] as List).cast<String>();
    var a = 0;
    offsets = [];
    for (final x in surahs) {
      offsets.add(a);
      a += x.count;
    }
    final am = jsonDecode(await rootBundle.loadString('assets/asma.json')) as List;
    asma = [for (final x in am) (x as List).cast<String>()];
  }

  Surah surah(int s) => surahs[s - 1];

  Unit ayah(int s, int a) {
    final i = offsets[s - 1] + a - 1;
    return Unit(ar[i], tr[i], uz[i], _pad(s) + _pad(a));
  }

  (int, int) locate(int i) {
    var s = 0;
    while (s < 113 && offsets[s + 1] <= i) {
      s++;
    }
    return (s + 1, i - offsets[s] + 1);
  }

  /// Sura darslarga bo'linadi: qisqa sura bitta dars, uzuni 5 oyat / 40 so'zdan.
  List<List<int>> darsOf(int s) {
    final cached = _darsCache[s];
    if (cached != null) return cached;
    final n = surah(s).count;
    int wc(int a) => arWords(ayah(s, a).ar).length;
    var total = 0;
    for (var a = 1; a <= n; a++) {
      total += wc(a);
    }
    final out = <List<int>>[];
    if (total <= 45) {
      out.add([1, n]);
    } else {
      var f = 1, cnt = 0, w = 0;
      for (var a = 1; a <= n; a++) {
        final x = wc(a);
        if (cnt > 0 && (cnt >= 5 || w + x > 40)) {
          out.add([f, a - 1]);
          f = a;
          cnt = 0;
          w = 0;
        }
        cnt++;
        w += x;
      }
      out.add([f, n]);
    }
    return _darsCache[s] = out;
  }

  Item quranItem(int s, int f, int t) {
    final su = surah(s);
    final whole = f == 1 && t == su.count;
    return Item(
      id: 'q$s-$f-$t',
      kind: 'q',
      unitName: 'oyat',
      title: '${su.uz} surasi',
      arTitle: su.ar,
      sub: '${su.uz}, ${f == t ? '$f-oyat' : '$f–$t-oyatlar'}',
      about: (whole ? aboutText['$s'] : aboutText['$s:$f']) ?? '',
      units: [for (var a = f; a <= t; a++) ayah(s, a)],
      s: s,
      f: f,
      t: t,
      base: f - 1,
    );
  }

  List<List<int>> get asmaDars => [for (var f = 1; f <= 99; f += 10) [f, math.min(99, f + 9)]];

  Item asmaItem(int f, int t) => Item(
        id: 'asma-$f-$t',
        kind: 'asma',
        unitName: 'ism',
        title: "Allohning go'zal ismlari",
        arTitle: 'الأسماء الحسنى',
        sub: '$f–$t-ismlar',
        about: asmaAbout,
        units: [for (final a in asma.sublist(f - 1, t)) Unit(a[0], a[1], a[2])],
        f: f,
        t: t,
        base: f - 1,
      );

  /// Dars bosqichlari: har oyat butunligicha, oxirida hammasi yoddan.
  List<Stage> stagesFor(Item it) {
    final st = <Stage>[];
    Seg full(int k) => Seg(k, 0, arWords(it.units[k].ar).length - 1);
    for (var k = 0; k < it.units.length; k++) {
      final p = partsOf(it.units[k].ar);
      final nm = '${it.base + k + 1}-${it.unitName}';
      if (p.length > 1) {
        for (var j = 0; j < p.length; j++) {
          st.add(Stage([Seg(k, p[j][0], p[j][1])], '$nm · ${j + 1}/${p.length}-qism'));
        }
        st.add(Stage([full(k)], '$nm · butun ${it.unitName}'));
      } else {
        st.add(Stage([full(k)], nm));
      }
    }
    if (it.units.length > 1 || st.length > 1) {
      st.add(Stage([for (var k = 0; k < it.units.length; k++) full(k)], 'Hammasini yoddan aytish', hide: true));
    } else {
      st.add(Stage([full(0)], 'Yoddan aytish', hide: true));
    }
    return st;
  }

  List<String> stageWords(Item it, Stage st) => [
        for (final g in st.segs) ...arWords(it.units[g.u].ar).sublist(g.from, g.to + 1),
      ];

  // ---------- Eshitilgan qiroatni tanish ----------
  static String _stem(String w) => w
      .replaceFirst(RegExp(r'^(و|ف)'), '')
      .replaceFirst(RegExp(r'^(ب|ل|ك)?ال'), '')
      .replaceFirst(RegExp(r'^لل'), '');

  void _buildIndex() {
    if (_index != null) return;
    final inv = <String, List<int>>{};
    final nw = <List<String>>[];
    for (var i = 0; i < ar.length; i++) {
      final ws = norm(ar[i]).split(' ').where((x) => x.isNotEmpty).toList();
      nw.add(ws);
      for (final t in ws.map(_stem).toSet()) {
        if (t.length < 2) continue;
        (inv[t] ??= []).add(i);
      }
    }
    _index = inv;
    _normWords = nw;
  }

  static double _lcsSim(List<String> h, List<String> w) {
    final m = h.length, n = w.length;
    var p = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      final c = List<int>.filled(n + 1, 0);
      for (var j = 1; j <= n; j++) {
        c[j] = math.max(math.max(p[j], c[j - 1]), p[j - 1] + (sim(h[i - 1], w[j - 1]) >= .72 ? 1 : 0));
      }
      p = c;
    }
    return m == 0 ? 0.0 : p[n] / m;
  }

  List<Found> findAyahs(String text) {
    _buildIndex();
    final inv = _index!, a = _normWords!;
    final h = norm(text).split(' ').where((w) => w.length > 1).toList();
    if (h.length < 2) return [];
    final sc = <int, double>{};
    for (final t in h.map(_stem).toSet()) {
      final l = inv[t];
      if (l == null || l.length > 1500) continue;
      final idf = math.log(6236 / l.length);
      for (final i in l) {
        sc[i] = (sc[i] ?? 0) + idf;
      }
    }
    final cand = (sc.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).take(40).map((e) => e.key);
    final res = <Found>[];
    for (final i in cand) {
      final w = [...a[i], ...(i + 1 < a.length ? a[i + 1] : const <String>[])];
      final alone = _lcsSim(h, a[i]);
      final pairS = _lcsSim(h, w);
      final pair = pairS > alone + .1;
      final r = math.max(alone, pairS * .97);
      final cover = math.min(1.0, h.length / (pair ? w : a[i]).length);
      res.add(Found(i, r, pair, r + 0.2 * cover));
    }
    res.sort((x, y) => y.k.compareTo(x.k));
    final out = <Found>[];
    final seen = <int>{};
    for (final x in res) {
      if (seen.add(x.index)) out.add(x);
      if (out.length >= 3) break;
    }
    return out.where((x) => x.r >= .35).toList();
  }
}
