import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/geofence_model.dart';

/// Geo-zonalarni boshqarish (ota-ona tomoni).
class GeofenceService {
  final FirebaseFirestore _db;
  final String familyId;

  GeofenceService(this._db, this.familyId);

  CollectionReference<Map<String, dynamic>> get _ref =>
      _db.collection(FsPaths.geofences(familyId));

  Stream<List<GeofenceModel>> watch() {
    return _ref.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => GeofenceModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> add(GeofenceModel g) => _ref.add(g.toMap());

  Future<void> update(GeofenceModel g) => _ref.doc(g.id).update(g.toMap());

  Future<void> delete(String id) => _ref.doc(id).delete();
}
