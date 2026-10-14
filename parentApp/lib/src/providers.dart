import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'models/alert_model.dart';
import 'models/child_model.dart';
import 'models/geofence_model.dart';
import 'models/limit_model.dart';
import 'models/location_point.dart';
import 'models/photo_model.dart';
import 'models/usage_model.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/command_service.dart';
import 'services/family_service.dart';
import 'services/geofence_service.dart';
import 'services/history_service.dart';
import 'services/limit_service.dart';
import 'services/live_location_service.dart';
import 'services/photo_service.dart';
import 'services/usage_service.dart';

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

final childDocProvider =
    StreamProvider.autoDispose.family<ChildModel?, String>(
  (ref, childId) => ref.watch(familyServiceProvider).watchChild(childId),
);

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

// ───── Bosqich 4 — ekran vaqti + limit + komanda ─────
final usageServiceProvider = Provider<UsageService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return UsageService(FirebaseFirestore.instance, fam.familyId);
});

/// Bugungi ekran vaqti (childId bo'yicha).
final todayUsageProvider =
    StreamProvider.autoDispose.family<UsageModel?, String>((ref, childId) {
  final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return ref.watch(usageServiceProvider).watchDay(childId, dateKey);
});

final limitServiceProvider = Provider<LimitService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return LimitService(FirebaseFirestore.instance, fam.familyId);
});

final dailyLimitProvider =
    StreamProvider.autoDispose.family<DailyLimit, String>(
  (ref, childId) => ref.watch(limitServiceProvider).watch(childId),
);

final commandServiceProvider = Provider<CommandService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return CommandService(FirebaseFirestore.instance, fam.familyId);
});

// ───── Bosqich 5 — oshkora rasm ─────
final photoServiceProvider = Provider<PhotoService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return PhotoService(FirebaseFirestore.instance, fam.familyId);
});

final photosProvider =
    StreamProvider.autoDispose.family<List<PhotoModel>, String>(
  (ref, childId) => ref.watch(photoServiceProvider).watch(childId),
);

// ───── Bosqich 6 — marshrut tarixi ─────
final historyServiceProvider = Provider<HistoryService>((ref) {
  final fam = ref.watch(familyServiceProvider);
  return HistoryService(FirebaseFirestore.instance, fam.familyId);
});

/// (childId, kun) bo'yicha joylashuv tarixi. Kun DATE-only bo'lsin.
final historyProvider = FutureProvider.autoDispose
    .family<List<LocationPoint>, (String, DateTime)>((ref, arg) {
  final (childId, day) = arg;
  return ref.watch(historyServiceProvider).forDay(childId, day);
});
