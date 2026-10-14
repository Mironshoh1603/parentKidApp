import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_reporter.dart';
import '../../services/sos_service.dart';

/// Bola bosh ekrani — OSHKORA holat. Bola nima kuzatilayotganini biladi.
class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  LocationPermission? _perm;
  bool _serviceStarted = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final perm = await Geolocator.checkPermission();
    setState(() => _perm = perm);
    if (_granted(perm)) _startService();
  }

  bool _granted(LocationPermission p) =>
      p == LocationPermission.always || p == LocationPermission.whileInUse;

  Future<void> _request() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    setState(() => _perm = perm);
    if (_granted(perm)) {
      _startService();
    } else if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
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

  @override
  Widget build(BuildContext context) {
    final perm = _perm;
    final ok = perm != null && _granted(perm);
    return Scaffold(
      appBar: AppBar(title: const Text('Himoya yoqilgan')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Icon(
              ok ? Icons.verified_user : Icons.gpp_maybe,
              size: 96,
              color: ok
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              ok ? 'Qurilma ulangan' : 'Ruxsat kerak',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            // Oshkoralik bildirgisi — bola nima bo'layotganini biladi.
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ota-onangiz joylashuvingizni va qurilma holatini ko\'radi. '
                        'Bu ilova maxfiy emas — u doimo ishlab turadi.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (ok)
              SizedBox(
                height: 110,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _sendSos,
                  icon: const Icon(Icons.sos, size: 40),
                  label: const Text('SOS',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                ),
              ),
            const Spacer(),
            if (!ok)
              FilledButton.icon(
                onPressed: _request,
                icon: const Icon(Icons.location_on),
                label: const Text('Joylashuvga ruxsat berish'),
              )
            else
              Text(
                _serviceStarted
                    ? 'Joylashuv yuborilmoqda ✓'
                    : 'Servis ishga tushmoqda...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
