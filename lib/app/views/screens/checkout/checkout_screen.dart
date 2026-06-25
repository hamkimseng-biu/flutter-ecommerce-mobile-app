import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/currency_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../routes/app_routes.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _firestoreService = FirebaseFirestoreService();
  bool _placingOrder = false;
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic>? _selectedPayment;
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

  Map<String, dynamic>? get _defaultCard {
    if (_userCards.isEmpty) return null;
    return _userCards.firstWhere(
      (c) => c['isDefault'] == true,
      orElse: () => _userCards.first,
    );
  }

  Map<String, dynamic>? get _defaultBank {
    if (_userBanks.isEmpty) return null;
    return _userBanks.firstWhere(
      (b) => b['isDefault'] == true,
      orElse: () => _userBanks.first,
    );
  }

  String get _selectedPaymentLabel {
    if (_defaultCard != null) {
      return 'Card •••• ${(_defaultCard!['number'] as String).substring((_defaultCard!['number'] as String).length - 4)}';
    }
    if (_defaultBank != null) {
      return '${_defaultBank!['bankName']} •••• ${(_defaultBank!['accountNumber'] as String).length > 4 ? (_defaultBank!['accountNumber'] as String).substring((_defaultBank!['accountNumber'] as String).length - 4) : _defaultBank!['accountNumber']}';
    }
    return 'Cash on Delivery';
  }

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

  void _showPaymentPicker() {
    final options = <Map<String, dynamic>>[];
    // Cards section
    for (final c in _userCards) {
      options.add({
        'icon': Icons.credit_card_rounded,
        'title':
            '${c['brand']?.toString().toUpperCase() ?? 'Card'} •••• ${(c['number'] as String).substring((c['number'] as String).length - 4)}',
        'sub': c['holder'] ?? '',
        'id': 'card_${c['firestoreId']}',
      });
    }
    // Banks section
    for (final b in _userBanks) {
      options.add({
        'icon': Icons.account_balance_rounded,
        'title': b['bankName'] ?? 'Bank',
        'sub':
            '•••• ${(b['accountNumber'] as String).length > 4 ? (b['accountNumber'] as String).substring((b['accountNumber'] as String).length - 4) : b['accountNumber']}',
        'id': 'bank_${b['firestoreId']}',
      });
    }
    // COD
    options.add({
      'icon': Icons.money_rounded,
      'title': 'Cash on Delivery',
      'sub': 'Pay when you receive',
      'id': 'cod',
    });
    // Add new
    options.add({
      'icon': Icons.add_circle_outline,
      'title': 'Add new payment method',
      'sub': 'Credit card or bank account',
      'id': 'add',
    });

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
              'Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_userCards.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 2),
                child: Text(
                  '💳 Credit / Debit Cards',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9E9EAA),
                  ),
                ),
              ),
            ...options.map(
              (o) => ListTile(
                leading: Icon(
                  o['icon'] as IconData,
                  color: AppTheme.primaryColor,
                ),
                title: Text(
                  o['title'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  o['sub'] as String,
                  style: const TextStyle(fontSize: 11),
                ),
                trailing:
                    _selectedPayment != null &&
                        _selectedPayment!['id'] == o['id']
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.primaryColor,
                      )
                    : null,
                onTap: () {
                  final id = o['id'] as String;
                  if (id == 'add') {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.paymentMethods);
                  } else {
                    setState(
                      () => _selectedPayment = {
                        'id': id,
                        'icon': o['icon'],
                        'title': o['title'],
                        'sub': o['sub'],
                        'label': (o['title'] as String),
                      },
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      auth.requireAuth(message: 'Sign in to place an order.');
      return;
    }
    final cc = Get.find<CartController>();
    if (_placingOrder || cc.cartItems.isEmpty) return;

    if (_selectedAddress == null) {
      AppSnack.error(
        'Address Required',
        'Please add a shipping address to continue.',
      );
      return;
    }

    setState(() => _placingOrder = true);

    try {
      // Only use selected items — never fall back to all items
      if (cc.selectedItems.isEmpty) {
        AppSnack.error(
          'Select Items',
          'Please select items in your cart to checkout.',
        );
        setState(() => _placingOrder = false);
        return;
      }
      final items = cc.selectedItems
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
        subtotal: cc.selectedSubtotal,
        tax: cc.selectedSubtotal * cc.taxRate,
        shipping: cc.shippingFee,
        discount: cc.discount.value,
        total: cc.selectedTotal,
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
    final curCtrl = Get.find<CurrencyController>();
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
              Obx(() {
                final useSelected = cc.selectedItems.isNotEmpty;
                final displayItems = useSelected
                    ? cc.selectedItems
                    : cc.cartItems;
                final displaySubtotal = useSelected
                    ? cc.selectedSubtotal
                    : cc.subtotal;
                final displayTax = displaySubtotal * cc.taxRate;
                final displayTotal = useSelected ? cc.selectedTotal : cc.total;
                return _card(
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
                      ...displayItems.map(
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
                              Obx(
                                () => Text(
                                  curCtrl.formatPrice(item.totalPrice),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      Obx(
                        () => _r(
                          'Subtotal',
                          curCtrl.formatPrice(displaySubtotal),
                        ),
                      ),
                      Obx(
                        () => _r('Tax (5%)', curCtrl.formatPrice(displayTax)),
                      ),
                      Obx(
                        () =>
                            _r('Shipping', curCtrl.formatPrice(cc.shippingFee)),
                      ),
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
                          Obx(
                            () => Text(
                              curCtrl.formatPrice(displayTotal),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
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
              // Payment Method — tappable, opens bottom sheet picker
              GestureDetector(
                onTap: _showPaymentPicker,
                child: _card(
                  bg,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.payment_outlined,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Color(0xFF9E9EAA),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_selectedPayment != null)
                        _pmTile(
                          _selectedPayment!['icon'] as IconData,
                          _selectedPayment!['title'] as String,
                          _selectedPayment!['sub'] as String,
                        )
                      else
                        _pmTile(
                          Icons.money_rounded,
                          'Cash on Delivery',
                          'Pay when you receive',
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        );
      }),
      // Taobao-style fixed bottom bar
      bottomNavigationBar: Obx(() {
        final cc = Get.find<CartController>();
        final hasSelection = cc.selectedItems.isNotEmpty;
        final displayTotal = hasSelection ? cc.selectedTotal : 0.0;
        final itemCount = hasSelection ? cc.selectedCount : 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total payment:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9E9EAA),
                        ),
                      ),
                      Text(
                        '\$${displayTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _placingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _placingOrder
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Place Order ($itemCount)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _card(Color bg, Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9EAA)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: green ? AppTheme.successColor : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pmTile(IconData icon, String title, String sub) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF9E9EAA),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppTheme.primaryColor,
            size: 22,
          ),
        ],
      ),
    );
  }
}
