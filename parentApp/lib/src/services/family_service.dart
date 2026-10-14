import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/child_model.dart';

/// Oila va bolalarni boshqarish. `familyId == parentUid` (har ota-onaga bitta oila).
class FamilyService {
  final FirebaseFirestore _db;
  final String uid; // = familyId

  FamilyService(this._db, this.uid);

  String get familyId => uid;

  DocumentReference<Map<String, dynamic>> get _familyRef =>
      _db.doc(FsPaths.family(uid));

  CollectionReference<Map<String, dynamic>> get _childrenRef =>
      _db.collection(FsPaths.children(uid));

  /// Birinchi kirishda oila hujjatini yaratadi (mavjud bo'lsa — tegmaydi).
  Future<void> ensureFamily() async {
    await _familyRef.set({
      'parentUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<ChildModel>> watchChildren() {
    return _childrenRef.orderBy('name').snapshots().map(
          (snap) => snap.docs
              .map((d) => ChildModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Stream<ChildModel?> watchChild(String childId) {
    return _childrenRef.doc(childId).snapshots().map(
        (d) => d.exists ? ChildModel.fromMap(d.id, d.data()!) : null);
  }

  /// Yangi farzand qo'shadi va juftlash kodi yaratadi. Kodni qaytaradi.
  Future<String> addChild(String name) async {
    final childRef = _childrenRef.doc();
    final code = await _generateUniqueCode();
    await _writePairing(code, childRef.id, childName: name, childRef: childRef);
    return code;
  }

  /// Mavjud (juftlanmagan) farzand uchun kodni qayta yaratadi.
  Future<String> regenerateCode(String childId) async {
    final childRef = _childrenRef.doc(childId);
    final code = await _generateUniqueCode();
    await _writePairing(code, childId, childRef: childRef);
    return code;
  }

  Future<void> _writePairing(
    String code,
    String childId, {
    String? childName,
    required DocumentReference<Map<String, dynamic>> childRef,
  }) async {
    final batch = _db.batch();
    if (childName != null) {
      batch.set(childRef, {
        'name': name_(childName),
        'paired': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.set(_db.doc('pairings/$code'), {
      'parentUid': uid,
      'familyId': uid,
      'childId': childId,
      'claimedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: 15)),
      ),
    });
    await batch.commit();
  }

  static String name_(String s) => s.trim();

  Future<String> _generateUniqueCode() async {
    final rnd = Random.secure();
    for (var i = 0; i < 8; i++) {
      final code = (rnd.nextInt(900000) + 100000).toString(); // 100000..999999
      final exists = (await _db.doc('pairings/$code').get()).exists;
      if (!exists) return code;
    }
    // Juda kam ehtimol — vaqt asosidagi zaxira.
    return (DateTime.now().millisecondsSinceEpoch % 900000 + 100000).toString();
  }
}
