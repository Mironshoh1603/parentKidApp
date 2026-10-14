/// Bitta ilovaning ishlatilish vaqti.
class AppUsageEntry {
  final String package;
  final String label;
  final int duration; // sekund

  const AppUsageEntry({
    required this.package,
    required this.label,
    required this.duration,
  });

  factory AppUsageEntry.fromMap(Map<String, dynamic> m) => AppUsageEntry(
        package: (m['package'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        duration: (m['duration'] as num?)?.toInt() ?? 0,
      );
}

/// Kunlik ekran vaqti — `families/{fid}/children/{cid}/usage/{yyyy-MM-dd}`.
class UsageModel {
  final String date; // yyyy-MM-dd
  final int totalScreenTime; // sekund
  final List<AppUsageEntry> apps;

  const UsageModel({
    required this.date,
    this.totalScreenTime = 0,
    this.apps = const [],
  });

  factory UsageModel.fromMap(String date, Map<String, dynamic> m) {
    final raw = (m['apps'] as List?) ?? const [];
    final apps = raw
        .whereType<Map>()
        .map((e) => AppUsageEntry.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    return UsageModel(
      date: date,
      totalScreenTime: (m['totalScreenTime'] as num?)?.toInt() ?? 0,
      apps: apps,
    );
  }
}
