import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/location_point.dart';

/// Joylashuv tarixi (marshrut) — ota-ona tomoni.
class HistoryService {
  final FirebaseFirestore _db;
  final String familyId;

  HistoryService(this._db, this.familyId);

  /// Berilgan kun uchun joylashuv nuqtalari (vaqt bo'yicha tartiblangan).
  /// Diqqat: `timestamp` bo'yicha range + orderBy — kompozit indeks shart emas.
  Future<List<LocationPoint>> forDay(String childId, DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection(FsPaths.locations(familyId, childId))
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThan: Timestamp.fromDate(end))
        .orderBy('timestamp')
        .get();
    return snap.docs.map((d) => LocationPoint.fromMap(d.data())).toList();
  }
}
