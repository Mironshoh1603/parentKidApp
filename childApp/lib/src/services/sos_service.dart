import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_paths.dart';

/// Bola SOS yuboradi — joylashuv bilan ogohlantirish yaratadi (OSHKORA).
class SosService {
  final FirebaseFirestore _db;
  SosService(this._db);

  Future<bool> sendSos() async {
    if (FirebaseAuth.instance.currentUser == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final familyId = prefs.getString('familyId');
    final childId = prefs.getString('childId');
    if (familyId == null || childId == null) return false;

    Map<String, dynamic> data = {};
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      data = {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      // Joylashuv olinmasa ham SOS yuboriladi.
    }

    await _db.collection(FsPaths.alerts(familyId)).add({
      'type': 'sos',
      'childId': childId,
      'data': data,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    return true;
  }
}
