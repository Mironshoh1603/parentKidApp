import 'package:flutter/material.dart';

/// Qulflash qoplamasi (overlay) — ALOHIDA Flutter engine'da ishlaydi
/// (`overlayMain` kirish nuqtasi orqali). Shuning uchun bu yerda Firebase yoki
/// Riverpod ISHLATILMAYDI — faqat statik UI.
///
/// OSHKORA: ekranda aniq yozuv — bola nega qulflanganini biladi.
class LockOverlay extends StatelessWidget {
  const LockOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: const Color(0xFF0E1726),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock_clock, size: 96, color: Colors.white),
                  SizedBox(height: 24),
                  Text(
                    'Qurilma vaqtincha qulflangan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Ota-onangiz telefon vaqtini cheklab qo\'ydi.\n'
                    'Qulfni ochish uchun ular bilan bog\'laning.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Shoshilinch holatda SOS ishlaydi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
