import 'package:flutter/material.dart';
import 'core/app_theme.dart';

/// Ota-ona ilovasining ildiz vidjeti.
class ParentApp extends StatelessWidget {
  const ParentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MANA — Ota-ona',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _SetupPendingScreen(),
    );
  }
}

/// Firebase ulanmaguncha ko'rsatiladigan vaqtinchalik ekran.
/// `flutterfire configure` bajarilgach, bu yerda auth oqimi o'rnini oladi.
class _SetupPendingScreen extends StatelessWidget {
  const _SetupPendingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.family_restroom,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('MANA — Ota-ona',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Firebase sozlanmoqda.\n`flutterfire configure` bajarilgach,\nbu ekran login bilan almashtiriladi.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
