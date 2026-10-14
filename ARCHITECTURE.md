# Family Safety App — Arxitektura va Reja

> Oshkora (transparent) ota-ona nazorati tizimi. Bola o'z telefonida ilova borligini va
> nima kuzatilayotganini biladi. Maxfiy kamera/audio, ilovani yashirish kabi
> *stalkerware* funksiyalari QO'SHILMAYDI (Google Play siyosati + qonun).

## 1. Umumiy ko'rinish

Ikki Flutter ilovasi, bitta umumiy Firebase backend:

| Ilova | Kim ishlatadi | Vazifasi |
|-------|---------------|----------|
| **parentApp** | Ota-ona | Farzandni xaritada ko'rish, geo-zona, ogohlantirish, limit qo'yish |
| **childApp** | Bola | Joylashuv yuborish, komandalarni bajarish (bloklash, SOS), holat yuborish |

Backend server YOZILMAYDI — faqat Firebase xizmatlari + Cloudinary.

```
myjob/
├── parentApp/        # Flutter — ota-ona ilovasi
├── childApp/         # Flutter — bola ilovasi
├── shared/           # Umumiy Dart paketi (modellar, Firebase servislar) — ixtiyoriy
└── firebase/         # Firestore rules, indexlar, Cloud Functions
```

## 2. Firebase xizmatlari rollari

| Xizmat | Nima uchun |
|--------|-----------|
| **Authentication** | Ota-ona: telefon/email login. Bola qurilmasi: Anonymous Auth + juftlash kodi |
| **Cloud Firestore** | Asosiy ma'lumotlar: oilalar, bolalar, geo-zonalar, ogohlantirishlar, sozlamalar, statistika, tarix |
| **Realtime Database** | Jonli joylashuv oqimi (tez-tez yoziladi, arzon). Firestore'dan ko'ra tejamli |
| **Cloud Messaging (FCM)** | Push bildirishnoma. ⚠️ Spark'da *yuborish* server kaliti talab qiladi (Functions/Blaze). Shuning uchun MVP'da push O'RNIGA Firestore realtime listener ishlatamiz (pastga qarang) |
| ~~**Cloud Functions**~~ | ⚠️ **Blaze talab qiladi — MVP'da ISHLATILMAYDI.** Geofence tekshirish va komandalarni client-side qilamiz. Keyin Blaze'ga o'tilganda server tomonga ko'chiriladi |
| **Crashlytics** | Xatolarni kuzatish |

**Cloudinary** — media fayllar (profil rasmi, SOS/check-in rasmi). Firebase Storage o'rniga,
chunki Cloudinary bepul tieri kattaroq va Storage Blaze plan talab qiladi.

### ⚠️ Spark (bepul) plan oqibati — push o'rniga realtime listener
Spark'da server (Cloud Functions) yo'q, FCM *yuborish* uchun maxfiy kalit kerak bo'lgani uchun
client'dan push yubora olmaymiz. Shuning uchun:
- **childApp** doimiy **foreground service** ishlatadi (joylashuv uchun shundoq ham kerak),
  shu service ichida Firestore `commands` va geofence'ni **realtime tinglaydi** → push shart emas.
- **parentApp** ochiq (yoki fonda) bo'lganda `alerts`/jonli joylashuvni realtime tinglaydi +
  mahalliy bildirishnoma (`flutter_local_notifications`) chiqaradi.
- Ilova **butunlay yopilganda** parentApp'ga push — bu Blaze (Functions) ga o'tilgandagina.
  MVP shu cheklov bilan ishlaydi.

## 3. Ma'lumotlar modeli (Firestore)

```
families/{familyId}
  parentUid: string
  name: string
  createdAt: timestamp

families/{familyId}/children/{childId}
  name: string
  avatarUrl: string          # Cloudinary URL
  pairingCode: string        # 6 xonali, juftlashdan keyin o'chiriladi
  paired: bool
  deviceId: string
  fcmToken: string
  lastSeen: timestamp
  batteryLevel: int
  isCharging: bool
  isOnline: bool
  soundOn: bool

families/{familyId}/children/{childId}/locations/{autoId}   # TARIX
  lat, lng, accuracy, speed: number
  timestamp: timestamp

families/{familyId}/geofences/{geofenceId}
  name: string
  lat, lng, radius: number
  alertOnEnter, alertOnExit: bool

families/{familyId}/alerts/{alertId}
  type: "sos" | "geofence_exit" | "geofence_enter" | "low_battery" | "offline"
  childId: string
  data: map
  read: bool
  timestamp: timestamp

families/{familyId}/children/{childId}/usage/{yyyy-mm-dd}
  totalScreenTime: int        # sekund
  apps: [{ package, label, duration }]

families/{familyId}/children/{childId}/limits/{packageName}
  dailyLimit: int             # sekund
  blocked: bool

families/{familyId}/children/{childId}/commands/{commandId}
  type: "lock" | "unlock" | "ring" | "request_location" | "request_photo"
  status: "pending" | "done"
  createdAt: timestamp

families/{familyId}/children/{childId}/photos/{photoId}
  url: string                 # Cloudinary URL
  source: "sos" | "checkin"
  createdAt: timestamp
```

