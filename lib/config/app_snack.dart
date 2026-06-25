import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Modern toast notification helper.
/// Compact card at the top with icon, title, message, and close button.
class AppSnack {
  static void success(String title, String message) {
    _show(title, message, const Color(0xFF43A047), Icons.check_circle_rounded);
  }

  static void error(String title, String message) {
    _show(title, message, const Color(0xFFE53935), Icons.error_outline_rounded);
  }

  static void info(String title, String message) {
    _show(title, message, const Color(0xFF1976D2), Icons.info_outline_rounded);
  }

  static void warning(String title, String message) {
    _show(title, message, const Color(0xFFF57C00), Icons.warning_amber_rounded);
  }

  static void _show(String title, String message, Color accent, IconData icon) {
    final isDark = Get.isDarkMode;

    Get.snackbar(
      title,
      message,
      titleText: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(left: 44),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF9E9EAA) : const Color(0xFF666666),
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      borderRadius: 16,
      backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
      borderWidth: 1,
      borderColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      boxShadows: [
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
          blurRadius: 20,
          offset: const Offset(0, 6),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      icon: null,
      duration: const Duration(seconds: 5),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
      shouldIconPulse: false,
      mainButton: TextButton(
        onPressed: () => Get.closeCurrentSnackbar(),
        child: Icon(
          Icons.close,
          size: 16,
          color: isDark ? Colors.white38 : Colors.black26,
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(24, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}
