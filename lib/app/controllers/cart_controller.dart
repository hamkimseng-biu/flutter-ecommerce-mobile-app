import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';

class CartController extends GetxController {
  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxString promoCode = ''.obs;
  final RxDouble discount = 0.0.obs;
  final double taxRate = 0.05;
  final double shippingFee = 5.99;
  final ScrollController scrollController = ScrollController();

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax + shippingFee - discount.value;

  void addToCart(
    ProductModel product, {
    String size = 'M',
    String color = '',
    int quantity = 1,
  }) {
    final existingIdx = cartItems.indexWhere(
      (item) => item.productId == product.id,
    );
    if (existingIdx != -1) {
      cartItems[existingIdx].quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(
        CartItemModel(
          productId: product.id,
          name: product.name,
          image: product.images.isNotEmpty ? product.images[0] : '',
          price: product.effectivePrice,
          selectedSize: size,
          selectedColor: color,
          quantity: quantity,
        ),
      );
    }
    _showSnack(
      'Added to Cart',
      quantity > 1 ? '$quantity × ${product.name}' : product.name,
      Icons.check_circle_rounded,
      const Color(0xFF2E7D32),
    );
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.productId == productId);
  }

  void incrementQuantity(int index) {
    cartItems[index].quantity++;
    cartItems.refresh();
  }

  void decrementQuantity(int index) {
    if (cartItems[index].quantity > 1) {
      cartItems[index].quantity--;
      cartItems.refresh();
    }
  }

  void applyPromo(String code) {
    if (code.toUpperCase() == 'CHICKEN10') {
      promoCode.value = code;
      discount.value = subtotal * 0.10;
      _showSnack(
        'Promo Applied!',
        '10% discount applied to your order.',
        Icons.local_offer_rounded,
        const Color(0xFF2E7D32),
      );
    } else {
      _showSnack(
        'Invalid Code',
        'Please enter a valid promo code.',
        Icons.error_outline_rounded,
        const Color(0xFFE53935),
      );
    }
  }

  void clearCart() {
    cartItems.clear();
    promoCode.value = '';
    discount.value = 0.0;
  }

  void _showSnack(String title, String message, IconData icon, Color color) {
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      backgroundColor: color,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }
}
