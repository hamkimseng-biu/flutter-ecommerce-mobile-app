import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class SearchBarWidget extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final Function(String)? onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        enabled: enabled,
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        decoration: const InputDecoration(
          hintText: 'Search products...',
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
