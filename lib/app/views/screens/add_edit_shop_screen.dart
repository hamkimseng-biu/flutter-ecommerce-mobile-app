import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_storage_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';

/// Full-screen page for creating/editing a shop.
/// Supports image logo, banner, name, description, and official badge.
class AddEditShopScreen extends StatefulWidget {
  const AddEditShopScreen({super.key});
  @override
  State<AddEditShopScreen> createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends State<AddEditShopScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _storageService = FirebaseStorageService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _logoUrl = '';
  String _bannerUrl = '';
  bool _isOfficial = false;
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
        AppSnack.success(
          _isEdit ? 'Updated' : 'Created',
          _isEdit ? 'Shop updated.' : 'Shop created.',
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Failed to save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Shop' : 'Create Shop'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              onPick: () async {
                final url = await _storageService.pickAndUploadImage();
                if (url != null && mounted) setState(() => _bannerUrl = url);
              },
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
              onPick: () async {
                final url = await _storageService.pickAndUploadImage();
                if (url != null && mounted) setState(() => _logoUrl = url);
              },
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
                prefixIcon: const Icon(Icons.description_outlined, size: 20),
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
            const SizedBox(height: 40),
          ],
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
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: height,
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
