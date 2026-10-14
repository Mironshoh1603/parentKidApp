import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/child_model.dart';
import 'models/location_point.dart';
import 'services/auth_service.dart';
import 'services/family_service.dart';
import 'services/live_location_service.dart';

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(FirebaseAuth.instance));

final authStateProvider = StreamProvider<User?>(
    (ref) => ref.watch(authServiceProvider).authState());

/// Faqat tizimga kirilgan holatda ishlatiladi (login'dan keyingi daraxt).
final familyServiceProvider = Provider<FamilyService>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    throw StateError('Tizimga kirilmagan — familyServiceProvider');
  }
  return FamilyService(FirebaseFirestore.instance, user.uid);
});

final childrenProvider = StreamProvider.autoDispose<List<ChildModel>>(
    (ref) => ref.watch(familyServiceProvider).watchChildren());

final liveLocationServiceProvider =
    Provider<LiveLocationService>((ref) => LiveLocationService(FirebaseDatabase.instance));

final liveLocationProvider =
    StreamProvider.autoDispose.family<LocationPoint?, String>(
  (ref, childId) => ref.watch(liveLocationServiceProvider).watch(childId),
);
