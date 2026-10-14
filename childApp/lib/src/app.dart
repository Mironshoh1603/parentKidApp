import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'features/home/child_home_screen.dart';
import 'features/pairing/pair_screen.dart';
import 'providers.dart';

/// Bola ilovasining ildiz vidjeti.
class ChildApp extends StatelessWidget {
  const ChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Himoya',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _Gate(),
    );
  }
}

/// Juftlanganmi — shunga qarab PairScreen yoki ChildHomeScreen.
class _Gate extends ConsumerWidget {
  const _Gate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paired = ref.watch(pairedProvider);
    return paired.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Xatolik: $e'))),
      data: (isPaired) =>
          isPaired ? const ChildHomeScreen() : const PairScreen(),
    );
  }
}
