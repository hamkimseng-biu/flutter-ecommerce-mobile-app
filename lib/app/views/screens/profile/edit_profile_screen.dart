import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/firebase_storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    _nameCtrl = TextEditingController(text: auth.userName.value);
    _phoneCtrl = TextEditingController(text: '');
    _loadPhone();
    _phoneCtrl.addListener(() {
      final f = _formatPhone(_phoneCtrl.text);
      final sel = _phoneCtrl.selection.baseOffset;
      final old = _phoneCtrl.text.length;
      _phoneCtrl.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: sel + (f.length - old)),
      );
    });
  }

  Future<void> _loadPhone() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      final phone = doc.data()?['phone'] as String? ?? '';
      if (phone.isNotEmpty && mounted) {
        _phoneCtrl.text = _formatPhone(phone);
      }
    } catch (_) {}
  }

  String _formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.startsWith('855')) {
      if (d.length <= 3) return '+$d';
      if (d.length <= 5) return '+${d.substring(0, 3)} ${d.substring(3)}';
      if (d.length <= 8)
        return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5)}';
      return '+${d.substring(0, 3)} ${d.substring(3, 5)} ${d.substring(5, 8)} ${d.substring(8, d.length > 11 ? 11 : d.length)}';
    }
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)} ${d.substring(3)}';
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, d.length > 10 ? 10 : d.length)}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _storageService.pickAndUploadImage();
      if (url == null) {
        // User cancelled
        setState(() => _uploadingPhoto = false);
        return;
      }
      final auth = Get.find<AuthController>();
      await auth.currentUser?.updatePhotoURL(url);
      await _firestore.collection('users').doc(auth.currentUser!.uid).update({
        'photoURL': url,
      });
      auth.userPhotoURL.value = url;
      if (mounted) {
        AppSnack.success(
          'Photo Updated',
          'Your profile photo has been updated.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnack.error('Upload Failed', 'Could not upload photo. Try again.');
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = Get.find<AuthController>();
    try {
      await auth.currentUser?.updateDisplayName(_nameCtrl.text.trim());
      auth.userName.value = _nameCtrl.text.trim();
      // Save phone to Firestore
      final rawPhone = _phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      await _firestore.collection('users').doc(auth.currentUser!.uid).set({
        'phone': rawPhone,
        'name': _nameCtrl.text.trim(),
      }, SetOptions(merge: true));
      if (mounted) {
        Get.back(result: true);
        AppSnack.success('Profile Updated', 'Your profile has been saved.');
      }
    } catch (e) {
      if (mounted) {
        AppSnack.error('Error', 'Could not update profile. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
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
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Obx(
                        () => auth.userPhotoURL.value.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.network(
                                  auth.userPhotoURL.value,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.asset(
                                      'assets/images/icon.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  'assets/images/icon.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: _uploadingPhoto
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkInputFill
                    : AppTheme.lightInputFill,
              ),
            ),
            const SizedBox(height: 16),

            // Email (read-only)
            Obx(
              () => TextField(
                controller: TextEditingController(text: auth.userEmail.value),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  suffixIcon: const Icon(
                    Icons.lock_outlined,
                    size: 18,
                    color: Color(0xFF9E9EAA),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppTheme.darkInputFill
                      : AppTheme.lightInputFill,
                  helperText: 'Email cannot be changed',
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                hintText: '+855 12 345 678',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkInputFill
                    : AppTheme.lightInputFill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
