import 'dart:math' as math;

/// Geo-zona (xavfsiz hudud) — `families/{familyId}/geofences/{id}`.
class GeofenceModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radius; // metr
  final bool alertOnEnter;
  final bool alertOnExit;

  const GeofenceModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.radius = 150,
    this.alertOnEnter = true,
    this.alertOnExit = true,
  });

  factory GeofenceModel.fromMap(String id, Map<String, dynamic> m) {
    return GeofenceModel(
      id: id,
      name: (m['name'] ?? '') as String,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      radius: (m['radius'] as num?)?.toDouble() ?? 150,
      alertOnEnter: (m['alertOnEnter'] ?? true) as bool,
      alertOnExit: (m['alertOnExit'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'alertOnEnter': alertOnEnter,
        'alertOnExit': alertOnExit,
      };

  /// Berilgan nuqta shu zona ichidami? (Haversine masofasi, metrda).
  bool contains(double pLat, double pLng) =>
      _distanceMeters(lat, lng, pLat, pLng) <= radius;

  static double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const earth = 6371000.0; // metr
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
