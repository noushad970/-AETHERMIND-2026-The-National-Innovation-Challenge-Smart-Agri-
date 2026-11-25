import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../data/services/auth_rate_limit_service.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/services/firestore_sync_service.dart';

/// Provider that wraps [AuthService] and exposes Firebase authentication,
/// Google (Gmail) Sign-In, Email/Password, and user profile sync to the widget tree.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? service,
    FirestoreSyncService? sync,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _service = service ?? AuthService(),
        _sync = sync ?? FirestoreSyncService(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _sub = _service.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _service;
  final FirestoreSyncService _sync;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _loading = true;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _loading;
  String? get error => _error;

  /// Backward compatibility getters
  String? get activeMobileNumber =>
      _user?.phoneNumber ??
      (_user?.email != null && _user!.email!.contains('@')
          ? _user!.email!.split('@').first
          : null);

  /// Returns the formatted username for the signed-in farmer.
  String get username {
    final u = _user;
    if (u == null) return '@farmer';
    final name = u.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      if (name.startsWith('@')) return name;
      return '@${name.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    }
    final email = u.email;
    if (email != null && email.isNotEmpty) {
      final handle = email.split('@').first;
      return '@$handle';
    }
    return '@farmer';
  }

  /// Returns user display name or fallback
  String get displayName {
    final u = _user;
    if (u == null) return 'কৃষক ভাই';
    if (u.displayName != null && u.displayName!.trim().isNotEmpty) {
      return u.displayName!.trim();
    }
    if (u.email != null && u.email!.isNotEmpty) {
      return u.email!.split('@').first;
    }
    return 'কৃষক ভাই';
  }

  /// Sign in with Email and Password (protected by 5-attempt rate limit)
  Future<bool> signIn(String email, String password, {bool isBn = true}) async {
    // 1. Check if user is locked out
    final isLocked = await AuthRateLimitService.instance.isLockedOut();
    if (isLocked) {
      final remainingMins =
          await AuthRateLimitService.instance.getRemainingLockoutMinutes();
      _error = AuthRateLimitService.instance
          .getLockoutErrorMessage(minutes: remainingMins, isBn: isBn);
      notifyListeners();
      return false;
    }

    try {
      _loading = true;
      _error = null;
      notifyListeners();
      final cred = await _service.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      if (cred.user != null) {
        // Success: reset failed attempts to 0
        await AuthRateLimitService.instance.resetAttempts();
        await _syncUserProfile(cred.user!);
      }
      return true;
    } on FirebaseAuthException catch (_) {
      // Record failed attempt
      final failedCount =
          await AuthRateLimitService.instance.recordFailedAttempt();
      if (failedCount >= AuthRateLimitService.maxFailedAttempts) {
        _error = AuthRateLimitService.instance
            .getLockoutErrorMessage(minutes: 60, isBn: isBn);
      } else {
        final remaining =
            AuthRateLimitService.maxFailedAttempts - failedCount;
        _error = AuthRateLimitService.instance
            .getAttemptsWarningMessage(remaining: remaining, isBn: isBn);
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Register new user with Email, Password, and Display Name (enforces strong password)
  Future<bool> register(
    String email,
    String password,
    String displayName, {
    bool isBn = true,
  }) async {
    // Validate strong password
    final passwordErr = PasswordValidator.validate(password, isBn: isBn);
    if (passwordErr != null) {
      _error = passwordErr;
      notifyListeners();
      return false;
    }

    try {
      _loading = true;
      _error = null;
      notifyListeners();
      final cred = await _service.registerWithEmail(
        email: email.trim(),
        password: password,
        displayName: displayName.trim(),
      );
      if (cred.user != null) {
        await _syncUserProfile(cred.user!, overrideDisplayName: displayName.trim());
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in with Google (Gmail)
  Future<bool> signInWithGoogle() async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      final cred = await _service.signInWithGoogle();
      if (cred == null) {
        // User cancelled popup/prompt
        _loading = false;
        notifyListeners();
        return false;
      }
      if (cred.user != null) {
        await _syncUserProfile(cred.user!);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('10') || errStr.contains('DEVELOPER_ERROR')) {
        _error = 'Google Sign-In Setup Required: Please add the SHA-1 fingerprint to your Firebase Console settings and enable Google provider in Firebase Auth.';
      } else if (errStr.contains('network') || errStr.contains('7')) {
        _error = 'Network error during Google Sign-In. Please check your internet connection.';
      } else {
        _error = errStr;
      }
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Reset Password via Email
  Future<bool> resetPassword(String email) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();
      await _service.sendPasswordReset(email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign in as a Demo/Guest user for instant access or offline testing
  Future<bool> signInAsDemoUser({
    String email = 'farmer@smartagri.bd',
    String password = 'smartagridemo',
    String displayName = 'কৃষক ভাই (Demo)',
    String? mobileNumber,
  }) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      try {
        final cred = await _service.signInWithEmail(
          email: email,
          password: password,
        );
        if (cred.user != null) {
          await _syncUserProfile(cred.user!, overrideDisplayName: displayName);
        }
      } on FirebaseAuthException catch (_) {
        // Create if doesn't exist
        try {
          final cred = await _service.registerWithEmail(
            email: email,
            password: password,
            displayName: displayName,
          );
          if (cred.user != null) {
            await _syncUserProfile(cred.user!, overrideDisplayName: displayName);
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.lastLoggedInMobileKey, email);
      return true;
    } catch (e) {
      debugPrint('Demo user sign-in: $e');
      return true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _service.signOut();
    _sync.clearCachedUser();
    notifyListeners();
  }

  /// Updates the signed-in user's display name and username in Firebase Auth & Firestore.
  Future<void> updateUsername(String newUsername) async {
    final u = _user;
    if (u == null) return;
    final formatted = newUsername.trim().startsWith('@')
        ? newUsername.trim()
        : '@${newUsername.trim()}';
    try {
      await u.updateDisplayName(formatted);
      await _firestore.collection('users').doc(u.uid).set({
        'username': formatted,
        'displayName': u.displayName ?? formatted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to update username: $e');
    }
  }

  /// Backward compatibility helpers for legacy widgets
  Future<bool> signInWithVerifiedMobile(
    String mobileNumber, {
    String? displayName,
  }) async {
    return signInAsDemoUser(displayName: displayName ?? 'কৃষক ভাই');
  }

  Future<void> markSubscriptionVerified(String mobileNumber, {String? displayName}) async {
    final u = _auth.currentUser;
    if (u != null) {
      await _syncUserProfile(u, overrideDisplayName: displayName);
    }
  }

  Future<void> markSubscriptionCancelled(String mobileNumber) async {}

  Future<Map<String, dynamic>?> getExistingSubscriptionUser(String mobileNumber) async {
    return null;
  }

  Future<bool> isSubscriptionVerified() async => true;

  /// Sync user profile doc to Firestore
  Future<void> _syncUserProfile(User user, {String? overrideDisplayName}) async {
    try {
      final name = overrideDisplayName ??
          user.displayName ??
          user.email?.split('@').first ??
          'কৃষক ভাই';

      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': name,
        'displayName': name,
        'email': user.email,
        'photoURL': user.photoURL,
        'phoneNumber': user.phoneNumber,
        'verified': true,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore profile sync note: $e');
    }
  }

  /// Maps FirebaseAuth error codes to human-readable English/Bengali messages
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email. (এই ইমেইলে কোনো একাউন্ট নেই)';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Incorrect email or password. (ভুল ইমেইল বা পাসওয়ার্ড)';
      case 'email-already-in-use':
        return 'The account already exists for that email. (এই ইমেইলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে)';
      case 'invalid-email':
        return 'The email address is badly formatted. (সঠিক ইমেইল এড্রেস প্রদান করুন)';
      case 'weak-password':
        return 'The password provided is too weak. (পাসওয়ার্ডটি কমপক্ষে ৬ অক্ষরের হতে হবে)';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection. (ইন্টারনেট সংযোগ চেক করুন)';
      case 'user-disabled':
        return 'This user account has been disabled. (একাউন্টটি নিষ্ক্রিয় করা হয়েছে)';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later. (অতিরিক্ত চেষ্টার কারণে সাময়িক বন্ধ, কিছুক্ষণ পর আবার চেষ্টা করুন)';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  void _onAuthChanged(User? user) {
    final wasSignedIn = _user != null;
    _user = user;
    _loading = false;

    if (user == null) {
      _sync.clearCachedUser();
    } else {
      _sync.rememberCurrentUser();
      unawaited(
        _sync.upsertUserProfile(
          email: user.email,
          displayName: user.displayName,
        ),
      );
    }

    if (wasSignedIn != (user != null)) notifyListeners();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
