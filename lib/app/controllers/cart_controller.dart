import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/firebase_firestore_service.dart';
import '../../config/app_snack.dart';

class CartController extends GetxController {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

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

  Future<void> addToCart(
    ProductModel product, {
    String size = 'M',
    String color = '',
    int quantity = 1,
  }) async {
    final existingIdx = cartItems.indexWhere(
      (item) => item.productId == product.id,
    );
    if (existingIdx != -1) {
      cartItems[existingIdx].quantity += quantity;
      cartItems.refresh();
      // Sync to Firestore
      try {
        await _firestoreService.updateCartQuantity(
          product.id,
          cartItems[existingIdx].quantity,
        );
      } catch (_) {}
    } else {
      final item = CartItemModel(
        productId: product.id,
        name: product.name,
        image: product.images.isNotEmpty ? product.images[0] : '',
        price: product.effectivePrice,
        selectedSize: size,
        selectedColor: color,
        quantity: quantity,
      );
      cartItems.add(item);
      // Sync to Firestore
      try {
        await _firestoreService.addToCart(item);
      } catch (_) {}
    }
    AppSnack.success(
      'Added to Cart',
      quantity > 1 ? '$quantity × ${product.name}' : product.name,
    );
  }

  Future<void> removeFromCart(String productId) async {
    cartItems.removeWhere((item) => item.productId == productId);
    // Sync to Firestore
    try {
      await _firestoreService.removeFromCart(productId);
    } catch (_) {}
  }

  Future<void> incrementQuantity(int index) async {
    cartItems[index].quantity++;
    cartItems.refresh();
    // Sync to Firestore
    try {
      await _firestoreService.updateCartQuantity(
        cartItems[index].productId,
        cartItems[index].quantity,
      );
    } catch (_) {}
  }

  Future<void> decrementQuantity(int index) async {
    if (cartItems[index].quantity > 1) {
      cartItems[index].quantity--;
      cartItems.refresh();
      // Sync to Firestore
      try {
        await _firestoreService.updateCartQuantity(
          cartItems[index].productId,
          cartItems[index].quantity,
        );
      } catch (_) {}
    }
  }

  Future<void> applyPromo(String code) async {
    if (code.trim().isEmpty) return;

    // Validate against Firestore promo_codes collection
    final promo = await _firestoreService.validatePromoCode(code);
    if (promo != null) {
      promoCode.value = promo['code'] as String;
      final pct = (promo['discountPercent'] as num).toDouble();
      discount.value = subtotal * (pct / 100.0);
      AppSnack.success(
        'Promo Applied!',
        '${pct.toInt()}% discount applied to your order.',
      );
    } else {
      promoCode.value = '';
      discount.value = 0.0;
      AppSnack.error('Invalid Code', 'Please enter a valid promo code.');
    }
  }

  Future<void> clearCart() async {
    cartItems.clear();
    promoCode.value = '';
    discount.value = 0.0;
    // Sync to Firestore
    try {
      await _firestoreService.clearCart();
    } catch (_) {}
  }
}
