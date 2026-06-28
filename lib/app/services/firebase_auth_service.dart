import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stores a credential that failed with account-exists-with-different-credential
  /// so it can be linked after the user signs in with their existing provider.
  AuthCredential? _pendingLinkCredential;

  /// Returns true if there's a pending credential waiting to be linked.
  bool get hasPendingLink => _pendingLinkCredential != null;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name,
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': null,
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Auto-link any pending credential (e.g. Facebook)
      await _tryLinkPending();
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    OAuthCredential? googleCredential;
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(googleCredential);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name':
            userCredential.user?.displayName ??
            googleUser.displayName ??
            'User',
        'email': userCredential.user?.email ?? googleUser.email,
        'photoURL': userCredential.user?.photoURL ?? googleUser.photoUrl,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _tryLinkPending();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingLinkCredential = googleCredential;
        throw await _existingProviderMessage(e.email);
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Google Sign-In failed. Make sure SHA-1 is registered in Firebase Console.\n\n${e.toString()}';
    }
  }

  // Sign in with Facebook
  Future<UserCredential?> signInWithFacebook() async {
    OAuthCredential? fbCredential;
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );
      if (result.status == LoginStatus.cancelled) return null;
      if (result.status == LoginStatus.failed) {
        throw result.message ?? 'Facebook login failed.';
      }

      fbCredential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      final userCredential = await _auth.signInWithCredential(fbCredential);

      final user = userCredential.user!;
      String email = user.email ?? '';
      String name = user.displayName ?? 'Facebook User';

      if (email.isEmpty) {
        try {
          final userData = await FacebookAuth.instance.getUserData(
            fields: 'email,name',
          );
          email = userData['email'] ?? '';
          if (name == 'Facebook User') {
            name = userData['name'] ?? 'Facebook User';
          }
        } catch (_) {}
      }

      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email.isNotEmpty ? email : null,
        'photoURL': user.photoURL,
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _tryLinkPending();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        _pendingLinkCredential = fbCredential;
        throw await _existingProviderMessage(e.email);
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Facebook Sign-In failed. ${e.toString()}';
    }
  }

  /// Returns a human-friendly message telling the user which provider
  /// they already used to sign up with [email].
  Future<String> _existingProviderMessage(String? email) async {
    if (email == null || email.isEmpty) {
      return 'An account with this email already exists. '
          'Please use the original sign-in method.';
    }
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      final parts = <String>[];
      if (methods.contains('google.com')) parts.add('Google');
      if (methods.contains('facebook.com')) parts.add('Facebook');
      if (methods.contains('password')) parts.add('email/password');
      if (methods.contains('phone')) parts.add('phone');

      if (parts.isNotEmpty) {
        return 'This email is already registered via ${parts.join(' and ')}.\n'
            'Please sign in with ${parts.length == 1 ? parts.first : 'one of those methods'}, '
            'and Facebook will be linked to your account.';
      }
    } catch (_) {}
    return 'An account with this email already exists.\n'
        'Please use your original sign-in method.';
  }

  /// Links the [_pendingLinkCredential] to the currently signed-in user.
  /// Call this after a successful sign-in with any existing provider.
  Future<void> _tryLinkPending() async {
    final pending = _pendingLinkCredential;
    if (pending == null) return;
    _pendingLinkCredential = null;

    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await user.linkWithCredential(pending);
      // Update Firestore with any missing profile data
      await _firestore.collection('users').doc(user.uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        // Already linked — nothing to do
      }
      // Other errors: credential may be expired or invalid; ignore silently
    } catch (_) {}
  }

  // ── Phone Auth ────────────────────────────────────

  /// Starts phone number verification. [phoneNumber] must be in E.164 format
  /// (e.g. +85512345678). Returns the [ConfirmationResult] which holds the
  /// verificationId and a callback to complete sign-in with the OTP.
  Future<PhoneAuthResult> verifyPhoneNumber(String phoneNumber) async {
    final completer = Completer<PhoneAuthResult>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification (e.g. Android SMS auto-retrieve) — instant sign-in
        final userCredential = await _auth.signInWithCredential(credential);
        // Create/update user doc
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': userCredential.user?.displayName ?? 'User',
          'phone': phoneNumber,
          'lastLoginAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (!completer.isCompleted) {
          completer.complete(
            PhoneAuthResult(
              verificationId: '',
              signIn: (_) async => userCredential,
            ),
          );
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(_handleAuthException(e));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneAuthResult(
              verificationId: verificationId,
              signIn: (String smsCode) async {
                final credential = PhoneAuthProvider.credential(
                  verificationId: verificationId,
                  smsCode: smsCode,
                );
                final userCredential = await _auth.signInWithCredential(
                  credential,
                );
                // Create user doc in Firestore
                await _firestore
                    .collection('users')
                    .doc(userCredential.user!.uid)
                    .set({
                      'name': userCredential.user?.displayName ?? 'User',
                      'phone': phoneNumber,
                      'lastLoginAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
                return userCredential;
              },
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // No-op — timeout is expected on some devices
      },
    );

    return completer.future;
  }

  // Sign out
  Future<void> signOut() async {
    _pendingLinkCredential = null;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // Stream user data from Firestore
  Stream<Map<String, dynamic>?> userDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  // Error handling
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. '
            'Please use your original sign-in method (Google, Facebook, or email).';
      case 'credential-already-in-use':
        return 'This account is already linked to another user.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Please choose a stronger password (at least 6 characters).';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}

/// Holds the verification ID and a callback to complete phone sign-in.
class PhoneAuthResult {
  final String verificationId;
  final Future<UserCredential> Function(String smsCode) signIn;

  PhoneAuthResult({required this.verificationId, required this.signIn});
}
