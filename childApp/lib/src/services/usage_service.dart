import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:app_usage/app_usage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../core/firestore_paths.dart';

/// Ilovadan foydalanish (ekran vaqti) statistikasi.
/// Android `UsageStatsManager` — `PACKAGE_USAGE_STATS` ruxsati kerak (foydalanuvchi
/// Sozlamalardan qo'lda beradi). Bu OSHKORA: bola ruxsat berayotganini biladi.
class UsageService {
  final AppUsage _appUsage = AppUsage();

  /// Bugungi (yarim tundan hozirgacha) ilova ishlatish ro'yxati.
  Future<List<AppUsageInfo>> todayUsage() async {
    if (!Platform.isAndroid) return const [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      return await _appUsage.getAppUsage(start, now);
    } catch (_) {
      // Ruxsat yo'q yoki xato — bo'sh ro'yxat.
      return const [];
    }
  }

  /// Ruxsat berilganmi (evristik: bugun ma'lumot o'qib bo'ladimi)?
  Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    final now = DateTime.now();
    try {
      final r = await _appUsage.getAppUsage(
          now.subtract(const Duration(days: 1)), now);
      return r.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Ruxsat berish ekranini ochadi (Settings → Usage access).
  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;
    const intent = AndroidIntent(action: 'android.settings.USAGE_ACCESS_SETTINGS');
    await intent.launch();
  }

  /// Bugungi umumiy ekran vaqti (sekund).
  int totalSeconds(List<AppUsageInfo> list) =>
      list.fold(0, (acc, e) => acc + e.usage.inSeconds);

  /// Firestore'ga bugungi statistikani yozadi (`usage/{yyyy-MM-dd}`).
  /// [topN] — eng ko'p ishlatilgan ilovalar soni.
  Future<int> reportToday(
    FirebaseFirestore db,
    String familyId,
    String childId, {
    int topN = 15,
  }) async {
    final list = await todayUsage();
    if (list.isEmpty) return 0;
    list.sort((a, b) => b.usage.inSeconds.compareTo(a.usage.inSeconds));
    final apps = list
        .take(topN)
        .map((e) => {
              'package': e.packageName,
              'label': e.appName,
              'duration': e.usage.inSeconds,
            })
        .toList();
    final total = totalSeconds(list);
    final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await db.collection(FsPaths.usage(familyId, childId)).doc(dateKey).set({
      'totalScreenTime': total,
      'apps': apps,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return total;
  }
}
