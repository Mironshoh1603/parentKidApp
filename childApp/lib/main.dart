import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/overlay/lock_overlay.dart';
import 'src/services/location_reporter.dart';

// `flutterfire configure` bajarilgach:
//   import 'firebase_options.dart';
//   Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocationReporter.configure();
  runApp(const ProviderScope(child: ChildApp()));
}

/// Qulflash qoplamasi (overlay) uchun ALOHIDA kirish nuqtasi.
/// `flutter_overlay_window` uni shu nom bilan ("overlayMain") qidiradi.
@pragma('vm:entry-point')
void overlayMain() {
  runApp(const LockOverlay());
}
