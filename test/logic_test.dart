import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_ustoz/core/arabic.dart';

void main() {
  test("To'g'ri o'qilgan oyat qabul qilinadi", () {
    final words = arWords('قُلْ هُوَ اللَّهُ أَحَدٌ');
    expect(score(words, 'قل هو الله احد').ratio, 1.0);
  });

  test("Chala o'qilgan oyat rad etiladi", () {
    final words = arWords('قُلْ هُوَ اللَّهُ أَحَدٌ');
    expect(score(words, 'قل هو الله').ratio < .8, true);
  });

  test("Qisqa oyat bo'linmaydi", () {
    expect(partsOf('الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ').length, 1);
  });

  test("Lotin yozuvi kirillga o'giriladi", () {
    expect(uzToCyr("O'quvchi g'ayrat bilan"), 'Укувчи гайрат билан');
  });
}
