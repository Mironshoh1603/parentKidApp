import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/alert_model.dart';
import 'models/child_model.dart';
import 'models/geofence_model.dart';
import 'models/location_point.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/family_service.dart';
import 'services/geofence_service.dart';
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

// ───── Geo-zonalar ─────
final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return GeofenceService(FirebaseFirestore.instance, fam.familyId);
});

final geofencesProvider = StreamProvider.autoDispose<List<GeofenceModel>>(
    (ref) => ref.watch(geofenceServiceProvider).watch());

// ───── Ogohlantirishlar ─────
final alertServiceProvider = Provider<AlertService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return AlertService(FirebaseFirestore.instance, fam.familyId);
});

final alertsProvider = StreamProvider.autoDispose<List<AlertModel>>(
    (ref) => ref.watch(alertServiceProvider).watch());

final unreadAlertsProvider = StreamProvider.autoDispose<int>(
    (ref) => ref.watch(alertServiceProvider).unreadCount());
