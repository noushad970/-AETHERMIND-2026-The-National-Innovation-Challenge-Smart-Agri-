import 'package:ai_agri_assistant/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _FakeCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuth implements FirebaseAuth {
  _FakeAuth({this.popupError});

  /// The error code the popup fails with, or null when it succeeds.
  final String? popupError;
  final UserCredential credential = _FakeCredential();
  int popups = 0;
  int signOuts = 0;

  @override
  Future<UserCredential> signInWithPopup(provider) async {
    popups++;
    expect(provider, isA<GoogleAuthProvider>());
    final code = popupError;
    // ignore: invalid_use_of_protected_member
    if (code != null) throw FirebaseAuthException(code: code);
    return credential;
  }

  @override
  Future<void> signOut() async => signOuts++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogle implements GoogleSignIn {
  int signIns = 0;
  int signOuts = 0;

  /// Behaves like a user who closes the account chooser.
  @override
  Future<GoogleSignInAccount?> signIn() async {
    signIns++;
    return null;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOuts++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  AuthService service(_FakeAuth auth, _FakeGoogle google, {bool isWeb = true}) =>
      AuthService(auth: auth, googleSignIn: google, isWeb: isWeb);

  test('the website signs in with the Firebase popup', () async {
    final auth = _FakeAuth();
    final google = _FakeGoogle();

    final result = await service(auth, google).signInWithGoogle();

    expect(result, same(auth.credential));
    expect(auth.popups, 1);
    expect(google.signIns, 0);
  });

  test('closing the popup is not an error', () async {
    for (final code in ['popup-closed-by-user', 'cancelled-popup-request']) {
      final auth = _FakeAuth(popupError: code);

      expect(await service(auth, _FakeGoogle()).signInWithGoogle(), isNull);
    }
  });

  test('other popup errors reach the caller', () async {
    final auth = _FakeAuth(popupError: 'unauthorized-domain');

    await expectLater(
      service(auth, _FakeGoogle()).signInWithGoogle(),
      throwsA(isA<FirebaseAuthException>()),
    );
  });

  test('mobile apps keep using the Google sign-in plugin', () async {
    final auth = _FakeAuth();
    final google = _FakeGoogle();

    await service(auth, google, isWeb: false).signInWithGoogle();

    expect(google.signIns, 1);
    expect(auth.popups, 0);
  });

  test('signing out on the website leaves the plugin alone', () async {
    final auth = _FakeAuth();
    final google = _FakeGoogle();

    await service(auth, google).signOut();

    expect(auth.signOuts, 1);
    expect(google.signOuts, 0);
  });

  test('signing out in the mobile apps also leaves Google', () async {
    final auth = _FakeAuth();
    final google = _FakeGoogle();

    await service(auth, google, isWeb: false).signOut();

    expect(auth.signOuts, 1);
    expect(google.signOuts, 1);
  });
}
