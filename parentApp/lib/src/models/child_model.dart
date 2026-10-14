import 'package:cloud_firestore/cloud_firestore.dart';

/// Bola (farzand) modeli — `families/{familyId}/children/{childId}`.
class ChildModel {
  final String id;
  final String name;
  final String? avatarUrl; // Cloudinary URL
  final bool paired;
  final String? deviceId;
  final String? fcmToken;
  final DateTime? lastSeen;
  final int batteryLevel;
  final bool isCharging;
  final bool isOnline;
  final bool soundOn;

  const ChildModel({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.paired = false,
    this.deviceId,
    this.fcmToken,
    this.lastSeen,
    this.batteryLevel = 0,
    this.isCharging = false,
    this.isOnline = false,
    this.soundOn = true,
  });

  factory ChildModel.fromMap(String id, Map<String, dynamic> m) {
    return ChildModel(
      id: id,
      name: (m['name'] ?? '') as String,
      avatarUrl: m['avatarUrl'] as String?,
      paired: (m['paired'] ?? false) as bool,
      deviceId: m['deviceId'] as String?,
      fcmToken: m['fcmToken'] as String?,
      lastSeen: (m['lastSeen'] as Timestamp?)?.toDate(),
      batteryLevel: (m['batteryLevel'] ?? 0) as int,
      isCharging: (m['isCharging'] ?? false) as bool,
      isOnline: (m['isOnline'] ?? false) as bool,
      soundOn: (m['soundOn'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'avatarUrl': avatarUrl,
        'paired': paired,
        'deviceId': deviceId,
        'fcmToken': fcmToken,
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
        'batteryLevel': batteryLevel,
        'isCharging': isCharging,
        'isOnline': isOnline,
        'soundOn': soundOn,
      };
}
