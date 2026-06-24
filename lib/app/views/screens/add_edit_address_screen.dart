import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/firebase_firestore_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? address; // null = add, non-null = edit
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _firestoreService = FirebaseFirestoreService();
  late final TextEditingController _recipientCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _zipCtrl;
  bool _isDefault = false;
  bool _saving = false;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _recipientCtrl = TextEditingController(text: a?['recipient'] ?? '');
    _phoneCtrl = TextEditingController(text: a?['phone'] ?? '');
    _labelCtrl = TextEditingController(text: a?['label'] ?? '');
    _streetCtrl = TextEditingController(text: a?['street'] ?? '');
    _cityCtrl = TextEditingController(text: a?['city'] ?? '');
    _provinceCtrl = TextEditingController(text: a?['province'] ?? '');
    _zipCtrl = TextEditingController(text: a?['zip'] ?? '');
    _isDefault = a?['isDefault'] == true;
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _labelCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_recipientCtrl.text.trim().isEmpty ||
        _streetCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Please fill recipient, street, and city.');
      return;
    }
    setState(() => _saving = true);
    final addr = {
      'firestoreId': widget.address?['firestoreId'] ?? '',
      'recipient': _recipientCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'label': _labelCtrl.text.trim().isEmpty
          ? 'Address'
          : _labelCtrl.text.trim(),
      'street': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'province': _provinceCtrl.text.trim(),
      'zip': _zipCtrl.text.trim(),
      'isDefault': _isDefault,
    };
    try {
      if (_isEdit && (addr['firestoreId'] as String).isNotEmpty) {
        await _firestoreService.saveAddress(
          addr,
          docId: addr['firestoreId'] as String,
        );
      } else {
        await _firestoreService.saveAddress(addr);
      }
      if (mounted) {
        AppSnack.success(
          'Saved',
          _isEdit ? 'Address updated.' : 'Address added.',
        );
        Get.back(result: addr);
      }
    } catch (_) {
      if (mounted) {
        AppSnack.error('Error', 'Could not save address. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Address' : 'New Address'),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Info',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9EAA),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _recipientCtrl,
                    'Recipient Name',
                    Icons.person_outlined,
                    fillColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _phoneCtrl,
                    'Phone Number',
                    Icons.phone_outlined,
                    fillColor,
                    TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9EAA),
              ),
            ),
            const SizedBox(height: 10),
            _field(
              _labelCtrl,
              'Label (Home, Office, etc.)',
              Icons.label_outlined,
              fillColor,
            ),
            const SizedBox(height: 12),
            _field(
              _streetCtrl,
              'Street Address',
              Icons.location_on_outlined,
              fillColor,
              TextInputType.streetAddress,
              2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    _cityCtrl,
                    'City',
                    Icons.location_city_outlined,
                    fillColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _provinceCtrl,
                    'Province/State',
                    Icons.map_outlined,
                    fillColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(
              _zipCtrl,
              'Postal Code',
              Icons.markunread_mailbox_outlined,
              fillColor,
              TextInputType.number,
            ),
            const SizedBox(height: 24),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: const Text(
                  'Set as default address',
                  style: TextStyle(fontSize: 15),
                ),
                subtitle: Text(
                  _isDefault
                      ? 'This will be your primary shipping address'
                      : '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9EAA),
                  ),
                ),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _saving ? 'Saving...' : 'Save Address',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color fill, [
    TextInputType? keyboardType,
    int maxLines = 1,
  ]) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
      ),
    );
  }
}
