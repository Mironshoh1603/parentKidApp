import 'package:cloud_firestore/cloud_firestore.dart';

/// Joylashuv nuqtasi. Realtime DB (jonli) va Firestore (tarix) uchun.
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

  Map<String, dynamic> toRtdb() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'speed': speed,
        'ts': timestamp.millisecondsSinceEpoch,
      };

  Map<String, dynamic> toFirestore() => {
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'speed': speed,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
