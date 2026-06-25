import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_auth_service.dart';
import '../../config/app_snack.dart';

class AuthController extends GetxController {
  final FirebaseAuthService _authService = FirebaseAuthService();

  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhotoURL = ''.obs;
  final ScrollController scrollController = ScrollController();

  User? get currentUser => _authService.currentUser;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        isLoggedIn.value = true;
        userEmail.value = user.email ?? '';
        userName.value = user.displayName ?? 'User';
        userPhotoURL.value = user.photoURL ?? '';
      } else {
        isLoggedIn.value = false;
        userName.value = '';
        userEmail.value = '';
        userPhotoURL.value = '';
      }
    });
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  // Sign up with email and password
  Future<String?> signUp(String name, String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signUpWithEmail(email, password, name);
      Get.offAllNamed('/main');
      return null; // success
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      await _authService.signInWithEmail(email, password);
      // Brief loading before transition
      if (Get.isDialogOpen ?? false) Get.back();
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (Get.isDialogOpen ?? false) Get.back();
      Get.offAllNamed('/main');
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      isLoading.value = true;
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        isLoading.value = false;
        return null; // User cancelled, not an error
      }
      if (Get.isDialogOpen ?? false) Get.back();
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (Get.isDialogOpen ?? false) Get.back();
      Get.offAllNamed('/main');
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Phone auth state
  PhoneAuthResult? _phoneConfirmation;

  /// Sends OTP to [phoneNumber] (E.164 format: +85512345678).
  /// Returns null on success, or an error message.
  Future<String?> sendPhoneOTP(String phoneNumber) async {
    try {
      isLoading.value = true;
      _phoneConfirmation = await _authService.verifyPhoneNumber(phoneNumber);
      // For test numbers, auto-verification happens — we let the OTP screen
      // handle it rather than auto-navigating away.
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies the OTP [smsCode] and completes phone sign-in.
  /// Returns null on success, or an error message.
  Future<String?> verifyPhoneOTP(String smsCode) async {
    // If auto-verified (test numbers), user is already signed in
    if (isLoggedIn.value) {
      _phoneConfirmation = null;
      Get.offAllNamed('/main');
      return null;
    }
    if (_phoneConfirmation == null) {
      return 'No verification in progress. Please try again.';
    }
    try {
      isLoading.value = true;
      await _phoneConfirmation!.signIn(smsCode);
      _phoneConfirmation = null;
      Get.offAllNamed('/main');
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Send password reset email
  Future<String?> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _authService.sendPasswordResetEmail(email);
      return null; // success
    } catch (e) {
      return e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> logout() async {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
      barrierDismissible: false,
    );
    await Future.delayed(const Duration(milliseconds: 300));
    await _authService.signOut();
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Returns true if user is signed in. If not, shows a prompt to sign in.
  /// Use this to guard actions that require authentication.
  bool requireAuth({
    String message = 'Please sign in to access this feature.',
  }) {
    if (isLoggedIn.value) return true;
    AppSnack.info('Sign In Required', message);
    Get.toNamed('/login');
    return false;
  }
}
