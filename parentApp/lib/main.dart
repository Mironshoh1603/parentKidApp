import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

// `flutterfire configure` bajarilgach:
//   import 'firebase_options.dart';
//   ... Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// Hozircha options'siz — Android google-services.json orqali ulanadi.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: ParentApp()));
}
