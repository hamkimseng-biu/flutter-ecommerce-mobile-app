import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';
import '../../services/firebase_firestore_service.dart';

/// Full-screen bank account add/edit with dropdown bank selection,
/// formatted account number, and account type selector.
class AddEditBankScreen extends StatefulWidget {
  const AddEditBankScreen({super.key});
  @override
  State<AddEditBankScreen> createState() => _AddEditBankScreenState();
}

class _AddEditBankScreenState extends State<AddEditBankScreen> {
  final _bankCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _routingCtrl = TextEditingController();

  String _accountType = 'checking';
  bool _saving = false;
  bool _isEdit = false;
  String? _existingId;
  String? _selectedBank; // null = custom entry

  static const _bankList = [
    'ABA Bank',
    'ACLEDA Bank',
    'Wing Bank',
    'TrueMoney',
    'Canadia Bank',
    'Sathapana Bank',
    'Maybank',
    'Bred Bank',
    'CIMB Bank',
    'Chip Mong Bank',
    'Phillip Bank',
    'RHB Bank',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _isEdit = true;
      _existingId = args['firestoreId'] as String?;
      final bankName = args['bankName'] as String? ?? '';
      _selectedBank = _bankList.contains(bankName) ? bankName : null;
      if (_selectedBank == null && bankName.isNotEmpty) _selectedBank = 'Other';
      _bankCtrl.text = bankName;
      _holderCtrl.text = args['accountHolder'] as String? ?? '';
      _accountCtrl.text = args['accountNumber'] as String? ?? '';
      _routingCtrl.text = args['routingNumber'] as String? ?? '';
      _accountType = args['accountType'] as String? ?? 'checking';
    }
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _holderCtrl.dispose();
    _accountCtrl.dispose();
    _routingCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (_bankCtrl.text.trim().isEmpty ||
        _holderCtrl.text.trim().isEmpty ||
        _accountCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Please fill all required fields.');
      return;
    }
    setState(() => _saving = true);
    final bank = {
      'bankName': _bankCtrl.text.trim(),
      'accountHolder': _holderCtrl.text.trim(),
      'accountNumber': _accountCtrl.text.trim(),
      'routingNumber': _routingCtrl.text.trim(),
      'accountType': _accountType,
      'isDefault': false,
    };
    try {
      final service = FirebaseFirestoreService();
      if (_isEdit &&
          _existingId != null &&
          _existingId!.isNotEmpty &&
          !_existingId!.startsWith('mock')) {
        await service.saveBankAccount(bank, docId: _existingId!);
      } else {
        await service.saveBankAccount(bank);
      }
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.success(
          _isEdit ? 'Updated' : 'Added',
          _isEdit ? 'Bank account updated.' : 'Bank account added.',
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error('Error', 'Could not save bank account. Try again.');
      }
    }
  }

  Color _bankColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('aba')) return const Color(0xFF004B87);
    if (n.contains('acleda')) return const Color(0xFF003399);
    if (n.contains('wing')) return const Color(0xFF009444);
    if (n.contains('canadia')) return const Color(0xFFC41E3A);
    return const Color(0xFF2C3E50);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final accent = _bankColor(_bankCtrl.text);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Bank Account' : 'Add Bank Account'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Bank card preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, accent.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Colors.white60,
                        size: 26,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _accountType.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _bankCtrl.text.isEmpty ? 'Bank Name' : _bankCtrl.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _accountCtrl.text.isEmpty
                        ? '••••••••••'
                        : _mask(_accountCtrl.text),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _holderCtrl.text.isEmpty
                        ? 'Account Holder'
                        : _holderCtrl.text.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bank Name Dropdown
            _label('Bank Name'), const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBank,
              decoration: _deco(
                'Select your bank',
                Icons.account_balance,
                fill,
              ),
              isExpanded: true,
              items: _bankList
                  .map(
                    (b) => DropdownMenuItem(
                      value: b,
                      child: Text(b, style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedBank = v;
                  if (v != null && v != 'Other') _bankCtrl.text = v;
                  if (v == 'Other') _bankCtrl.text = '';
                });
              },
            ),
            if (_selectedBank == 'Other' || _selectedBank == null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _bankCtrl,
                decoration: _deco('Enter bank name', Icons.edit, fill),
              ),
            ],
            const SizedBox(height: 16),

            _label('Account Holder Name'), const SizedBox(height: 8),
            TextField(
              controller: _holderCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: _deco(
                'Full account holder name',
                Icons.person_outline,
                fill,
              ),
            ),
            const SizedBox(height: 16),

            _label('Account Number'), const SizedBox(height: 8),
            TextField(
              controller: _accountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('Account number', Icons.credit_card, fill),
            ),
            const SizedBox(height: 16),

            _label('Routing Number (optional)'), const SizedBox(height: 8),
            TextField(
              controller: _routingCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('Routing or SWIFT code', Icons.route, fill),
            ),
            const SizedBox(height: 20),

            // Account type selector
            _label('Account Type'), const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _typeCard(
                    'checking',
                    'Checking',
                    Icons.credit_card,
                    _accountType == 'checking',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _typeCard(
                    'savings',
                    'Savings',
                    Icons.savings,
                    _accountType == 'savings',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
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
                  _isEdit ? 'Update Account' : 'Add Account',
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(String type, String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _accountType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? AppTheme.primaryColor.withValues(alpha: 0.05)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primaryColor : Colors.grey.shade400,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppTheme.primaryColor : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _mask(String num) {
    if (num.length <= 4) return num;
    final last = num.substring(num.length - 4);
    return '•••• $last';
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );
  InputDecoration _deco(String hint, IconData icon, Color fill) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 14,
        ),
        isDense: true,
      );
}
