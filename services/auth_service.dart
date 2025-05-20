import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcı akışı
  Stream<User?> get userStream => _auth.authStateChanges();

  // Google ile giriş
  Future<UserCredential> signInWithGoogle() async {
    final GoogleAuthProvider googleProvider = GoogleAuthProvider();
    return await _auth.signInWithPopup(googleProvider);
  }

  // Çıkış
  Future<void> signOut() async {
    await _auth.signOut();
  }
}