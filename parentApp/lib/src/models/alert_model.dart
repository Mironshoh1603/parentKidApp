import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertType { sos, geofenceExit, geofenceEnter, lowBattery, offline, unknown }

AlertType alertTypeFromString(String? s) {
  switch (s) {
    case 'sos':
      return AlertType.sos;
    case 'geofence_exit':
      return AlertType.geofenceExit;
    case 'geofence_enter':
      return AlertType.geofenceEnter;
    case 'low_battery':
      return AlertType.lowBattery;
    case 'offline':
      return AlertType.offline;
    default:
      return AlertType.unknown;
  }
}

/// Ogohlantirish — `families/{familyId}/alerts/{id}`.
class AlertModel {
  final String id;
  final AlertType type;
  final String childId;
  final Map<String, dynamic> data;
  final bool read;
  final DateTime timestamp;

  const AlertModel({
    required this.id,
    required this.type,
    required this.childId,
    this.data = const {},
    this.read = false,
    required this.timestamp,
  });

  factory AlertModel.fromMap(String id, Map<String, dynamic> m) {
    return AlertModel(
      id: id,
      type: alertTypeFromString(m['type'] as String?),
      childId: (m['childId'] ?? '') as String,
      data: (m['data'] as Map<String, dynamic>?) ?? const {},
      read: (m['read'] ?? false) as bool,
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
