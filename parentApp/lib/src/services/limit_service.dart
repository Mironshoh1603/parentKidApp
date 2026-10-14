import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/limit_model.dart';

/// Kunlik ekran vaqti limiti (ota-ona tomoni).
class LimitService {
  final FirebaseFirestore _db;
  final String familyId;

  LimitService(this._db, this.familyId);

  DocumentReference<Map<String, dynamic>> _ref(String childId) =>
      _db.collection(FsPaths.limits(familyId, childId)).doc('_daily');

  Stream<DailyLimit> watch(String childId) =>
      _ref(childId).snapshots().map((d) => DailyLimit.fromMap(d.data()));

  Future<void> save(String childId, DailyLimit limit) =>
      _ref(childId).set(limit.toMap(), SetOptions(merge: true));
}
