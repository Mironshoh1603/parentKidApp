import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/child_model.dart';
import '../../models/location_point.dart';
import '../../providers.dart';
import '../history/history_screen.dart';
import '../photos/photos_screen.dart';
import '../usage/usage_screen.dart';

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

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _toggleLock(bool locked) async {
    final cmd = ref.read(commandServiceProvider);
    if (locked) {
      await cmd.unlock(widget.child.id);
      _snack('Qulfni ochish buyrug\'i yuborildi');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Qurilma qulflansinmi?'),
        content: const Text(
            'Bolaning telefonida oshkora qulf ekrani ko\'rsatiladi. '
            'SOS baribir ishlaydi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Qulflash')),
        ],
      ),
    );
    if (ok != true) return;
    await cmd.lock(widget.child.id);
    _snack('Qulflash buyrug\'i yuborildi');
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _menu(String v) async {
    final cmd = ref.read(commandServiceProvider);
    switch (v) {
      case 'usage':
        _push(UsageScreen(
            childId: widget.child.id, childName: widget.child.name));
        break;
      case 'history':
        _push(HistoryScreen(
            childId: widget.child.id, childName: widget.child.name));
        break;
      case 'photos':
        _push(PhotosScreen(
            childId: widget.child.id, childName: widget.child.name));
        break;
      case 'request_photo':
        await cmd.requestPhoto(widget.child.id);
        _snack('Rasm so\'rovi yuborildi. Bola ko\'rib yuboradi.');
        break;
      case 'request_location':
        await cmd.requestLocation(widget.child.id);
        _snack('Joylashuvni yangilash so\'rovi yuborildi');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveLocationProvider(widget.child.id));
    final zones = ref.watch(geofencesProvider).value ?? const [];
    final doc = ref.watch(childDocProvider(widget.child.id)).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.child.name),
        actions: [
          if (doc != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                children: [
                  Icon(
                    doc.isCharging
                        ? Icons.battery_charging_full
                        : Icons.battery_full,
                    size: 20,
                    color: doc.batteryLevel < 20 ? Colors.red : null,
                  ),
                  const SizedBox(width: 4),
                  Center(child: Text('${doc.batteryLevel}%')),
                ],
              ),
            ),
          if (doc != null)
            IconButton(
              tooltip: doc.locked ? 'Qulfni ochish' : 'Qulflash',
              icon: Icon(doc.locked ? Icons.lock : Icons.lock_open,
                  color: doc.locked ? Colors.red : null),
              onPressed: () => _toggleLock(doc.locked),
            ),
          PopupMenuButton<String>(
            onSelected: _menu,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'usage',
                child: ListTile(
                  leading: Icon(Icons.timelapse),
                  title: Text('Ekran vaqti'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.route),
                  title: Text('Marshrut tarixi'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'photos',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Rasmlar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'request_photo',
                child: ListTile(
                  leading: Icon(Icons.add_a_photo),
                  title: Text('Rasm so\'rash'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'request_location',
                child: ListTile(
                  leading: Icon(Icons.my_location),
                  title: Text('Joylashuvni yangilash'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
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
                  CircleLayer(
                    circles: [
                      for (final g in zones)
                        CircleMarker(
                          point: LatLng(g.lat, g.lng),
                          radius: g.radius,
                          useRadiusInMeter: true,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderColor: Theme.of(context).colorScheme.primary,
                          borderStrokeWidth: 1.5,
                        ),
                    ],
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
