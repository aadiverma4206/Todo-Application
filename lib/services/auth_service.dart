import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw "Registration failed";
    }
  }

  Future<UserCredential> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      notifyListeners();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw "Login failed";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(credential);

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (_) {
      throw "Google sign-in failed";
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email already in use";
      case 'invalid-email':
        return "Invalid email address";
      case 'weak-password':
        return "Password is too weak";
      case 'user-not-found':
        return "User not found";
      case 'wrong-password':
        return "Wrong password";
      case 'network-request-failed':
        return "Check your internet connection";
      case 'too-many-requests':
        return "Too many attempts. Try later";
      default:
        return e.message ?? "Authentication error";
    }
  }
}