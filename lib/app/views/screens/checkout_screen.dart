import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../services/firebase_firestore_service.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';
import '../../routes/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _firestoreService = FirebaseFirestoreService();
  bool _placingOrder = false;
  final RxInt payMethod = 0.obs;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _loadingAddresses = true;
  List<Map<String, dynamic>> _userCards = [];
  List<Map<String, dynamic>> _userBanks = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final cards = await _firestoreService.getCards();
      final banks = await _firestoreService.getBankAccounts();
      if (mounted)
        setState(() {
          _userCards = cards;
          _userBanks = banks;
        });
    } catch (_) {}
  }

  String get _selectedPaymentLabel {
    if (payMethod.value < _userCards.length) {
      final c = _userCards[payMethod.value];
      return '${c['brand']} •••• ${(c['number'] as String).substring((c['number'] as String).length - 4)}';
    }
    final bankIdx = payMethod.value - _userCards.length;
    if (bankIdx >= 0 && bankIdx < _userBanks.length) {
      final b = _userBanks[bankIdx];
      return '${b['bankName']} •••• ${(b['accountNumber'] as String).length > 4 ? (b['accountNumber'] as String).substring((b['accountNumber'] as String).length - 4) : b['accountNumber']}';
    }
    return 'Cash on Delivery';
  }

  int get _codIndex => _userCards.length + _userBanks.length;

  Future<void> _loadAddresses() async {
    try {
      final addrs = await _firestoreService.getAddresses();
      if (addrs.isNotEmpty) {
        setState(() {
          _addresses = addrs;
          _selectedAddress = addrs.firstWhere(
            (a) => a['isDefault'] == true,
            orElse: () => addrs.first,
          );
          _loadingAddresses = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loadingAddresses = false);
  }

  void _showAddressPicker() {
    if (_addresses.isEmpty) {
      AppSnack.info('No Addresses', 'Add an address in your profile first.');
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Address',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._addresses.map(
              (a) => ListTile(
                leading: Icon(
                  a['label'] == 'Home'
                      ? Icons.home_rounded
                      : a['label'] == 'Office'
                      ? Icons.business_rounded
                      : Icons.location_on_rounded,
                  color: _selectedAddress == a
                      ? AppTheme.primaryColor
                      : Colors.grey,
                ),
                title: Text(
                  a['label'] ?? 'Address',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _selectedAddress == a ? AppTheme.primaryColor : null,
                  ),
                ),
                subtitle: Text(
                  '${a['street']}, ${a['city']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: _selectedAddress == a
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedAddress = a);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cc = Get.find<CartController>();
    if (_placingOrder || cc.cartItems.isEmpty) return;

    setState(() => _placingOrder = true);

    try {
      final items = cc.cartItems
          .map(
            (item) => {
              'name': item.name,
              'image': item.image,
              'price': item.price,
              'quantity': item.quantity,
              'size': item.selectedSize,
              'color': item.selectedColor,
            },
          )
          .toList();

      await _firestoreService.createOrder(
        items: items,
        subtotal: cc.subtotal,
        tax: cc.tax,
        shipping: cc.shippingFee,
        discount: cc.discount.value,
        total: cc.total,
        promoCode: cc.promoCode.value,
        paymentMethod: _selectedPaymentLabel,
      );

      if (!mounted) return;
      setState(() => _placingOrder = false);

      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 14),
              const Text(
                'Order Placed!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your order has been placed successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9E9EAA)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  cc.clearCart();
                  Get.offAllNamed(AppRoutes.main);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      AppSnack.error(
        'Order Failed',
        'Could not place order. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cc = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;
    final surface2 = isDark ? AppTheme.darkSurface2 : const Color(0xFFF1F3F5);
    final promoCtl = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (cc.cartItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🛍️', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 14),
                const Text(
                  'Nothing to checkout',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.main),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(160, 46),
                  ),
                  child: const Text('Continue Shopping'),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping Address
              _card(
                bg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Shipping Address',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _showAddressPicker,
                          child: const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_loadingAddresses)
                      const SizedBox(
                        height: 32,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    if (!_loadingAddresses && _selectedAddress == null)
                      GestureDetector(
                        onTap: () => Get.toNamed(AppRoutes.addresses),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.add_location_outlined,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add a shipping address',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_loadingAddresses && _selectedAddress != null) ...[
                      Text(
                        _selectedAddress!['recipient'] ?? 'Valued Customer',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedAddress!['phone'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9EAA),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_selectedAddress!['street']}, ${_selectedAddress!['city']}${(_selectedAddress!['province'] as String? ?? '').isNotEmpty ? ', ${_selectedAddress!['province']}' : ''} ${_selectedAddress!['zip'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9EAA),
                          height: 1.4,
                        ),
                      ),
                      if (_selectedAddress!['isDefault'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Order summary
              _card(
                bg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...cc.cartItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 44,
                                height: 44,
                                color: surface2,
                                child: item.image.isNotEmpty
                                    ? Image.network(
                                        item.image,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.image_outlined,
                                          size: 18,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Qty: ${item.quantity} | ${item.selectedSize}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF9E9EAA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    _r('Subtotal', '\$${cc.subtotal.toStringAsFixed(2)}'),
                    _r('Tax (5%)', '\$${cc.tax.toStringAsFixed(2)}'),
                    _r('Shipping', '\$${cc.shippingFee.toStringAsFixed(2)}'),
                    if (cc.discount.value > 0)
                      _r(
                        'Discount',
                        '-\$${cc.discount.toStringAsFixed(2)}',
                        green: true,
                      ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${cc.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Promo
              _card(
                bg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Promo Code',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      if (cc.promoCode.isNotEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.successColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                cc.promoCode.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                '-10%',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  cc.promoCode.value = '';
                                  cc.discount.value = 0;
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF9E9EAA),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: promoCtl,
                              onSubmitted: (v) => cc.applyPromo(v),
                              decoration: const InputDecoration(
                                hintText: 'Enter code (try CHICKEN10)',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFB0B0B0),
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 80,
                            child: ElevatedButton(
                              onPressed: () => cc.applyPromo(promoCtl.text),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 44),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Payment Method — dynamic from user's saved cards & banks
              _card(
                bg,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Method',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // User's credit/debit cards
                    ..._userCards.asMap().entries.map(
                      (e) => _pm(
                        e.key,
                        Icons.credit_card_rounded,
                        '${e.value['brand']?.toString().toUpperCase() ?? 'Card'} •••• ${(e.value['number'] as String).substring((e.value['number'] as String).length - 4)}',
                        e.value['holder'] ?? '',
                        payMethod,
                        bg,
                      ),
                    ),
                    if (_userCards.isNotEmpty) const SizedBox(height: 6),
                    // User's bank accounts
                    ..._userBanks.asMap().entries.map(
                      (e) => _pm(
                        _userCards.length + e.key,
                        Icons.account_balance_rounded,
                        e.value['bankName'] ?? 'Bank Account',
                        '•••• ${(e.value['accountNumber'] as String).length > 4 ? (e.value['accountNumber'] as String).substring((e.value['accountNumber'] as String).length - 4) : e.value['accountNumber']}',
                        payMethod,
                        bg,
                      ),
                    ),
                    if (_userBanks.isNotEmpty) const SizedBox(height: 6),
                    // Cash on Delivery (always available)
                    _pm(
                      _codIndex,
                      Icons.money_rounded,
                      'Cash on Delivery',
                      'Pay when you receive',
                      payMethod,
                      bg,
                    ),
                    if (_userCards.isEmpty && _userBanks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => Get.toNamed(AppRoutes.paymentMethods),
                          child: Text(
                            'Add a card or bank account →',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _placingOrder ? null : _placeOrder,
                  icon: _placingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.shopping_bag_rounded, size: 18),
                  label: Text(
                    _placingOrder
                        ? 'Placing Order...'
                        : 'Place Order - \$${cc.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _card(Color bg, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
      ],
    ),
    child: child,
  );

  Widget _r(String label, String value, {bool green = false}) {
    final c = green ? AppTheme.successColor : const Color(0xFF9E9EAA);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pm(
    int idx,
    IconData icon,
    String title,
    String sub,
    RxInt sel,
    Color bg,
  ) {
    return Obx(() {
      final active = sel.value == idx;
      final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
      return GestureDetector(
        onTap: () => sel.value = idx,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor.withValues(alpha: 0.06) : bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppTheme.primaryColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.primaryColor
                      : (isDark
                            ? AppTheme.darkSurface2
                            : const Color(0xFFE9ECEF)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: active ? Colors.white : const Color(0xFF9E9EAA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: active ? AppTheme.primaryColor : null,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9EAA),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryColor
                        : const Color(0xFF9E9EAA),
                    width: 2,
                  ),
                ),
                child: active
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      );
    });
  }
}
