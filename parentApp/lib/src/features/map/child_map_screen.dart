import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/child_model.dart';
import '../../models/location_point.dart';
import '../../providers.dart';

/// Bolaning jonli joylashuvini OpenStreetMap xaritasida ko'rsatadi.
class ChildMapScreen extends ConsumerStatefulWidget {
  final ChildModel child;
  const ChildMapScreen({super.key, required this.child});

  @override
  ConsumerState<ChildMapScreen> createState() => _ChildMapScreenState();
}

class _ChildMapScreenState extends ConsumerState<ChildMapScreen> {
  final _map = MapController();
  bool _followed = false;

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveLocationProvider(widget.child.id));

    return Scaffold(
      appBar: AppBar(title: Text(widget.child.name)),
      body: live.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (point) {
          if (point == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Joylashuv hali yo\'q.\nBolaning telefonida ilova ochiq va '
                  'joylashuv ruxsati berilganiga ishonch hosil qiling.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final pos = LatLng(point.lat, point.lng);
          // Birinchi nuqta kelganda markazga olamiz.
          if (!_followed) {
            _followed = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _map.move(pos, 16);
            });
          }
          return Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCenter: pos,
                  initialZoom: 16,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'uz.bros.parent_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: pos,
                        width: 48,
                        height: 48,
                        child: Icon(Icons.location_on,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _InfoCard(point: point),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final p = live.value;
          if (p != null) _map.move(LatLng(p.lat, p.lng), 16);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final LocationPoint point;
  const _InfoCard({required this.point});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(point.timestamp.toLocal());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Text('Oxirgi: $time'),
            const Spacer(),
            const Icon(Icons.speed, size: 18),
            const SizedBox(width: 8),
            Text('${(point.speed * 3.6).toStringAsFixed(0)} km/s'),
          ],
        ),
      ),
    );
  }
}
