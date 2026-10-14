# parentKidApp

Oilaviy xavfsizlik (oshkora ota-ona nazorati) tizimi — ikki Flutter ilovasi, bitta
Firebase backend + Cloudinary. Ota-ona farzandining joylashuvi va xavfsizligini
kuzatadi; **farzand ilova borligini va nima kuzatilayotganini biladi** (maxfiy/stalkerware
funksiyalar yo'q).

## Tuzilma

| Papka | Ilova |
|-------|-------|
| [`parentApp/`](parentApp) | Ota-ona ilovasi — xarita, geo-zona, ogohlantirish, limit |
| [`childApp/`](childApp) | Bola ilovasi — joylashuv yuborish, SOS, komandalarni bajarish |

## Texnologiyalar

- **Flutter** (Android-birinchi; childApp iOS'da cheklangan)
- **Firebase** — Auth, Firestore, Realtime Database (jonli joylashuv), FCM
- **Cloudinary** — rasm (profil, SOS/check-in)
- **flutter_map** (OpenStreetMap) — xarita
- **Riverpod** — holat boshqaruvi

To'liq arxitektura va reja: [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Holat

Bosqich 1–6 kodi yozilgan (ikkala ilova `flutter analyze` toza, debug APK quriladi):

1. Juftlash + jonli joylashuv + OSM xarita
2. Geo-zona + ogohlantirishlar
3. SOS + onlayn/batareya holati
4. Ekran vaqti + kunlik limit + masofadan qulflash
5. Oshkora check-in rasm (Cloudinary)
6. Marshrut tarixi (xaritada)

## Boshlash

Har bir ilova papkasida:

```bash
flutter pub get
flutterfire configure   # Firebase'ga ulash (firebase login kerak)
flutter run
```

### Sozlash kerak (ishga tushirishdan oldin)

1. **Firebase** — `firebase login`, so'ng Console'da loyiha + Auth(Email/Password) +
   Firestore + Realtime Database yarating. `flutterfire configure` ni har ikkala ilovada
   ishga tushiring, qoidalarni joylang: `firebase deploy --only firestore:rules,database`.
2. **Cloudinary** (Bosqich 5 rasm uchun) — `childApp/lib/src/core/cloudinary_config.dart`
   ichida `cloudName` va `unsignedPreset` ni to'ldiring (imzosiz upload preset).

### Bola telefonida ruxsatlar (oshkora)

- **Joylashuv** — "Doim ruxsat etilsin".
- **Ekran vaqti** (Usage access) — ilova ichidagi tugma Sozlamalarni ochadi.
- **Ustidan ko'rsatish** (Display over other apps) — qulflash qoplamasi uchun.
