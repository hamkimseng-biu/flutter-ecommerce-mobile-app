import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';

class ThemeController extends GetxController {
  final RxBool isDarkMode = false.obs;

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
  }

  // No need to call Get.changeThemeMode — main.dart watches isDarkMode via Obx
  ThemeData get currentTheme =>
      isDarkMode.value ? AppTheme.darkTheme : AppTheme.lightTheme;
}
