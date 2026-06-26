import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';

/// Centralized dialog styles for the entire app.
class AppDialog {
  static const _radius = 20.0;

  /// Slide-up confirmation sheet — theme-aware, modern design.
  static Future<bool?> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    final ctx = Get.context;
    if (ctx == null) return Future.value(null);
    final isDark = Theme.of(ctx).brightness == Brightness.dark;

    return showModalBottomSheet<bool>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (icon != null) ...[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (confirmColor ?? AppTheme.primaryColor).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: confirmColor ?? AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFF9E9EAA) : const Color(0xFF666666), height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                      child: Text(cancelLabel, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: confirmColor ?? AppTheme.primaryColor,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(confirmLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Delete confirmation with red accent.
  static Future<bool?> deleteConfirm({
    required String title,
    required String message,
    String itemName = '',
  }) {
    return confirm(
      title: title,
      message: message,
      confirmLabel: 'Delete',
      confirmColor: AppTheme.errorColor,
      icon: Icons.delete_outline_rounded,
    );
  }

  /// Info dialog — popup style.
  static Future<void> info({
    required String title,
    required String message,
    String buttonLabel = 'OK',
    Widget? child,
  }) {
    return Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: child ?? Text(message, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
        actions: [
          FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Input dialog.
  static Future<String?> input({
    required String title,
    required String label,
    required String hint,
    String actionLabel = 'Submit',
    String? initialValue,
    IconData? prefixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final ctrl = TextEditingController(text: initialValue ?? '');
    return Get.dialog<String>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel', style: TextStyle(fontSize: 14))),
          FilledButton(
            onPressed: () => Get.back(result: ctrl.text.trim()),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text(actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
