import 'dart:math' as math;

/// Arabcha matnni solishtirish uchun: harakatlar olib tashlanadi, harflar bir xillashtiriladi.
final _diacritics = RegExp(r'[ؐ-ًؚ-ٰٟۖ-ۭـ]');

String norm(String s) => s
    .replaceAll(_diacritics, '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ء', '')
    .replaceAll(RegExp(r'[^ء-ي\s]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Oyatdagi so'zlar (vaqf belgilari tashlab yuboriladi).
List<String> arWords(String ar) =>
    ar.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && norm(w).isNotEmpty).toList();

bool isMark(String w) => norm(w).isEmpty;

int lev(String a, String b) {
  final m = a.length, n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  var p = List<int>.generate(n + 1, (i) => i);
  for (var i = 1; i <= m; i++) {
    final c = List<int>.filled(n + 1, 0);
    c[0] = i;
    for (var j = 1; j <= n; j++) {
      c[j] = math.min(math.min(p[j] + 1, c[j - 1] + 1), p[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1));
    }
    p = c;
  }
  return p[n];
}

final _alPrefix = RegExp(r'^(و|ف)?ال');

double sim(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final r1 = 1 - lev(a, b) / math.max(a.length, b.length);
  final a2 = a.replaceFirst(_alPrefix, ''), b2 = b.replaceFirst(_alPrefix, '');
  final r2 = (a2.isNotEmpty && b2.isNotEmpty) ? 1 - lev(a2, b2) / math.max(a2.length, b2.length) : 0.0;
  return math.max(r1, r2);
}

class ScoreResult {
  final List<bool> words;
  final double ratio;
  const ScoreResult(this.words, this.ratio);
}

/// Aytilgan matnni kutilgan so'zlar bilan solishtiradi: qaysi so'z to'g'ri, qaysi biri xato.
ScoreResult score(List<String> target, String heard) {
  final t = target.map(norm).toList();
  final h = norm(heard).split(' ').where((x) => x.isNotEmpty).toList();
  var j = 0;
  final res = <bool>[];
  for (var ti = 0; ti < t.length; ti++) {
    final w = t[ti];
    var best = 0.0;
    var bi = -1;
    var span = 1;
    for (var k = j; k < math.min(h.length, j + 4); k++) {
      final s1 = sim(w, h[k]);
      if (s1 > best) {
        best = s1;
        bi = k;
        span = 1;
      }
      if (k + 1 < h.length) {
        final s2 = sim(w, h[k] + h[k + 1]);
        if (s2 > best) {
          best = s2;
          bi = k;
          span = 2;
        }
      }
      final nxt = ti + 1 < t.length ? t[ti + 1] : '';
      final s3 = sim(w + nxt, h[k]);
      if (s3 > best + .05) {
        best = s3;
        bi = k;
        span = 1;
      }
    }
    if (best >= .6) {
      j = bi + span;
      res.add(true);
    } else {
      res.add(false);
    }
  }
  final ok = res.where((x) => x).length;
  return ScoreResult(res, t.isEmpty ? 0.0 : ok / t.length);
}

/// Juda uzun oyatlarni (18 so'zdan ortiq) 10–14 so'zli katta qismlarga bo'ladi.
List<List<int>> partsOf(String ar) {
  final toks = ar.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final w = arWords(ar);
  if (w.length <= 18) return [[0, w.length - 1]];
  final n = (w.length / 14).ceil();
  final size = (w.length / n).ceil();
  final stops = <int>{};
  var wi = 0;
  for (final t in toks) {
    if (isMark(t)) {
      stops.add(wi - 1);
    } else {
      wi++;
    }
  }
  final out = <List<int>>[];
  var f = 0;
  while (f < w.length) {
    var t = math.min(w.length - 1, f + size - 1);
    for (var d = 0; d <= 4; d++) {
      if (stops.contains(t - d) && t - d >= f + 7) {
        t = t - d;
        break;
      }
      if (stops.contains(t + d) && t + d < w.length - 1 && t + d - f < 20) {
        t = t + d;
        break;
      }
    }
    if (w.length - 1 - t < 6) t = w.length - 1;
    out.add([f, t]);
    f = t + 1;
  }
  return out;
}

/// O'zbekcha lotin matnni ruscha ovoz o'qiy oladigan kirill yozuviga o'giradi.
String uzToCyr(String input) {
  final t = input.replaceAll(RegExp('[‘’ʻʼ`]'), "'");
  const digraphs = [
    ["o'", 'у'], ["O'", 'У'], ["g'", 'г'], ["G'", 'Г'], ['sh', 'ш'], ['Sh', 'Ш'], ['SH', 'Ш'],
    ['ch', 'ч'], ['Ch', 'Ч'], ['CH', 'Ч'], ['yo', 'ё'], ['Yo', 'Ё'], ['yu', 'ю'], ['Yu', 'Ю'],
    ['ya', 'я'], ['Ya', 'Я'], ['ye', 'е'], ['Ye', 'Е'],
  ];
  const single = {
    'a': 'а', 'b': 'б', 'd': 'д', 'e': 'е', 'f': 'ф', 'g': 'г', 'h': 'х', 'i': 'и', 'j': 'ж',
    'k': 'к', 'l': 'л', 'm': 'м', 'n': 'н', 'o': 'о', 'p': 'п', 'q': 'к', 'r': 'р', 's': 'с',
    't': 'т', 'u': 'у', 'v': 'в', 'x': 'х', 'y': 'й', 'z': 'з', 'c': 'к', 'w': 'в',
  };
  final latin = RegExp(r"[a-zA-Z']");
  final letter = RegExp('[a-zA-Z]');
  final out = StringBuffer();
  var i = 0;
  while (i < t.length) {
    List<String>? hit;
    for (final d in digraphs) {
      if (t.startsWith(d[0], i)) {
        hit = d;
        break;
      }
    }
    if (hit != null) {
      out.write(hit[1]);
      i += hit[0].length;
      continue;
    }
    final ch = t[i];
    final lo = ch.toLowerCase();
    if (lo == 'e' && (i == 0 || !latin.hasMatch(t[i - 1]))) {
      out.write(ch == lo ? 'э' : 'Э');
      i++;
      continue;
    }
    if (ch == "'") {
      final prevL = i > 0 && letter.hasMatch(t[i - 1]);
      final nextL = i + 1 < t.length && letter.hasMatch(t[i + 1]);
      out.write(prevL && nextL ? 'ъ' : ch);
      i++;
      continue;
    }
    final c = single[lo];
    if (c != null) {
      out.write(ch == lo ? c : c.toUpperCase());
    } else {
      out.write(ch);
    }
    i++;
  }
  return out.toString();
}

/// Talaffuz yordamchisi: qiyin harflar va belgilar.
class LetterTip {
  final String sign, name, how;
  const LetterTip(this.sign, this.name, this.how);
}

const letterTips = [
  LetterTip('ع', "'ayn", "Bo'g'izning o'rtasidan chiqadi. Tomoqni biroz siqib \"a\" deysiz."),
  LetterTip('ح', "ha (bo'g'iz)", "Bo'g'iz o'rtasidan, xirillamasdan issiq nafas bilan \"h\"."),
  LetterTip('خ', 'xo', "O'zbekcha \"x\" ga yaqin, til orqasi bilan, yo'g'on aytiladi."),
  LetterTip('غ', "g'oyn", "O'zbekcha \"g'\" tovushi, yo'g'on aytiladi."),
  LetterTip('ق', 'qof', "Tilning eng orqa qismi tanglayga tegadi, yo'g'on chiqadi."),
  LetterTip('ص', 'sod', "Yo'g'on \"s\": til orqasi ko'tariladi."),
  LetterTip('ض', 'zod', "Yo'g'on tovush: tilning yon qirrasi yuqori oziq tishlarga tegadi."),
  LetterTip('ط', 'to', "Yo'g'on \"t\", ovoz \"to\" kabi qalin."),
  LetterTip('ظ', 'zo', "Yo'g'on \"z\": til uchi old tishlar orasiga chiqadi."),
  LetterTip('ث', 'sa', "Yumshoq \"s\": til uchi old tishlar orasida."),
  LetterTip('ذ', 'zal', "Yumshoq \"z\": til uchi old tishlar orasida."),
  LetterTip('ه', 'ha (yengil)', "Yengil \"h\": bo'g'izni siqmasdan."),
];

List<LetterTip> tipsForWord(String w) {
  final bare = w.replaceAll(_diacritics, '');
  final out = letterTips.where((l) => bare.contains(l.sign)).toList();
  if (RegExp('[ءأإؤئ]').hasMatch(w)) {
    out.add(const LetterTip('ء', 'hamza', "Bo'g'izda qisqa to'xtash: unli oldidan nafas bir lahza uziladi."));
  }
  if (w.contains('ّ')) {
    out.add(const LetterTip('ـّ', 'Tashdid', 'Belgili harf ikki marta, bosib aytiladi.'));
  }
  if (RegExp('[ٰٓ]|َا|ُو|ِي').hasMatch(w)) {
    out.add(const LetterTip('ـٰ', "Cho'zish (madd)", "Unli ikki baravar cho'zib aytiladi."));
  }
  return out;
}

class TipWithExample {
  final LetterTip tip;
  final String example;
  const TipWithExample(this.tip, this.example);
}

List<TipWithExample> tipsFor(List<String> words) {
  final seen = <String, TipWithExample>{};
  for (final w in words) {
    for (final t in tipsForWord(w)) {
      seen.putIfAbsent(t.name, () => TipWithExample(t, w));
    }
  }
  return seen.values.toList();
}
