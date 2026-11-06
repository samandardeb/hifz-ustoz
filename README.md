# Hifz Ustoz — Flutter ilovasi

Qur'on suralari va Allohning 99 ismini ma'nosi bilan yodlash ustozi.

## Ilovada nimalar bor

- **Suralar**: 114 sura. Nomi, raqami, `2:255` ko'rinishida yoki ma'nosi bo'yicha qidiriladi.
- **Dars tartibi**: har oyatni Ustoz (Shayx Mishari Roshid al-Afasiy) 3 marta o'qiydi. Keyin u bilan birga 3 marta o'qiladi. So'ng o'quvchi "Aytib ko'rish"ni bosib o'zi aytadi. Ilova talaffuzni tekshiradi: to'g'ri bo'lsa keyingi oyatga o'tkazadi, xato bo'lsa qayta tinglatib, yana aytishga majbur qiladi. Oxirida butun dars yoddan aytiladi.
- **Allohning 99 ismi**: 10 tadan 10 ta dars, xuddi shu tartibda.
- **Eshitgan qiroatni tanish**: 7 soniya tinglaydi, o'zi to'xtaydi va qaysi suraning nechanchi oyati ekanini topadi.
- **Ma'nosini ovozda tinglash**: o'zbekcha ovoz bo'lmasa, matn kirillga o'girilib ruscha ovozda o'qiladi.
- **Natijalarim**: nechta sura va nechta ism yodlangani. Natijalar telefonning o'zida saqlanadi.

## Kompyuterga kerakli dasturlar (bir marta o'rnatiladi)

1. **Flutter SDK**: https://docs.flutter.dev/get-started/install. 3.22 yoki undan yangi versiya kerak.
2. **Android Studio** (Android SDK uchun): https://developer.android.com/studio
3. Terminalda tekshiring: `flutter doctor`. Android qatorlarida ✓ belgisi bo'lishi kerak.

## Ishga tushirish

1. Arxivni oching va papkaga kiring.
2. Sozlash skriptini bir marta ishga tushiring. U Android papkalarini yaratadi, mikrofon va internet ruxsatlarini qo'shadi:
   - Windows: `setup.bat` ni ikki marta bosing.
   - macOS / Linux: `./setup.sh`
3. Planshetni USB orqali ulang. Planshetda: Sozlamalar → Planshet haqida → MIUI versiyasini 7 marta bosing → Qo'shimcha sozlamalar → Dasturchilar uchun → **USB orqali tuzatish** ni yoqing.
4. Ilovani ishga tushiring: `flutter run`

## APK yig'ish (planshetga o'rnatish uchun)

```
flutter build apk --release
```

Tayyor fayl shu yerda bo'ladi: `build/app/outputs/flutter-apk/app-release.apk`. Uni planshetga ko'chirib o'rnating. Xiaomi "noma'lum manbadan o'rnatish"ga ruxsat so'raydi, ruxsat bering.

Play Market'ga chiqarish uchun ilovani o'z kalitingiz bilan imzolash kerak: https://docs.flutter.dev/deployment/android

## Muhim

- **Internet kerak.** Mishari qiroati internetdan (everyayah.com) olinadi, ovozni tanish Google xizmati orqali ishlaydi.
- **Google ilovasi** telefonda o'rnatilgan va yangilangan bo'lishi kerak, ovozni tanish shunga tayanadi.
- Birinchi marta "Aytib ko'rish" bosilganda ilova **mikrofon ruxsatini** so'raydi, ruxsat bering.
- Arabcha ismlar va o'zbekcha ma'nolarni ovozda o'qish uchun: Sozlamalar → Tillar va kiritish → Matnni nutqqa aylantirish → Google → arab va rus tillarini yuklab oling.
- "Ustoz batafsil tushuntirsin" (AI) bu versiyada yo'q. Uni qo'shish uchun Claude API kaliti va server kerak.

## iPhone / iPad uchun

`setup.sh` iOS papkasini ham yaratadi. Xcode'da `ios/Runner/Info.plist` fayliga quyidagilarni qo'shing:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Oyatni to'g'ri o'qiganingizni tekshirish uchun</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Ovozingizni matnga aylantirib tekshirish uchun</string>
```

## Loyiha tuzilishi

```
lib/
  main.dart            ilova kirish nuqtasi
  app.dart             umumiy holat, ranglar, umumiy vidjetlar
  core/arabic.dart     arabcha matnni solishtirish, oyatni qismlarga bo'lish, kirillga o'girish
  core/data.dart       sura va oyatlar, darslar, dars bosqichlari, qiroatni tanish
  core/audio.dart      Mishari qiroati va sun'iy ovoz
  core/speech.dart     ovozni tanish (speech_to_text)
  core/progress.dart   natijalarni saqlash
  screens/             sahifalar: bosh sahifa, suralar, dars, 99 ism, qiroatni tanish, natijalar
assets/quran.json      Qur'on matni, o'qilishi, Alouddin Mansur tarjimasi
assets/asma.json       Allohning 99 ismi
android_patch/         ruxsatlar qo'shilgan AndroidManifest.xml
test/logic_test.dart   tekshiruv mantig'i testlari: flutter test
```

Eslatma: ilova yodlashga yordam beradi. Dasturda o'qilgan suralar Qur'on xatmi hisoblanmaydi.
