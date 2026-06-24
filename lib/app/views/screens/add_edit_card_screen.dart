import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';
import '../../services/firebase_firestore_service.dart';

/// Polished card add/edit screen with live preview, auto-formatting,
/// smart brand detection, and expiry validation.
class AddEditCardScreen extends StatefulWidget {
  const AddEditCardScreen({super.key});
  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  String _brand = 'visa';
  bool _saving = false;
  bool _isEdit = false;
  String? _existingId;

  static const _brands = {
    'visa': ('Visa', Color(0xFF1A1F71), Color(0xFF3D5AFE), 16),
    'mastercard': ('Mastercard', Color(0xFFEB001B), Color(0xFFF79E1B), 16),
    'amex': ('Amex', Color(0xFF2E77BC), Color(0xFF69B3E7), 15),
    'jcb': ('JCB', Color(0xFF0E4C92), Color(0xFF179BD7), 16),
  };

  (String, Color, Color, int) get _info => _brands[_brand] ?? _brands['visa']!;

  String _detectBrand(String num) {
    final c = num.replaceAll(' ', '');
    if (c.startsWith('4')) return 'visa';
    if (c.startsWith('5')) return 'mastercard';
    if (c.startsWith('34') || c.startsWith('37')) return 'amex';
    if (c.startsWith('35')) return 'jcb';
    return _brand;
  }

  int get _maxLen => _info.$4;

  // ── Formatters ────────────────────────────────────

  String _formatCard(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    final cap = d.length > _maxLen ? d.substring(0, _maxLen) : d;
    final b = StringBuffer();
    for (int i = 0; i < cap.length; i++) {
      if (_brand == 'amex') {
        if (i == 4 || i == 10) b.write(' ');
      } else {
        if (i > 0 && i % 4 == 0) b.write(' ');
      }
      b.write(cap[i]);
    }
    return b.toString();
  }

  String _formatExpiry(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.length >= 2) {
      final mm = int.tryParse(d.substring(0, 2)) ?? 0;
      final safe = mm > 12 ? '12' : d.substring(0, 2);
      return d.length > 2
          ? '$safe/${d.substring(2, d.length > 4 ? 4 : d.length)}'
          : safe;
    }
    return d;
  }

  // ── Init ──────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      _isEdit = true;
      _existingId = args['firestoreId'] as String?;
      final num = args['number'] as String? ?? '';
      _brand = _detectBrand(num);
      _numberCtrl.text = _formatCard(num);
      _holderCtrl.text = args['holder'] as String? ?? '';
      _expiryCtrl.text = args['expiry'] as String? ?? '';
    }
    _numberCtrl.addListener(() {
      final f = _formatCard(_numberCtrl.text);
      final s = _numberCtrl.selection.baseOffset;
      final old = _numberCtrl.text.length;
      _numberCtrl.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: s + (f.length - old)),
      );
      final nb = _detectBrand(f);
      if (nb != _brand) setState(() => _brand = nb);
    });
    _expiryCtrl.addListener(() {
      final f = _formatExpiry(_expiryCtrl.text);
      _expiryCtrl.value = TextEditingValue(
        text: f,
        selection: TextSelection.collapsed(offset: f.length),
      );
    });
  }

  @override
  void dispose() {
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  // ── Save ──────────────────────────────────────────

  void _save() async {
    final clean = _numberCtrl.text.replaceAll(' ', '');
    if (clean.length < _maxLen) {
      AppSnack.error(
        'Invalid Card',
        'Enter a valid $_maxLen-digit card number.',
      );
      return;
    }
    if (_holderCtrl.text.trim().isEmpty) {
      AppSnack.error('Required', 'Enter the cardholder name.');
      return;
    }
    if (!_validExpiry(_expiryCtrl.text)) {
      AppSnack.error('Invalid Expiry', 'Enter a valid future MM/YY.');
      return;
    }

    // Check authentication
    final uid = FirebaseFirestoreService().currentUserId;
    if (uid.isEmpty) {
      AppSnack.error(
        'Login Required',
        'Please log in to save payment methods.',
      );
      return;
    }

    setState(() => _saving = true);
    final card = {
      'number': clean,
      'holder': _holderCtrl.text.trim(),
      'expiry': _expiryCtrl.text.trim(),
      'brand': _brand,
      'isDefault': false,
    };
    try {
      final service = FirebaseFirestoreService();
      if (_isEdit &&
          _existingId != null &&
          _existingId!.isNotEmpty &&
          !_existingId!.contains('mock')) {
        await service.saveCard(card, docId: _existingId!);
      } else {
        await service.saveCard(card);
      }
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.success(
          _isEdit ? 'Updated' : 'Added',
          _isEdit ? 'Card updated.' : 'Card added.',
        );
        Get.back(result: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnack.error(
          'Error',
          'Could not save: ${e.toString().replaceFirst("Exception: ", "")}',
        );
      }
    }
  }

  bool _validExpiry(String e) {
    final p = e.split('/');
    if (p.length != 2) return false;
    final mm = int.tryParse(p[0]), yy = int.tryParse(p[1]);
    if (mm == null || yy == null || mm < 1 || mm > 12) return false;
    final exp = DateTime(2000 + yy, mm + 1, 0);
    return exp.isAfter(DateTime.now());
  }

  // ── Build ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final (name, c1, c2, _) = _info;
    final formatted = _numberCtrl.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _numberCtrl.text;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Card' : 'Add New Card'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card preview
            Container(
              width: double.infinity,
              height: 210,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [c1, c2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: c1.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 42,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.15),
                            ],
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.contactless,
                        color: Colors.white60,
                        size: 26,
                      ),
                    ],
                  ),
                  Text(
                    formatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CARD HOLDER',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 9,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _holderCtrl.text.isEmpty
                                  ? 'YOUR NAME'
                                  : _holderCtrl.text.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'EXPIRES',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _expiryCtrl.text.isEmpty
                                ? 'MM/YY'
                                : _expiryCtrl.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _label('Card Number'), const SizedBox(height: 8),
            TextField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: _maxLen + 3,
              decoration: _deco(
                '0000 0000 0000 0000',
                Icons.credit_card_outlined,
                fill,
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 12, top: 14),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c1,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _label('Cardholder Name'), const SizedBox(height: 8),
            TextField(
              controller: _holderCtrl,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: _deco(
                'FULL NAME ON CARD',
                Icons.person_outline,
                fill,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Expiry Date'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _expiryCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 5,
                        decoration: _deco('MM/YY', Icons.calendar_today, fill),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('CVV'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: _brand == 'amex' ? 4 : 3,
                        obscureText: true,
                        decoration: _deco('•••', Icons.lock_outline, fill),
                      ),
                    ],
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
                  _isEdit ? 'Update Card' : 'Add Card',
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
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Color(0xFF9E9EAA),
                ),
                const SizedBox(width: 6),
                Text(
                  'Your card info is encrypted and secure',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Text(
    t,
    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );
  InputDecoration _deco(
    String hint,
    IconData icon,
    Color fill, {
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
    prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade500),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    counterText: '',
    isDense: true,
  );
}
