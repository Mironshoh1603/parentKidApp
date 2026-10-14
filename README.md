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

## Boshlash

Har bir ilova papkasida:

```bash
flutter pub get
flutterfire configure   # Firebase'ga ulash (firebase login kerak)
flutter run
```
