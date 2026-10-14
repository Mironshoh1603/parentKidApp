import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/child_model.dart';
import '../../providers.dart';
import '../alerts/alerts_screen.dart';
import '../geofence/geofences_screen.dart';
import '../map/child_map_screen.dart';

/// Ota-ona bosh ekrani — farzandlar ro'yxati.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Oila hujjatini (familyId = uid) birinchi kirishda yaratamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyServiceProvider).ensureFamily();
    });
  }

  Future<void> _addChild() async {
    final name = await _askName();
    if (name == null || name.trim().isEmpty) return;
    try {
      final code = await ref.read(familyServiceProvider).addChild(name.trim());
      if (mounted) showPairingCodeDialog(context, name.trim(), code);
    } catch (e) {
      _snack('Xatolik: $e');
    }
  }

  Future<String?> _askName() {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Farzand qo\'shish'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Ism'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Bekor')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text),
              child: const Text('Qo\'shish')),
        ],
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(childrenProvider);
    final unread = ref.watch(unreadAlertsProvider).value ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farzandlarim'),
        actions: [
          IconButton(
            tooltip: 'Geo-zonalar',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeofencesScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Ogohlantirishlar',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AlertsScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Chiqish',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addChild,
        icon: const Icon(Icons.add),
        label: const Text('Farzand'),
      ),
      body: children.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Xatolik: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Hali farzand qo\'shilmagan.\nPastdagi tugma orqali qo\'shing.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ChildTile(child: list[i]),
          );
        },
      ),
    );
  }
}

class _ChildTile extends ConsumerWidget {
  final ChildModel child;
  const _ChildTile({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = child.lastSeen != null &&
        DateTime.now().difference(child.lastSeen!).inMinutes < 2;
    return Card(
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              child: Text(
                  child.name.isNotEmpty ? child.name[0].toUpperCase() : '?'),
            ),
            if (child.paired)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: online ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(child.name),
        subtitle: Text(child.paired
            ? '${online ? 'Onlayn' : 'Oflayn'} • ${child.batteryLevel}%'
                '${child.isCharging ? ' ⚡' : ''} • ${_relativeTime(child.lastSeen)}'
            : 'Juftlanmagan — kod kutilmoqda'),
        trailing: child.paired
            ? Icon(
                child.isCharging
                    ? Icons.battery_charging_full
                    : Icons.battery_full,
                color: child.batteryLevel < 20 ? Colors.red : null)
            : null,
        onTap: child.paired
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChildMapScreen(child: child)),
                )
            : () async {
                final code = await ref
                    .read(familyServiceProvider)
                    .regenerateCode(child.id);
                if (context.mounted) {
                  showPairingCodeDialog(context, child.name, code);
                }
              },
      ),
    );
  }
}

/// Nisbiy vaqt ("5 daq oldin").
String _relativeTime(DateTime? dt) {
  if (dt == null) return '—';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'hozir';
  if (diff.inMinutes < 60) return '${diff.inMinutes} daq oldin';
  if (diff.inHours < 24) return '${diff.inHours} soat oldin';
  return '${diff.inDays} kun oldin';
}

/// Juftlash kodini ko'rsatuvchi dialog (bir nechta joydan chaqiriladi).
void showPairingCodeDialog(BuildContext context, String name, String code) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('$name — juftlash kodi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Bolaning telefonidagi ilovaga shu kodni kiriting:'),
          const SizedBox(height: 16),
          SelectableText(
            code,
            style: const TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8),
          ),
          const SizedBox(height: 8),
          const Text('Kod 15 daqiqa amal qiladi.',
              style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(ctx)
                .showSnackBar(const SnackBar(content: Text('Kod nusxalandi')));
          },
          child: const Text('Nusxalash'),
        ),
        FilledButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Yopish')),
      ],
    ),
  );
}