### Realtime Database (jonli joylashuv)
```
/live/{childId}: { lat, lng, ts, battery, speed }
```
childApp bu tugunni tez-tez (masalan 10–30 s) yangilaydi; parentApp real vaqtda tinglaydi.
Tarix uchun esa Firestore `locations` ga kamroq (masalan har 1–5 daqiqa) yoziladi.

## 4. Juftlash (pairing) oqimi

1. Ota-ona parentApp'da "Farzand qo'shish" → ism kiritadi → tizim 6 xonali `pairingCode` yaratadi.
2. Bolaning telefoniga childApp o'rnatiladi → kod kiritiladi.
3. childApp Anonymous Auth bilan kiradi, kodni tekshiradi (Cloud Function yoki security rules),
   `deviceId` + `fcmToken` ni o'z `child` hujjatiga yozadi, `paired = true`.
4. `pairingCode` o'chiriladi. Bola ekranida "Ota-onangiz kuzatmoqda" ochiq yozuvi doimo ko'rinadi.

## 5. childApp — fon ishlashi (Android-birinchi)

- **Fon joylashuv**: `geolocator` + `flutter_background_service` (foreground service, doimiy bildirishnoma bilan — oshkoralik talabi).
- **FCM komanda tinglash**: bloklash/SOS/joylashuv so'rovi push orqali keladi.
- **Ilova ishlatish statistikasi**: Android `UsageStatsManager` (`PACKAGE_USAGE_STATS` — foydalanuvchi qo'lda ruxsat beradi).
- **Telefonni bloklash**: Device Admin / Accessibility yoki overlay ekran (dars vaqtida).
- **Batareya/internet holati**: `battery_plus`, `connectivity_plus`.

### ⚠️ iOS cheklovlari
iOS'da fon joylashuv ishlaydi, lekin ilova ishlatishni kuzatish va telefonni bloklash
tizim tomonidan cheklangan (Screen Time / FamilyControls maxsus entitlement talab qiladi).
Shu sabab childApp **Android-birinchi** rejalashtiriladi; iOS'da faqat joylashuv + SOS.

## 6. Xavfsizlik (Firestore Security Rules — tamoyil)

- Ota-ona faqat `parentUid == auth.uid` bo'lgan `families/...` ga kira oladi.
- Bola qurilmasi (anonymous) faqat o'zining `child` hujjatiga va uning ost-kolleksiyalariga
  yoza oladi (`locations`, `usage`, holat maydonlari), boshqa oilalarga emas.
- `commands` ni faqat ota-ona yaratadi, bola faqat `status` ni `done` ga o'zgartiradi.

## 7. Bosqichma-bosqich reja (MVP → to'liq)

**Bosqich 0 — Setup**
- [ ] Firebase loyiha, ikkala ilovaga `google-services.json`
- [ ] Flutter loyihalar: parentApp, childApp
- [ ] Auth (ota-ona) + Anonymous (bola)

**Bosqich 1 — Juftlash + jonli joylashuv (MVP yadrosi)**
- [ ] Farzand qo'shish + pairing kod
- [ ] childApp fon joylashuv → Realtime DB
- [ ] parentApp xaritada jonli ko'rsatish (Google Maps)

**Bosqich 2 — Geo-zona + ogohlantirish**
- [ ] Geo-zona yaratish, enter/exit aniqlash (Cloud Function)
- [ ] FCM push + alerts ro'yxati

**Bosqich 3 — Holat + SOS**
- [ ] Batareya/internet/online holati
- [ ] SOS tugmasi (bola) → push + alert

**Bosqich 4 — Ekran vaqti + limit**
- [ ] UsageStats yig'ish → Firestore
- [ ] Ilovaga limit, dars vaqtida bloklash

**Bosqich 5 — Oshkora foto (SOS/check-in)**
- [ ] Ota-ona `request_photo` komandasi → bola ekranida **"Ota-onangizga rasm yuborilmoqda"** yozuvi
- [ ] Bola rasm oladi (yoki SOS bilan avtomatik) → Cloudinary'ga yuklanadi → `photos` kolleksiyasi
- [ ] parentApp'da rasmlar galereyasi
- [ ] ⚠️ Maxfiy emas — bola har doim xabardor (Play Store talabi)

**Bosqich 6 — Tarix + sozlash**
- [ ] Marshrut tarixi xaritada
- [ ] Profil rasmlari (Cloudinary), sozlamalar

## 8. Asosiy Flutter paketlari

| Maqsad | Paket |
|--------|-------|
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`, `firebase_messaging` |
| Joylashuv | `geolocator`, `flutter_background_service` |
| Xarita | `google_maps_flutter` |
| Holat | `battery_plus`, `connectivity_plus` |
| Media | `cloudinary_public` (yoki to'g'ridan-to'g'ri REST upload) |
| State mgmt | `riverpod` (yoki `provider`/`bloc`) |

## 9. Ochiq savollar / keyin hal qilinadi

- Xarita: Google Maps API kaliti kerak (billing). Alternativa: OpenStreetMap (`flutter_map`) — bepul.
- Cloud Functions Blaze plan talab qiladi — geofence/push logikasini client-side qilish mumkinmi?
- iOS chiqariladimi yoki faqat Android?
