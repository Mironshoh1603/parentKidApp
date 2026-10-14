import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/location_point.dart';
import '../../providers.dart';

/// Marshrut tarixi xaritada (Bosqich 6) — ota-ona tomoni.
class HistoryScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;
  const HistoryScreen(
      {super.key, required this.childId, required this.childName});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _map = MapController();
  late DateTime _day = _dateOnly(DateTime.now());
  DateTime? _lastFitDay;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _day = _dateOnly(picked);
        _lastFitDay = null; // qayta markazlashtiramiz
      });
    }
  }

  void _fit(List<LatLng> pts) {
    if (pts.isEmpty || _lastFitDay == _day) return;
    _lastFitDay = _day;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(48),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hist = ref.watch(historyProvider((widget.childId, _day)));
    final dateLabel = DateFormat('dd MMM yyyy').format(_day);

    return Scaffold(
      appBar: AppBar(
        title: Text('Marshrut — ${widget.childName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionChip(
              avatar: const Icon(Icons.calendar_today, size: 18),
              label: Text(dateLabel),
              onPressed: _pickDate,
            ),
          ),
        ),
      ),
      body: hist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (points) {
          if (points.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Bu kun uchun marshrut tarixi topilmadi.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final latlngs =
              points.map((p) => LatLng(p.lat, p.lng)).toList();
          _fit(latlngs);
          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: latlngs.first,
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'uz.bros.parent_app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: latlngs,
                        strokeWidth: 4,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latlngs.first,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.trip_origin,
                            color: Colors.green, size: 32),
                      ),
                      Marker(
                        point: latlngs.last,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _StatsCard(points: points),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final List<LocationPoint> points;
  const _StatsCard({required this.points});

  double get _km {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += _distanceMeters(points[i - 1], points[i]);
    }
    return total / 1000.0;
  }

  static double _distanceMeters(LocationPoint a, LocationPoint b) {
    const earth = 6371000.0;
    final dLat = _rad(b.lat - a.lat);
    final dLon = _rad(b.lng - a.lng);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.lat)) *
            math.cos(_rad(b.lat)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earth * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _rad(double d) => d * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final first = DateFormat('HH:mm').format(points.first.timestamp.toLocal());
    final last = DateFormat('HH:mm').format(points.last.timestamp.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat(context, Icons.place, '${points.length}', 'nuqta'),
            _stat(context, Icons.straighten, _km.toStringAsFixed(1), 'km'),
            _stat(context, Icons.schedule, '$first–$last', 'oraliq'),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
