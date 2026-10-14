import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

// Firebase keyin ulanadi (Bosqich 0 oxirida):
//   1) `flutterfire configure` -> lib/firebase_options.dart hosil bo'ladi
//   2) bu yerda:
//        import 'firebase_options.dart';
//        WidgetsFlutterBinding.ensureInitialized();
//        await Firebase.initializeApp(
//          options: DefaultFirebaseOptions.currentPlatform);
//   3) main() ni `Future<void>` ga aylantiramiz.

void main() {
  runApp(const ProviderScope(child: ParentApp()));
}
