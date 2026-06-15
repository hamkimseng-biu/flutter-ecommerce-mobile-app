import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final RxBool isLoggedIn = false.obs;
  final RxString userName = 'Chicken Lover'.obs;
  final RxString userEmail = 'user@tinychicken.com'.obs;
  final ScrollController scrollController = ScrollController();

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

  void login(String email, String password) {
    // Mock login
    isLoggedIn.value = true;
    userEmail.value = email;
  }

  void logout() {
    isLoggedIn.value = false;
  }
}
