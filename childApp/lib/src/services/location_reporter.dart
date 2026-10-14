import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_paths.dart';
import '../models/geofence_model.dart';
import '../models/location_point.dart';
import 'usage_service.dart';

const _channelId = 'location_channel';
const _notifId = 888;
const _tick = Duration(seconds: 20); // RTDB jonli yangilash oralig'i
const _historyEvery = 3; // har 3-tick (~1 daqiqa) Firestore tarixiga yoziladi
const _usageEvery = 6; // har 6-tick (~2 daqiqa) ekran vaqti o'qiladi/yoziladi

String _todayKey() => DateFormat('yyyy-MM-dd').format(DateTime.now());

/// Fon servisi — joylashuv (Bosqich 1-3) + ekran vaqti/qulflash (Bosqich 4).
/// Doimiy foreground service, OSHKORA bildirishnoma bilan.
class LocationReporter {
  static Future<void> configure() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // juftlashdan keyin qo'lda boshlanadi
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Nazorat yoqilgan',
        initialNotificationContent: 'Ota-onangiz joylashuvni ko\'rmoqda',
        foregroundServiceNotificationId: _notifId,
        foregroundServiceTypes: const [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  static Future<void> startReporting() async {
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
  }

  static void stopReporting() {
    FlutterBackgroundService().invoke('stop');
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp();

  service.on('stop').listen((_) => service.stopSelf());

  final prefs = await SharedPreferences.getInstance();
  final familyId = prefs.getString('familyId');
  final childId = prefs.getString('childId');
  if (familyId == null || childId == null) {
    service.stopSelf();
    return;
  }

  final rtdb = FirebaseDatabase.instance;
  final fs = FirebaseFirestore.instance;
  final battery = Battery();
  final usageService = UsageService();
  var counter = 0;

  // Geo-zonalar va oldingi holat (kirgan/chiqqan) — xotirada saqlanadi.
  var geofences = <GeofenceModel>[];
  final lastInside = <String, bool>{};
  var lowBatteryAlerted = false;
  DateTime? lastPointTime;

  // ───── Bosqich 4 — ekran vaqti / qulflash holati ─────
  var dailyLimitSec = 0; // 0 = cheklovsiz
  var limitEnabled = false;
  var manualLock = false; // ota-ona "lock" komandasi
  String? limitSnoozedDate; // shu kun limit qulfi o'chirilgan
  var overlayActive = false;
  var todayUsageSeconds = 0;
  var photoPending = false;
  var lockedState = false;
  bool? lastLockedWritten;
  var currentDay = _todayKey();

  Future<void> addAlert(String type, Map<String, dynamic> data) async {
    await fs.collection(FsPaths.alerts(familyId)).add({
      'type': type,
      'childId': childId,
      'data': data,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void updateNotification() {
    if (service is! AndroidServiceInstance) return;
    String title = 'Nazorat yoqilgan';
    String content;
    if (photoPending) {
      title = 'Ota-onangiz rasm so\'radi';
      content = 'Ilovani oching va rasm yuboring';
    } else if (lockedState) {
      title = 'Qurilma qulflangan';
      content = 'Ota-onangiz ekran vaqtini cheklab qo\'ydi';
    } else {
      final t = lastPointTime;
      final hhmm = t == null
          ? '—'
          : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      content = 'Oxirgi joylashuv: $hhmm';
    }
    service.setForegroundNotificationInfo(title: title, content: content);
  }

  // Joylashuvni bir marta o'qib yuboradi (jonli + ixtiyoriy tarix).
  Future<void> reportLocation({required bool writeHistory}) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LocationPoint(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        timestamp: DateTime.now(),
      );
      lastPointTime = point.timestamp;

      await rtdb.ref(FsPaths.liveLocation(childId)).set(point.toRtdb());

      // Geo-zona kirish/chiqishni mahalliy aniqlaymiz.
      for (final g in geofences) {
        final inside = g.contains(point.lat, point.lng);
        final prev = lastInside[g.id];
        if (prev != null && prev != inside) {
          await addAlert(inside ? 'geofence_enter' : 'geofence_exit',
              {'geofenceId': g.id, 'geofenceName': g.name});
        }
        lastInside[g.id] = inside;
      }

      final level = await battery.batteryLevel;
      if (level <= 15 && !lowBatteryAlerted) {
        lowBatteryAlerted = true;
        await addAlert('low_battery', {'level': level});
      } else if (level > 20) {
        lowBatteryAlerted = false;
      }

      if (writeHistory) {
        await fs
            .collection(FsPaths.locations(familyId, childId))
            .add(point.toFirestore());
        final state = await battery.batteryState;
        final charging =
            state == BatteryState.charging || state == BatteryState.full;
        await fs.doc(FsPaths.child(familyId, childId)).set({
          'lastSeen': FieldValue.serverTimestamp(),
          'batteryLevel': level,
          'isCharging': charging,
          'isOnline': true,
        }, SetOptions(merge: true));
      }
    } catch (_) {
      // Tarmoq yoki ruxsat xatosi — keyingi tick'da qayta urinadi.
    }
  }

  // Qulflash holatini hisoblaydi va qoplama (overlay)ni boshqaradi.
  Future<void> applyLock() async {
    final shouldLock = manualLock ||
        (limitEnabled &&
            dailyLimitSec > 0 &&
            todayUsageSeconds >= dailyLimitSec &&
            limitSnoozedDate != _todayKey());
    lockedState = shouldLock;

    if (shouldLock && !overlayActive) {
      try {
        if (await FlutterOverlayWindow.isPermissionGranted()) {
          await FlutterOverlayWindow.showOverlay(
            height: WindowSize.fullCover,
            width: WindowSize.matchParent,
            flag: OverlayFlag.defaultFlag,
            enableDrag: false,
            overlayTitle: 'Qurilma qulflangan',
            overlayContent: 'Ota-onangiz ekran vaqtini cheklab qo\'ydi',
          );
          overlayActive = true;
        }
      } catch (_) {}
    } else if (!shouldLock && overlayActive) {
      try {
        await FlutterOverlayWindow.closeOverlay();
      } catch (_) {}
      overlayActive = false;
    }

    if (lastLockedWritten != shouldLock) {
      lastLockedWritten = shouldLock;
      try {
        await fs
            .doc(FsPaths.child(familyId, childId))
            .set({'locked': shouldLock}, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  // ───── Listenerlar ─────
  fs.collection(FsPaths.geofences(familyId)).snapshots().listen((snap) {
    geofences =
        snap.docs.map((d) => GeofenceModel.fromMap(d.id, d.data())).toList();
  });

  fs
      .collection(FsPaths.limits(familyId, childId))
      .doc('_daily')
      .snapshots()
      .listen((d) async {
    final m = d.data();
    limitEnabled = (m?['enabled'] ?? false) as bool;
    dailyLimitSec = ((m?['dailyLimitMinutes'] as num?)?.toInt() ?? 0) * 60;
    await applyLock();
  });

  fs
      .collection(FsPaths.commands(familyId, childId))
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .listen((snap) async {
    photoPending = false;
    for (final d in snap.docs) {
      final type = d.data()['type'] as String?;
      switch (type) {
        case 'lock':
          manualLock = true;
          await d.reference.update({'status': 'done'});
          break;
        case 'unlock':
          manualLock = false;
          limitSnoozedDate = _todayKey(); // qolgan kun limit qayta qulflamasin
          await d.reference.update({'status': 'done'});
          break;
        case 'request_location':
          await reportLocation(writeHistory: true);
          await d.reference.update({'status': 'done'});
          break;
        case 'ring':
          // Minimal: bildirishnoma orqali e'tibor. (To'liq jiringlash keyin.)
          await d.reference.update({'status': 'done'});
          break;
        case 'request_photo':
          // UI (CheckinScreen) bajaradi — bu yerda faqat belgilaymiz.
          photoPending = true;
          break;
        default:
          await d.reference.update({'status': 'done'});
      }
    }
    await applyLock();
    updateNotification();
  });

  // ───── Davriy sikl ─────
  Timer.periodic(_tick, (timer) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    counter++;

    // Kun almashsa — limit "snooze" ni tiklaymiz.
    final today = _todayKey();
    if (today != currentDay) {
      currentDay = today;
      limitSnoozedDate = null;
    }

    // Ekran vaqtini o'qish/yozish (kamroq).
    if (counter == 1 || counter % _usageEvery == 0) {
      try {
        final list = await usageService.todayUsage();
        todayUsageSeconds = usageService.totalSeconds(list);
        await usageService.reportToday(fs, familyId, childId);
      } catch (_) {}
    }

    await applyLock();
    await reportLocation(writeHistory: counter % _historyEvery == 0);
    updateNotification();
  });
}
