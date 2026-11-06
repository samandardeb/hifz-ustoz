import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ItemProgress {
  int done;
  int total;
  bool learned;
  int at;
  Map<String, int> miss;
  ItemProgress({this.done = 0, this.total = 0, this.learned = false, this.at = 0, Map<String, int>? miss})
      : miss = miss ?? {};

  Map<String, dynamic> toJson() => {'done': done, 'total': total, 'learned': learned, 'at': at, 'miss': miss};

  factory ItemProgress.fromJson(Map<String, dynamic> j) => ItemProgress(
        done: (j['done'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        learned: j['learned'] == true,
        at: (j['at'] as num?)?.toInt() ?? 0,
        miss: ((j['miss'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      );
}

/// Natijalar shu qurilmada saqlanadi.
class ProgressStore {
  static const _key = 'hifz.progress';
  SharedPreferences? _prefs;
  final Map<String, ItemProgress> items = {};

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      m.forEach((k, v) => items[k] = ItemProgress.fromJson(v as Map<String, dynamic>));
    } catch (_) {}
  }

  ItemProgress? operator [](String id) => items[id];

  ItemProgress of(String id) => items[id] ??= ItemProgress();

  Future<void> save() async {
    await _prefs?.setString(_key, jsonEncode(items.map((k, v) => MapEntry(k, v.toJson()))));
  }

  void markStage(String id, int stageIndex, int total) {
    final p = of(id);
    if (p.total != total && !p.learned) {
      p.total = total;
    }
    if (stageIndex + 1 > p.done) p.done = stageIndex + 1;
    if (stageIndex + 1 >= total && !p.learned) {
      p.learned = true;
      p.at = DateTime.now().millisecondsSinceEpoch;
    }
    save();
  }

  void logMiss(String id, Iterable<String> words) {
    if (words.isEmpty) return;
    final p = of(id);
    for (final w in words) {
      p.miss[w] = (p.miss[w] ?? 0) + 1;
    }
    save();
  }
}
