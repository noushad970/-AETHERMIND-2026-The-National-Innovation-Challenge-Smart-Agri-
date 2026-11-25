import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Auth wrapper around [FirebaseAuth] and [GoogleSignIn].
/// Provides authentication methods for Email/Password and Google (Gmail).
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    bool isWeb = kIsWeb,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _isWeb = isWeb;

  final FirebaseAuth _auth;

  /// Used by the mobile apps only. On the web it needs a client ID in the page,
  /// so the website uses Firebase's own Google popup instead.
  final GoogleSignIn _googleSignIn;
  final bool _isWeb;

  /// Firebase error codes meaning the user dismissed the Google popup.
  static const Set<String> _popupDismissed = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'user-cancelled',
  };

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Registers a new user with Email and 
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (displayName != null && displayName.isNotEmpty) {
      await cred.user?.updateDisplayName(displayName.trim());
    }
    return cred;
  }

  /// Signs in an existing user with Email and Password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in with Google (Gmail). Returns null if the user cancels.
  Future<UserCredential?> signInWithGoogle() async {
    if (_isWeb) return _signInWithGooglePopup();

    // Trigger Google Sign-In interactive flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled sign-in
      return null;
    }

    // Obtain auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential for Firebase
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credentials
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential?> _signInWithGooglePopup() async {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});
    try {
      return await _auth.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (_popupDismissed.contains(e.code)) return null;
      rethrow;
    }
  }

  /// Sends a password reset email
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Signs out from Firebase and, in the mobile apps, from Google
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      if (!_isWeb) _googleSignIn.signOut(),
    ]);
  }
}