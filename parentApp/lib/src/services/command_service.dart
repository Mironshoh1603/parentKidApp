import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';

/// Bola qurilmasiga komanda yuborish (ota-ona tomoni).
/// Komandalar Firestore'da `commands` kolleksiyasiga yoziladi; bola qurilmasi
/// fon servisida ularni realtime tinglaydi (Spark plan — FCM push o'rniga).
class CommandService {
  final FirebaseFirestore _db;
  final String familyId;

  CommandService(this._db, this.familyId);

  Future<void> send(String childId, String type) {
    return _db.collection(FsPaths.commands(familyId, childId)).add({
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> lock(String childId) => send(childId, 'lock');
  Future<void> unlock(String childId) => send(childId, 'unlock');
  Future<void> requestPhoto(String childId) => send(childId, 'request_photo');
  Future<void> requestLocation(String childId) =>
      send(childId, 'request_location');
  Future<void> ring(String childId) => send(childId, 'ring');
}
