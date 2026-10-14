import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';

/// Bola tomoni — ota-onadan kelgan komandalarni UI darajasida boshqarish
/// (masalan `request_photo` — kamera UI kerak). Qurilma darajasidagi komandalar
/// (lock/unlock/ring/request_location) fon servisida bajariladi.
class ChildCommandService {
  final FirebaseFirestore _db;
  final String familyId;
  final String childId;

  ChildCommandService(this._db, this.familyId, this.childId);

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(FsPaths.commands(familyId, childId));

  /// Bajarilmagan (pending) komandalar oqimi.
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchPending() {
    return _ref
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) => s.docs);
  }

  Future<void> markDone(String id) => _ref.doc(id).update({'status': 'done'});
}
