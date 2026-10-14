import 'package:firebase_database/firebase_database.dart';

import '../core/firestore_paths.dart';
import '../models/location_point.dart';

/// Realtime Database'dan bolaning jonli joylashuvini tinglaydi.
class LiveLocationService {
  final FirebaseDatabase _db;
  LiveLocationService(this._db);

  Stream<LocationPoint?> watch(String childId) {
    return _db.ref(FsPaths.liveLocation(childId)).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      return LocationPoint.fromRtdb(value);
    });
  }
}
