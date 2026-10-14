import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../models/limit_model.dart';
import '../../models/usage_model.dart';
import '../../providers.dart';

/// Ekran vaqti + kunlik limit (Bosqich 4) — ota-ona tomoni.
class UsageScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;
  const UsageScreen(
      {super.key, required this.childId, required this.childName});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  bool? _enabled; // local tahrir (null = provider qiymati)
  int? _minutes;

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(todayUsageProvider(widget.childId));
    final limitAsync = ref.watch(dailyLimitProvider(widget.childId));

    return Scaffold(
      appBar: AppBar(title: Text('Ekran vaqti — ${widget.childName}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          limitAsync.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Limitni o\'qib bo\'lmadi: $e'),
              ),
            ),
            data: (limit) => _limitCard(limit),
          ),
          const SizedBox(height: 16),
          Text('Bugungi foydalanish',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          usage.when(
            loading: () =>
                const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Xatolik: $e'),
            data: (u) => _usageBody(u),
          ),
        ],
      ),
    );
  }

  Widget _limitCard(DailyLimit limit) {
    final enabled = _enabled ?? limit.enabled;
    final minutes = _minutes ?? limit.dailyLimitMinutes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Kunlik ekran vaqti limiti',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 8),
              Text('Limit: ${formatDuration(minutes * 60)}',
                  style: Theme.of(context).textTheme.titleLarge),
              Slider(
                value: minutes.toDouble(),
                min: 15,
                max: 480,
                divisions: (480 - 15) ~/ 15,
                label: formatDuration(minutes * 60),
                onChanged: (v) =>
                    setState(() => _minutes = (v ~/ 15) * 15),
              ),
              const Text(
                'Limitdan oshsa, qurilmada oshkora qulf ekrani ko\'rsatiladi. '
                'Siz istalgan vaqt ochishingiz mumkin.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () async {
                  await ref.read(limitServiceProvider).save(
                        widget.childId,
                        DailyLimit(
                            enabled: enabled, dailyLimitMinutes: minutes),
                      );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saqlandi ✓')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Saqlash'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageBody(UsageModel? u) {
    if (u == null || u.apps.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Hali ma\'lumot yo\'q.\nBola telefonida "Ekran vaqti ruxsati" '
            'berilganiga ishonch hosil qiling.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final maxDur = u.apps
        .map((e) => e.duration)
        .fold<int>(1, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Jami', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(formatDuration(u.totalScreenTime),
                    style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final a in u.apps) _appRow(a.label, a.duration, maxDur),
      ],
    );
  }

  Widget _appRow(String label, int duration, int maxDur) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              Text(formatDuration(duration),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: maxDur == 0 ? 0 : duration / maxDur,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
