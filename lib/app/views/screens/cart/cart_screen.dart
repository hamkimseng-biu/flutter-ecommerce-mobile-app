import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/currency_controller.dart';
import '../../../../../config/app_theme.dart';
import '../../../config/app_dialog.dart';
import '../../../routes/app_routes.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cc = Get.find<CartController>();
    final curCtrl = Get.find<CurrencyController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text('Cart (${cc.itemCount})')),
        actions: [
          Obx(
            () => cc.cartItems.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      AppDialog.confirm(
                        title: 'Clear Cart?',
                        message: 'Remove all items from your cart?',
                        confirmLabel: 'Clear',
                        confirmColor: AppTheme.errorColor,
                      ).then((confirmed) {
                        if (confirmed == true) cc.clearCart();
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.errorColor,
                    ),
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() {
        if (cc.cartItems.isEmpty) return _emptyCart();

        final grouped = <String, List<int>>{};
        for (int i = 0; i < cc.cartItems.length; i++) {
          final key = cc.cartItems[i].sellerId.isNotEmpty
              ? cc.cartItems[i].sellerId
              : 'unknown';
          grouped.putIfAbsent(key, () => []).add(i);
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppTheme.darkSurface : const Color(0xFFFAFAFA),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => cc.toggleAll(),
                    child: Icon(
                      cc.selectedIds.length == cc.cartItems.length &&
                              cc.cartItems.isNotEmpty
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          cc.selectedIds.length == cc.cartItems.length &&
                              cc.cartItems.isNotEmpty
                          ? AppTheme.primaryColor
                          : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('All', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  Text(
                    '${cc.selectedCount} selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: cc.scrollController,
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: grouped.length,
                itemBuilder: (ctx, idx) {
                  final sellerId = grouped.keys.elementAt(idx);
                  final indices = grouped[sellerId]!;
                  final firstItem = cc.cartItems[indices.first];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final pc = Get.find<ProductController>();
                          final seller = pc.getSellerById(sellerId);
                          if (seller != null) {
                            Get.toNamed(AppRoutes.shop, arguments: seller);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          color: isDark
                              ? AppTheme.darkSurface2
                              : const Color(0xFFF8F9FB),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.store_outlined,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                firstItem.sellerName.isNotEmpty
                                    ? firstItem.sellerName
                                    : 'Tiny Chicken',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: AppTheme.primaryColor,
                              ),
                              const Spacer(),
                              // Shop-level select all
                              GestureDetector(
                                onTap: () => cc.toggleShopItems(
                                  indices.map((i) => cc.cartItems[i]).toList(),
                                ),
                                child: Icon(
                                  indices.every(
                                        (i) =>
                                            cc.isItemSelected(cc.cartItems[i]),
                                      )
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...indices.map((i) {
                        final item = cc.cartItems[i];
                        return Dismissible(
                          key: Key(
                            '${item.productId}_${item.selectedSize}_${item.selectedColor}',
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            cc.removeFromCart(i);
                            return true;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: AppTheme.errorColor,
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              final pc = Get.find<ProductController>();
                              final product = pc.getProductById(item.productId);
                              if (product != null) {
                                Get.toNamed(
                                  AppRoutes.productDetail,
                                  arguments: product,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cc.toggleItem(item),
                                    child: Obx(
                                      () => Icon(
                                        cc.isItemSelected(item)
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        color: cc.isItemSelected(item)
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade300,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 72,
                                      height: 72,
                                      color: isDark
                                          ? AppTheme.darkSurface2
                                          : const Color(0xFFF1F3F5),
                                      child: item.image.isNotEmpty
                                          ? Image.network(
                                              item.image,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.image,
                                                    size: 28,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              size: 28,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.selectedColor.isNotEmpty
                                              ? '${item.selectedSize} · ${item.selectedColor}'
                                              : 'Size: ${item.selectedSize}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Obx(
                                              () => Text(
                                                curCtrl.formatPrice(item.price),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade200,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        cc.decrementQuantity(i),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      child: Icon(
                                                        Icons.remove,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                        ),
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        cc.incrementQuantity(i),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(
                                                        6,
                                                      ),
                                                      child: Icon(
                                                        Icons.add,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            // Taobao-style bottom bar — always visible
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // "All" checkbox
                    GestureDetector(
                      onTap: () => cc.toggleAll(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cc.selectedIds.length == cc.cartItems.length &&
                                    cc.cartItems.isNotEmpty
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color:
                                cc.selectedIds.length == cc.cartItems.length &&
                                    cc.cartItems.isNotEmpty
                                ? AppTheme.primaryColor
                                : Colors.grey,
                            size: 22,
                          ),
                          const Text(
                            'All',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total + discount info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cc.discount.value > 0 &&
                              cc.selectedIds.isNotEmpty)
                            Obx(
                              () => Text(
                                '-${curCtrl.formatPrice(cc.discount.value)} discount',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          Obx(
                            () => Text(
                              'Total: ${curCtrl.formatPrice(cc.selectedIds.isEmpty ? 0.0 : cc.selectedTotal)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (cc.discount.value > 0 &&
                              cc.selectedIds.isNotEmpty)
                            Obx(
                              () => Text(
                                'Saved ${curCtrl.formatPrice(cc.discount.value)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Checkout button
                    ElevatedButton(
                      onPressed:
                          cc.selectedIds.isEmpty && cc.cartItems.isNotEmpty
                          ? null
                          : () => Get.toNamed(AppRoutes.checkout),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(110, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        disabledBackgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF3A3A4A)
                            : const Color(0xFFE0E0E0),
                        disabledForegroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF9E9EAA)
                            : const Color(0xFF999999),
                      ),
                      child: Text(
                        cc.selectedIds.isEmpty && cc.cartItems.isNotEmpty
                            ? 'Select items'
                            : 'Checkout${cc.selectedCount > 0 ? ' (${cc.selectedCount})' : ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _emptyCart() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('🛒', style: TextStyle(fontSize: 44)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your cart is empty',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Add some items to get started!',
          style: TextStyle(fontSize: 14, color: Color(0xFF9E9EAA)),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Get.offAllNamed(AppRoutes.main),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(180, 50),
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text('Start Shopping', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}
