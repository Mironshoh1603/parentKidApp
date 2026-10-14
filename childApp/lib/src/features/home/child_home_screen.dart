import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers.dart';
import '../../services/location_reporter.dart';
import '../../services/sos_service.dart';
import '../checkin/checkin_screen.dart';

/// Bola bosh ekrani — OSHKORA holat. Bola nima kuzatilayotganini biladi.
class ChildHomeScreen extends ConsumerStatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  ConsumerState<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends ConsumerState<ChildHomeScreen>
    with WidgetsBindingObserver {
  LocationPermission? _perm;
  bool _serviceStarted = false;
  bool _usageGranted = false;
  bool _overlayGranted = false;
  bool _handlingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final perm = await Geolocator.checkPermission();
    final usage = await ref.read(usageServiceProvider).hasPermission();
    final overlay = await FlutterOverlayWindow.isPermissionGranted();
    if (!mounted) return;
    setState(() {
      _perm = perm;
      _usageGranted = usage;
      _overlayGranted = overlay;
    });
    if (_granted(perm)) _startService();
  }

  bool _granted(LocationPermission p) =>
      p == LocationPermission.always || p == LocationPermission.whileInUse;

  Future<void> _requestLocation() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() => _perm = perm);
    if (_granted(perm)) {
      _startService();
    } else if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  }

  Future<void> _requestUsage() async {
    await ref.read(usageServiceProvider).openUsageAccessSettings();
    // Qaytgach didChangeAppLifecycleState qayta tekshiradi.
  }

  Future<void> _requestOverlay() async {
    await FlutterOverlayWindow.requestPermission();
  }

  Future<void> _startService() async {
    if (_serviceStarted) return;
    await LocationReporter.startReporting();
    if (mounted) setState(() => _serviceStarted = true);
  }

  Future<void> _sendSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SOS yuborilsinmi?'),
        content: const Text(
            'Ota-onangizga joylashuvingiz bilan shoshilinch signal boradi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SOS yuborish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await SosService(FirebaseFirestore.instance).sendSos();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'SOS yuborildi ✓' : 'SOS yuborilmadi')),
    );
  }

  Future<void> _openCheckin({String? commandId}) async {
    _handlingPhoto = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckinScreen(commandId: commandId),
      ),
    );
    _handlingPhoto = false;
  }

  @override
  Widget build(BuildContext context) {
    final perm = _perm;
    final ok = perm != null && _granted(perm);

    // Ota-ona rasm so'rasa — avtomatik check-in ekranini ochamiz.
    // (watch: ekran ochilganda mavjud so'rovni ham, keyingilarini ham tutadi.)
    final pendingPhotoId = ref.watch(pendingPhotoRequestProvider).value;
    if (pendingPhotoId != null && !_handlingPhoto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_handlingPhoto) {
          _openCheckin(commandId: pendingPhotoId);
        }
      });
    }

    final needPerms = <Widget>[];
    if (!ok) {
      needPerms.add(_PermTile(
        icon: Icons.location_on,
        label: 'Joylashuvga ruxsat',
        onTap: _requestLocation,
      ));
    }
    if (!_usageGranted) {
      needPerms.add(_PermTile(
        icon: Icons.timelapse,
        label: 'Ekran vaqti ruxsati',
        onTap: _requestUsage,
      ));
    }
    if (!_overlayGranted) {
      needPerms.add(_PermTile(
        icon: Icons.layers,
        label: 'Qulflash uchun ruxsat (ustidan ko\'rsatish)',
        onTap: _requestOverlay,
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Himoya yoqilgan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Icon(
              ok ? Icons.verified_user : Icons.gpp_maybe,
              size: 88,
              color: ok
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              ok ? 'Qurilma ulangan' : 'Ruxsat kerak',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            // Oshkoralik bildirgisi — bola nima bo'layotganini biladi.
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bu ilova maxfiy emas — u doimo ishlab turadi.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ota-onangiz quyidagilarni ko\'ra oladi:\n'
                      '• joylashuvingiz va qurilma holati;\n'
                      '• ilovalardan foydalanish vaqti;\n'
                      '• kerak bo\'lsa telefonni vaqtincha qulflashi;\n'
                      '• sizdan rasm so\'rashi (siz ko\'rib turib yuborasiz).',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (needPerms.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Kerakli ruxsatlar',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              ...needPerms,
              const SizedBox(height: 12),
            ],
            if (ok) ...[
              SizedBox(
                height: 96,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _sendSos,
                  icon: const Icon(Icons.sos, size: 36),
                  label: const Text('SOS',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openCheckin(),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Ota-onamga rasm yuborish'),
              ),
              const SizedBox(height: 16),
              Text(
                _serviceStarted
                    ? 'Joylashuv yuborilmoqda ✓'
                    : 'Servis ishga tushmoqda...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Eng yaxshi natija uchun joylashuvni "Doim ruxsat etilsin" '
              'qilib belgilang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PermTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
