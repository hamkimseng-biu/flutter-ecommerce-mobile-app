import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_auth_service.dart';

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
      Get.offAllNamed('/main');
      return null; // success
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
      Get.offAllNamed('/main');
      return null; // success
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
    await _authService.signOut();
  }
}
