import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/firestore_paths.dart';
import '../models/usage_model.dart';

/// Ekran vaqti statistikasini o'qish (ota-ona tomoni).
class UsageService {
  final FirebaseFirestore _db;
  final String familyId;

  UsageService(this._db, this.familyId);

  /// Berilgan kun uchun ishlatish statistikasi (`yyyy-MM-dd`).
  Stream<UsageModel?> watchDay(String childId, String dateKey) {
    return _db
        .collection(FsPaths.usage(familyId, childId))
        .doc(dateKey)
        .snapshots()
        .map((d) =>
            d.exists ? UsageModel.fromMap(d.id, d.data()!) : null);
  }
}
