import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Bola telefonida juftlash kodini kiritish ekrani.
class PairScreen extends ConsumerStatefulWidget {
  const PairScreen({super.key});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await ref.read(pairingServiceProvider).pairWithCode(_code.text);
    if (!mounted) return;
    if (result.ok) {
      // Juftlandi — pairedProvider qayta tekshiriladi va home'ga o'tadi.
      ref.invalidate(pairedProvider);
    } else {
      setState(() {
        _loading = false;
        _error = result.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.link,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('Qurilmani ulash',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Ota-onangiz ilovasida ko\'rsatilgan 6 xonali kodni kiriting.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 32, letterSpacing: 10, fontWeight: FontWeight.bold),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _pair,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Ulash'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
