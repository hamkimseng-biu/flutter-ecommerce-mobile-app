import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';

/// Full-screen page for creating/editing a shop.
/// Supports image logo, banner, name, description, and official badge.
class AddEditShopScreen extends StatefulWidget {
  const AddEditShopScreen({super.key});
  @override
  State<AddEditShopScreen> createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends State<AddEditShopScreen> {
  final _firestore = FirebaseFirestore.instance;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _logoUrl = '';
  String _bannerUrl = '';
  bool _isOfficial = false;
  bool _isPopular = false;
  bool _isEdit = false;
  String? _docId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    if (arg is Map<String, dynamic>) {
      _isEdit = true;
      _docId = arg['docId'] as String?;
      final data = arg['data'] as Map<String, dynamic>? ?? {};
      _nameCtrl = TextEditingController(text: data['name'] ?? '');
      _descCtrl = TextEditingController(text: data['description'] ?? '');
      _logoUrl = data['logoUrl'] as String? ?? '';
      _bannerUrl = data['bannerUrl'] as String? ?? '';
      _isOfficial = data['isOfficial'] ?? false;
      _isPopular = data['isPopular'] ?? false;
    } else {
      _nameCtrl = TextEditingController();
      _descCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Shop name is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'logoUrl': _logoUrl,
        'bannerUrl': _bannerUrl,
        'isOfficial': _isOfficial,
        'isPopular': _isPopular,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (_isEdit && _docId != null) {
        await _firestore.collection('shops').doc(_docId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('shops').add(data);
      }
      if (mounted) {
        setState(() => _saving = false);
        Get.back(result: _isEdit ? 'updated' : 'created');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Failed to save: $e');
      }
    }
  }

  void _addImageUrl(void Function(String) onSet) {
    final urlCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Add Image URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: InputDecoration(
                hintText: 'https://picsum.photos/400/400',
                labelText: 'Image URL',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste any direct image URL (picsum.photos works best).\nURLs like unsplash.com/images/... or imgur.com/...\nshould work too. Pinterest & Instagram are blocked.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (url.isNotEmpty && mounted) onSet(url);
              Get.back();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Shop' : 'Create Shop')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner image
                  _section('Banner Image', 'Displayed at top of shop page'),
                  const SizedBox(height: 8),
                  _imagePicker(
                    url: _bannerUrl,
                    height: 140,
                    label: 'Upload Banner',
                    onPick: () =>
                        _addImageUrl((url) => setState(() => _bannerUrl = url)),
                    onRemove: () => setState(() => _bannerUrl = ''),
                  ),
                  const SizedBox(height: 24),

                  // Logo image
                  _section('Shop Logo', 'Square image, appears on shop cards'),
                  const SizedBox(height: 8),
                  _imagePicker(
                    url: _logoUrl,
                    height: 100,
                    width: 100,
                    label: 'Logo',
                    borderRadius: 16,
                    onPick: () =>
                        _addImageUrl((url) => setState(() => _logoUrl = url)),
                    onRemove: () => setState(() => _logoUrl = ''),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  _section('Shop Details', ''),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Shop Name',
                      prefixIcon: const Icon(Icons.store_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: fill,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(
                        Icons.description_outlined,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: fill,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Official Shop',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Mark as an official/verified shop',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _isOfficial,
                    onChanged: (v) => setState(() => _isOfficial = v),
                    activeColor: AppTheme.primaryColor,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Popular Shop',
                      style: TextStyle(fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Show in Popular Shops on homepage',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _isPopular,
                    onChanged: (v) => setState(() => _isPopular = v),
                    activeColor: AppTheme.secondaryColor,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                _saving
                    ? 'Saving...'
                    : (_isEdit ? 'Update Shop' : 'Create Shop'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      if (subtitle.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    ],
  );

  Widget _imagePicker({
    required String url,
    double height = 140,
    double? width,
    String label = 'Upload',
    double borderRadius = 12,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: url.isNotEmpty
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(borderRadius - 2),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: height,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 28,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
