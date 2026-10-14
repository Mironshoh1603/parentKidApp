import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_paths.dart';
import '../models/geofence_model.dart';
import '../models/location_point.dart';

const _channelId = 'location_channel';
const _notifId = 888;
const _tick = Duration(seconds: 20); // RTDB jonli yangilash oralig'i
const _historyEvery = 3; // har 3-tick (~1 daqiqa) Firestore tarixiga yoziladi

/// Fon joylashuv servisini sozlaydi (foreground service, oshkora bildirishnoma bilan).
/// Juftlashdan keyin [startReporting] bilan ishga tushiriladi.
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
  var counter = 0;

  // Geo-zonalar va oldingi holat (kirgan/chiqqan) — xotirada saqlanadi.
  var geofences = <GeofenceModel>[];
  final lastInside = <String, bool>{};
  var lowBatteryAlerted = false;

  fs.collection(FsPaths.geofences(familyId)).snapshots().listen((snap) {
    geofences = snap.docs
        .map((d) => GeofenceModel.fromMap(d.id, d.data()))
        .toList();
  });

  Future<void> addAlert(String type, Map<String, dynamic> data) async {
    await fs.collection(FsPaths.alerts(familyId)).add({
      'type': type,
      'childId': childId,
      'data': data,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Timer.periodic(_tick, (timer) async {
    // Anonim auth yo'qolgan bo'lsa yozmaymiz (yangi uid olmaymiz — childAuthUid buziladi).
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

      // Jonli joylashuv (RTDB) — har tick.
      await rtdb.ref(FsPaths.liveLocation(childId)).set(point.toRtdb());

      // Geo-zona kirish/chiqishni mahalliy aniqlaymiz (Spark — Functions yo'q).
      for (final g in geofences) {
        final inside = g.contains(point.lat, point.lng);
        final prev = lastInside[g.id];
        if (prev != null && prev != inside) {
          await addAlert(inside ? 'geofence_enter' : 'geofence_exit',
              {'geofenceId': g.id, 'geofenceName': g.name});
        }
        lastInside[g.id] = inside;
      }

      // Batareya holati + kam batareya ogohlantirishi.
      final level = await battery.batteryLevel;
      if (level <= 15 && !lowBatteryAlerted) {
        lowBatteryAlerted = true;
        await addAlert('low_battery', {'level': level});
      } else if (level > 20) {
        lowBatteryAlerted = false;
      }

      // Tarix (Firestore) — kamroq.
      counter++;
      if (counter % _historyEvery == 0) {
        await fs
            .collection(FsPaths.locations(familyId, childId))
            .add(point.toFirestore());

        final state = await battery.batteryState;
        final charging = state == BatteryState.charging ||
            state == BatteryState.full;
        await fs.doc(FsPaths.child(familyId, childId)).set({
          'lastSeen': FieldValue.serverTimestamp(),
          'batteryLevel': level,
          'isCharging': charging,
          'isOnline': true,
        }, SetOptions(merge: true));
      }

      // Bildirishnomani yangilab turamiz (oshkoralik).
      if (service is AndroidServiceInstance) {
        final t = point.timestamp;
        final hhmm =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        service.setForegroundNotificationInfo(
          title: 'Nazorat yoqilgan',
          content: 'Oxirgi joylashuv: $hhmm',
        );
      }
    } catch (_) {
      // Tarmoq yoki ruxsat xatosi — keyingi tick'da qayta urinadi.
    }
  });
}
