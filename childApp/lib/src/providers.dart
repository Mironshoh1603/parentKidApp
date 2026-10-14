import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/firestore_paths.dart';
import 'services/cloudinary_service.dart';
import 'services/command_service.dart';
import 'services/pairing_service.dart';
import 'services/photo_service.dart';
import 'services/usage_service.dart';

final pairingServiceProvider = Provider<PairingService>(
  (ref) => PairingService(FirebaseAuth.instance, FirebaseFirestore.instance),
);

/// Qurilma juftlanganmi? (anonim auth ta'minlanadi, so'ng lokal tekshiriladi)
final pairedProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(pairingServiceProvider);
  await svc.ensureSignedIn();
  return svc.isPaired();
});

/// Saqlangan juftlik (familyId, childId) — lokaldan.
final savedPairProvider = FutureProvider<(String, String)?>(
  (ref) => ref.watch(pairingServiceProvider).savedPair(),
);

final usageServiceProvider = Provider<UsageService>((ref) => UsageService());

final photoServiceProvider = Provider<PhotoService>(
  (ref) => PhotoService(FirebaseFirestore.instance, CloudinaryService()),
);

/// Juftlik ma'lum bo'lsa — komanda servisi.
final childCommandServiceProvider =
    Provider.autoDispose<ChildCommandService?>((ref) {
  final pair = ref.watch(savedPairProvider).value;
  if (pair == null) return null;
  final (fid, cid) = pair;
  return ChildCommandService(FirebaseFirestore.instance, fid, cid);
});

/// Ota-ona rasm so'raganmi? (pending `request_photo` komanda id'si yoki null)
final pendingPhotoRequestProvider = StreamProvider.autoDispose<String?>((ref) {
  final pair = ref.watch(savedPairProvider).value;
  if (pair == null) return Stream.value(null);
  final (fid, cid) = pair;
  return FirebaseFirestore.instance
      .collection(FsPaths.commands(fid, cid))
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) {
    for (final d in s.docs) {
      if (d.data()['type'] == 'request_photo') return d.id;
    }
    return null;
  });
});
