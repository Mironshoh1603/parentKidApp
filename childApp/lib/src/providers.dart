import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/pairing_service.dart';

final pairingServiceProvider = Provider<PairingService>(
  (ref) => PairingService(FirebaseAuth.instance, FirebaseFirestore.instance),
);

/// Qurilma juftlanganmi? (anonim auth ta'minlanadi, so'ng lokal tekshiriladi)
final pairedProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(pairingServiceProvider);
  await svc.ensureSignedIn();
  return svc.isPaired();
});
