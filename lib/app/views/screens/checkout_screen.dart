import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../../config/app_theme.dart';
import '../../routes/app_routes.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;
    final surface2 = isDark ? AppTheme.darkSurface2 : const Color(0xFFF1F3F5);
    final RxInt payMethod = 0.obs;

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
              // Shipping
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
                        const Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      '123 Cluck Street, Hen House District\nPhnom Penh, Cambodia',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9E9EAA),
                        height: 1.5,
                      ),
                    ),
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
                              onPressed: () {},
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
              // Payment
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
                    _pm(
                      0,
                      Icons.credit_card_rounded,
                      'Credit / Debit Card',
                      'Visa, Mastercard',
                      payMethod,
                      bg,
                    ),
                    const SizedBox(height: 8),
                    _pm(
                      1,
                      Icons.account_balance_wallet_rounded,
                      'ABA / Wing / TrueMoney',
                      'Local e-wallets',
                      payMethod,
                      bg,
                    ),
                    const SizedBox(height: 8),
                    _pm(
                      2,
                      Icons.money_rounded,
                      'Cash on Delivery',
                      'Pay when you receive',
                      payMethod,
                      bg,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
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
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
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
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Place Order - \$${cc.total.toStringAsFixed(2)}'),
                  ],
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
