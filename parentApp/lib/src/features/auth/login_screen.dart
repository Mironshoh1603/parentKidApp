import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

/// Ota-ona uchun kirish / ro'yxatdan o'tish ekrani.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      if (_isRegister) {
        await auth.register(_email.text, _password.text);
      } else {
        await auth.signIn(_email.text, _password.text);
      }
      // Muvaffaqiyatli bo'lsa, authStateProvider avtomatik dashboard'ga o'tkazadi.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _message(e.code));
    } catch (e) {
      setState(() => _error = 'Xatolik: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Email noto\'g\'ri.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email yoki parol noto\'g\'ri.';
      case 'email-already-in-use':
        return 'Bu email allaqachon ro\'yxatdan o\'tgan.';
      case 'weak-password':
        return 'Parol juda oddiy (kamida 6 belgi).';
      default:
        return 'Xatolik: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.family_restroom,
                      size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    _isRegister ? 'Ro\'yxatdan o\'tish' : 'Kirish',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Email kiriting' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Parol'),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Kamida 6 belgi'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isRegister ? 'Ro\'yxatdan o\'tish' : 'Kirish'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _isRegister = !_isRegister),
                    child: Text(_isRegister
                        ? 'Akkauntingiz bormi? Kirish'
                        : 'Akkaunt yo\'qmi? Ro\'yxatdan o\'tish'),
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
