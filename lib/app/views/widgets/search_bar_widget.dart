import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final TextEditingController? controller;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF1F3F5);
    final borderColor = isDark ? Colors.white24 : const Color(0xFFD0D0D6);

    final textField = TextField(
      enabled: enabled,
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      cursorColor: AppTheme.primaryColor,
      style: TextStyle(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: 'Search in Tiny Chicken',
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? const Color(0xFF9E9EAA) : const Color(0xFFAAAAAA),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.primaryColor,
          size: 22,
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: borderColor, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
      ),
    );

    final container = Container(
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: textField,
    );

    // When disabled, wrap in GestureDetector so onTap still fires
    if (!enabled && onTap != null) {
      return GestureDetector(onTap: onTap, child: container);
    }

    return container;
  }
}
