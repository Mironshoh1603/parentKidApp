import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/photo_model.dart';

/// Oshkora rasmlarni o'qish/o'chirish (ota-ona tomoni).
/// Rasm so'rash `CommandService.requestPhoto` orqali amalga oshiriladi.
class PhotoService {
  final FirebaseFirestore _db;
  final String familyId;

  PhotoService(this._db, this.familyId);

  CollectionReference<Map<String, dynamic>> _ref(String childId) =>
      _db.collection(FsPaths.photos(familyId, childId));

  Stream<List<PhotoModel>> watch(String childId, {int limit = 60}) {
    return _ref(childId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => PhotoModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> delete(String childId, String photoId) =>
      _ref(childId).doc(photoId).delete();
}
