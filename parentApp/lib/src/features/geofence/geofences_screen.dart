import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/geofence_model.dart';
import '../../providers.dart';

/// Geo-zonalarni xaritada yaratish/ko'rish/o'chirish.
class GeofencesScreen extends ConsumerStatefulWidget {
  const GeofencesScreen({super.key});

  @override
  ConsumerState<GeofencesScreen> createState() => _GeofencesScreenState();
}

class _GeofencesScreenState extends ConsumerState<GeofencesScreen> {
  static const _defaultCenter = LatLng(41.311081, 69.279737); // Toshkent

  LatLng? _draft;
  double _radius = 150;
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final c = _draft;
    if (c == null || _name.text.trim().isEmpty) return;
    final g = GeofenceModel(
      id: '',
      name: _name.text.trim(),
      lat: c.latitude,
      lng: c.longitude,
      radius: _radius,
    );
    try {
      await ref.read(geofenceServiceProvider).add(g);
      if (!mounted) return;
      setState(() {
        _draft = null;
        _name.clear();
        _radius = 150;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Geo-zona qo\'shildi')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Xatolik: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zones = ref.watch(geofencesProvider);
    final scheme = Theme.of(context).colorScheme;

    final circles = <CircleMarker>[];
    final markers = <Marker>[];
    zones.whenData((list) {
      for (final g in list) {
        final p = LatLng(g.lat, g.lng);
        circles.add(CircleMarker(
          point: p,
          radius: g.radius,
          useRadiusInMeter: true,
          color: scheme.primary.withValues(alpha: 0.15),
          borderColor: scheme.primary,
          borderStrokeWidth: 2,
        ));
        markers.add(Marker(
          point: p,
          width: 120,
          height: 40,
          child: _ZoneLabel(
            name: g.name,
            onDelete: () => _confirmDelete(g),
          ),
        ));
      }
    });

    if (_draft != null) {
      circles.add(CircleMarker(
        point: _draft!,
        radius: _radius,
        useRadiusInMeter: true,
        color: scheme.tertiary.withValues(alpha: 0.2),
        borderColor: scheme.tertiary,
        borderStrokeWidth: 2,
      ));
      markers.add(Marker(
        point: _draft!,
        width: 40,
        height: 40,
        child: Icon(Icons.add_location, color: scheme.tertiary, size: 36),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Geo-zonalar')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 13,
                onTap: (_, point) => setState(() => _draft = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'uz.bros.parent_app',
                ),
                CircleLayer(circles: circles),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
          _draft == null
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Yangi zona qo\'shish uchun xaritaga bosing.'),
                )
              : _editor(),
        ],
      ),
    );
  }

  Widget _editor() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Zona nomi (mas: Maktab)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.radio_button_checked, size: 18),
              const SizedBox(width: 8),
              Text('Radius: ${_radius.toStringAsFixed(0)} m'),
              Expanded(
                child: Slider(
                  value: _radius,
                  min: 50,
                  max: 1000,
                  divisions: 19,
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _draft = null),
                child: const Text('Bekor'),
              ),
              const Spacer(),
              FilledButton(onPressed: _save, child: const Text('Saqlash')),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(GeofenceModel g) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(g.name),
        content: const Text('Bu geo-zonani o\'chirasizmi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Yo\'q')),
          FilledButton(
            onPressed: () {
              ref.read(geofenceServiceProvider).delete(g.id);
              Navigator.pop(ctx);
            },
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;
  const _ZoneLabel({required this.name, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(name, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 4),
            const Icon(Icons.close, size: 14),
          ],
        ),
      ),
    );
  }
}
