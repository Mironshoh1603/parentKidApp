/// Kunlik ekran vaqti limiti — `families/{fid}/children/{cid}/limits/_daily`.
class DailyLimit {
  final bool enabled;
  final int dailyLimitMinutes;

  const DailyLimit({this.enabled = false, this.dailyLimitMinutes = 120});

  factory DailyLimit.fromMap(Map<String, dynamic>? m) => DailyLimit(
        enabled: (m?['enabled'] ?? false) as bool,
        dailyLimitMinutes: (m?['dailyLimitMinutes'] as num?)?.toInt() ?? 120,
      );

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'dailyLimitMinutes': dailyLimitMinutes,
      };

  DailyLimit copyWith({bool? enabled, int? dailyLimitMinutes}) => DailyLimit(
        enabled: enabled ?? this.enabled,
        dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      );
}
