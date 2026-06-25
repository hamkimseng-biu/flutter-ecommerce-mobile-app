import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _firestoreService = FirebaseFirestoreService();
  late final TextEditingController _recipientCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _zipCtrl;

  String _selectedLabel = 'Home';
  bool _isDefault = false;
  bool _saving = false;
  bool _isEdit = false;
  String? _existingId;

  static const _labels = ['Home', 'Office', 'Other'];

  @override
  void initState() {
    super.initState();
    // Read from Get.arguments — routes pass data via GetX, not constructor
    final a = Get.arguments;
    Map<String, dynamic>? addr;
    if (a is Map<String, dynamic>) {
      addr = a;
      _isEdit = true;
      _existingId = addr['firestoreId'] as String?;
    }

    _recipientCtrl = TextEditingController(text: addr?['recipient'] ?? '');
    _phoneCtrl = TextEditingController(
      text: _formatPhone(addr?['phone'] ?? ''),
    );
    _streetCtrl = TextEditingController(text: addr?['street'] ?? '');
    _cityCtrl = TextEditingController(text: addr?['city'] ?? '');
    _provinceCtrl = TextEditingController(text: addr?['province'] ?? '');
    _zipCtrl = TextEditingController(text: addr?['zip'] ?? '');

    final label = addr?['label'] as String? ?? '';
    if (_labels.contains(label)) {
      _selectedLabel = label;
    }
    _isDefault = addr?['isDefault'] == true;

    // Live phone formatting listener
    _phoneCtrl.addListener(() {
      final raw = _phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final formatted = _formatPhone(raw);
      if (_phoneCtrl.text != formatted) {
        final sel = _phoneCtrl.selection.baseOffset;
        final diff = formatted.length - _phoneCtrl.text.length;
        _phoneCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: (sel + diff).clamp(0, formatted.length),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  String _formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)} ${d.substring(3)}';
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, d.length > 10 ? 10 : d.length)}';
  }

  Future<void> _save() async {
    if (_recipientCtrl.text.trim().isEmpty ||
        _streetCtrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Please fill recipient, street, and city.');
      return;
    }
    setState(() => _saving = true);
    final rawPhone = _phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
    final addr = {
      'firestoreId': _existingId ?? '',
      'recipient': _recipientCtrl.text.trim(),
      'phone': rawPhone,
      'label': _selectedLabel,
      'street': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'province': _provinceCtrl.text.trim(),
      'zip': _zipCtrl.text.trim(),
      'isDefault': _isDefault,
    };
    try {
      if (_isEdit && _existingId != null && _existingId!.isNotEmpty) {
        await _firestoreService.saveAddress(addr, docId: _existingId!);
      } else {
        await _firestoreService.saveAddress(addr);
      }
      // Go back FIRST so the snackbar shows on the parent page
      Get.back(result: true);
      // Show snackbar after back — it'll appear on the addresses list
      AppSnack.success(
        'Saved',
        _isEdit ? 'Address updated.' : 'Address added.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Could not save address. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Address' : 'New Address')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Contact Info'),
                  const SizedBox(height: 10),
                  _field(
                    _recipientCtrl,
                    'Recipient Name',
                    Icons.person_outlined,
                    fillColor,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _phoneCtrl,
                    'Phone Number',
                    Icons.phone_outlined,
                    fillColor,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(15),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Label'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _labels.map((l) {
                      final active = _selectedLabel == l;
                      return ChoiceChip(
                        label: Text(l),
                        selected: active,
                        onSelected: (_) => setState(() => _selectedLabel = l),
                        selectedColor: AppTheme.primaryColor,
                        backgroundColor: fillColor,
                        labelStyle: TextStyle(
                          color: active
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: active
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: active
                            ? BorderSide.none
                            : BorderSide(
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300,
                              ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Location'),
                  const SizedBox(height: 10),
                  _field(
                    _streetCtrl,
                    'Street Address',
                    Icons.location_on_outlined,
                    fillColor,
                    keyboardType: TextInputType.streetAddress,
                    maxLines: 2,
                    maxLength: 100,
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
                          maxLength: 50,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          _provinceCtrl,
                          'Province/State',
                          Icons.map_outlined,
                          fillColor,
                          maxLength: 50,
                          textCapitalization: TextCapitalization.words,
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
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
                    _saving
                        ? 'Saving...'
                        : (_isEdit ? 'Update Address' : 'Save Address'),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF9E9EAA),
      letterSpacing: 0.5,
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon,
    Color fill, {
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fill,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
      ),
    );
  }
}
