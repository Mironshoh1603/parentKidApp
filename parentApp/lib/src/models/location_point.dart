import 'package:cloud_firestore/cloud_firestore.dart';

/// Joylashuv nuqtasi. Jonli joylashuv (Realtime DB) va tarix (Firestore
/// `locations` ost-kolleksiyasi) uchun ham ishlatiladi.
class LocationPoint {
  final double lat;
  final double lng;
  final double accuracy;
  final double speed;
  final DateTime timestamp;

  const LocationPoint({
    required this.lat,
    required this.lng,
    this.accuracy = 0,
    this.speed = 0,
    required this.timestamp,
  });

  /// Realtime Database `/live/{childId}` tugunidan (ms epoch bilan).
  factory LocationPoint.fromRtdb(Map<dynamic, dynamic> m) {
    return LocationPoint(
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0,
      speed: (m['speed'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (m['ts'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  /// Firestore `locations` hujjatidan.
  factory LocationPoint.fromMap(Map<String, dynamic> m) {
    return LocationPoint(
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      accuracy: (m['accuracy'] as num?)?.toDouble() ?? 0,
      speed: (m['speed'] as num?)?.toDouble() ?? 0,
      timestamp: (m['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'speed': speed,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  Map<String, dynamic> toRtdb() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'speed': speed,
        'ts': timestamp.millisecondsSinceEpoch,
      };
}
