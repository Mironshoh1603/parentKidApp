import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/firestore_paths.dart';

class PairResult {
  final bool ok;
  final String? error;
  const PairResult(this.ok, [this.error]);
}

/// Bola qurilmasini oilaga ulaydi (anonymous auth + 6 xonali kod).
class PairingService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  PairingService(this._auth, this._db);

  /// Anonim foydalanuvchini ta'minlaydi (uid barqaror saqlanadi).
  Future<User> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<bool> isPaired() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('familyId') != null) &&
        (prefs.getString('childId') != null);
  }

  Future<(String familyId, String childId)?> savedPair() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString('familyId');
    final c = prefs.getString('childId');
    if (f == null || c == null) return null;
    return (f, c);
  }

  Future<String> _deviceId() async {
    try {
      final info = DeviceInfoPlugin();
      final android = await info.androidInfo;
      return android.id;
    } catch (_) {
      return 'unknown';
    }
  }

  /// 6 xonali kod orqali juftlaydi.
  Future<PairResult> pairWithCode(String code) async {
    code = code.trim();
    if (code.length != 6) return const PairResult(false, 'Kod 6 xonali bo\'lishi kerak');

    final user = await ensureSignedIn();
    final uid = user.uid;
    final pairingRef = _db.doc('pairings/$code');

    try {
      final snap = await pairingRef.get();
      if (!snap.exists) return const PairResult(false, 'Kod topilmadi');
      final data = snap.data()!;

      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
        return const PairResult(false, 'Kod muddati tugagan');
      }
      if (data['claimedBy'] != null) {
        return const PairResult(false, 'Kod allaqachon ishlatilgan');
      }

      final familyId = data['familyId'] as String;
      final childId = data['childId'] as String;

      // 1) pairing'ni egalaymiz
      await pairingRef.update({'claimedBy': uid});

      // 2) child hujjatiga egalikni yozamiz (rules validClaim tekshiradi)
      await _db.doc(FsPaths.child(familyId, childId)).set({
        'childAuthUid': uid,
        'deviceId': await _deviceId(),
        'paired': true,
        'pairCode': code,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3) pairing'ni o'chiramiz
      await pairingRef.delete();

      // 4) lokal saqlaymiz
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('familyId', familyId);
      await prefs.setString('childId', childId);

      return const PairResult(true);
    } on FirebaseException catch (e) {
      return PairResult(false, 'Firebase xatosi: ${e.code}');
    } catch (e) {
      return PairResult(false, 'Xatolik: $e');
    }
  }
}
