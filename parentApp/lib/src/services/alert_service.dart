import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/alert_model.dart';

/// Ogohlantirishlarni o'qish/boshqarish (ota-ona tomoni).
class AlertService {
  final FirebaseFirestore _db;
  final String familyId;

  AlertService(this._db, this.familyId);

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(FsPaths.alerts(familyId));

  Stream<List<AlertModel>> watch({int limit = 100}) {
    return _ref
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AlertModel.fromMap(d.id, d.data())).toList());
  }

  Stream<int> unreadCount() {
    return _ref
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> markRead(String id) => _ref.doc(id).update({'read': true});

  Future<void> markAllRead() async {
    final snap = await _ref.where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
