import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/alert_model.dart';
import '../../providers.dart';

/// Ogohlantirishlar ro'yxati.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ogohlantirishlar'),
        actions: [
          IconButton(
            tooltip: 'Hammasini o\'qilgan deb belgilash',
            icon: const Icon(Icons.done_all),
            onPressed: () => ref.read(alertServiceProvider).markAllRead(),
          ),
        ],
      ),
      body: alerts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Ogohlantirishlar yo\'q.'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) => _AlertTile(alert: list[i]),
          );
        },
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final AlertModel alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final time =
        DateFormat('dd.MM HH:mm').format(alert.timestamp.toLocal());
    return ListTile(
      leading: Icon(_icon(alert.type), color: _color(context, alert.type)),
      title: Text(_title(alert)),
      subtitle: Text(time),
      trailing: alert.read
          ? null
          : const Icon(Icons.circle, size: 10, color: Colors.red),
      onTap: () => ref.read(alertServiceProvider).markRead(alert.id),
    );
  }

  String _title(AlertModel a) {
    final name = a.data['geofenceName'] ?? a.data['name'] ?? '';
    switch (a.type) {
      case AlertType.sos:
        return 'SOS! Yordam so\'raldi';
      case AlertType.geofenceExit:
        return 'Zonadan chiqdi: $name';
      case AlertType.geofenceEnter:
        return 'Zonaga kirdi: $name';
      case AlertType.lowBattery:
        return 'Batareya kam (${a.data['level'] ?? '?'}%)';
      case AlertType.offline:
        return 'Qurilma oflayn';
      case AlertType.unknown:
        return 'Ogohlantirish';
    }
  }

  IconData _icon(AlertType t) {
    switch (t) {
      case AlertType.sos:
        return Icons.sos;
      case AlertType.geofenceExit:
        return Icons.logout;
      case AlertType.geofenceEnter:
        return Icons.login;
      case AlertType.lowBattery:
        return Icons.battery_alert;
      case AlertType.offline:
        return Icons.wifi_off;
      case AlertType.unknown:
        return Icons.notifications;
    }
  }

  Color _color(BuildContext context, AlertType t) {
    final scheme = Theme.of(context).colorScheme;
    switch (t) {
      case AlertType.sos:
      case AlertType.geofenceExit:
      case AlertType.lowBattery:
        return scheme.error;
      default:
        return scheme.primary;
    }
  }
}
