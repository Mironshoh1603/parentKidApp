import 'package:firebase_auth/firebase_auth.dart';

/// Ota-ona autentifikatsiyasi (Email/Password).
class AuthService {
  final FirebaseAuth _auth;
  AuthService(this._auth);

  User? get current => _auth.currentUser;

  Stream<User?> authState() => _auth.authStateChanges();

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  Future<void> signOut() => _auth.signOut();
}
