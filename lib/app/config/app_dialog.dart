import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../config/app_theme.dart';

/// Centralized dialog styles for the entire app.
/// Use these methods instead of raw AlertDialog for consistent design.
class AppDialog {
  static const _radius = 20.0;
  static const _contentStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF666666),
  );

  /// Confirmation dialog (e.g. "Are you sure?" with Cancel/Confirm)
  static Future<bool?> confirm({
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) {
    return Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: confirmColor ?? AppTheme.primaryColor,
                size: 22,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: _contentStyle),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(cancelLabel, style: const TextStyle(fontSize: 14)),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmColor ?? AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Delete confirmation with red accent
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
      icon: Icons.delete_outline,
    );
  }

  /// Success/info dialog with a single "OK" button
  static Future<void> info({
    required String title,
    required String message,
    String buttonLabel = 'OK',
    Widget? child,
  }) {
    return Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: child ?? Text(message, style: _contentStyle),
        actions: [
          FilledButton(
            onPressed: () => Get.back(),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Input dialog — returns the entered text or null if cancelled.
  /// [onSubmit] is called with the text when the user presses the action button.
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          FilledButton(
            onPressed: () => Get.back(result: ctrl.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
