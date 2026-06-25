import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/cart_item_model.dart';
import '../services/firebase_firestore_service.dart';
import '../../config/app_snack.dart';
import 'auth_controller.dart';

class CartController extends GetxController {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();

  final RxList<CartItemModel> cartItems = <CartItemModel>[].obs;
  final RxSet<String> selectedIds = <String>{}.obs;
  final RxString promoCode = ''.obs;
  final RxDouble discount = 0.0.obs;
  final double taxRate = 0.05;
  final RxDouble _baseShippingFee = 5.99.obs;

  double get shippingFee {
    if (cartItems.isNotEmpty && cartItems.every((i) => i.freeShipping)) {
      return 0.0;
    }
    return _baseShippingFee.value;
  }

  @override
  void onInit() {
    super.onInit();
    _loadShippingFee();
    _loadCartFromFirestore();
  }

  Future<void> _loadShippingFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('shipping')
          .get();
      if (doc.exists) {
        _baseShippingFee.value = (doc.data()?['fee'] ?? 5.99).toDouble();
      }
    } catch (_) {}
  }

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

  void _loadCartFromFirestore() {
    _firestoreService.getCartStream().listen((items) {
      // Collect keys previously selected by the user
      final previousSelected = Set<String>.from(selectedIds);

      cartItems.assignAll(items);

      // Never auto-select on initial load — items start unselected.
      // On subsequent updates (e.g. quantity change from another device),
      // preserve the user's existing selections.
      // Only add keys for newly-appeared items that were previously tracked,
      // and remove keys for items that no longer exist.
      if (previousSelected.isNotEmpty) {
        for (final item in items) {
          final key = _cartKeyFromItem(item);
          if (previousSelected.contains(key)) {
            selectedIds.add(key);
          }
        }
      }
      // Clean up stale keys
      final currentKeys = items.map((i) => _cartKeyFromItem(i)).toSet();
      selectedIds.removeWhere((key) => !currentKeys.contains(key));
    }, onError: (_) {});
  }

  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);
  int get selectedCount => cartItems
      .where((i) => selectedIds.contains(_cartKeyFromItem(i)))
      .fold(0, (sum, i) => sum + i.quantity);
  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax + shippingFee - discount.value;

  // Selected-only calculations for checkout
  List<CartItemModel> get selectedItems => cartItems
      .where((i) => selectedIds.contains(_cartKeyFromItem(i)))
      .toList();
  double get selectedSubtotal =>
      selectedItems.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get selectedTotal =>
      selectedSubtotal +
      (selectedSubtotal * taxRate) +
      shippingFee -
      discount.value;

  /// Unique key for variant-aware cart storage
  String _cartKey(String productId, String size, String color) =>
      '$productId${size.isNotEmpty ? '_$size' : ''}${color.isNotEmpty ? '_$color' : ''}';
  String _cartKeyFromItem(CartItemModel item) =>
      _cartKey(item.productId, item.selectedSize, item.selectedColor);

  bool isItemSelected(CartItemModel item) =>
      selectedIds.contains(_cartKeyFromItem(item));
  void toggleItem(CartItemModel item) {
    final key = _cartKeyFromItem(item);
    if (selectedIds.contains(key)) {
      selectedIds.remove(key);
    } else {
      selectedIds.add(key);
    }
  }

  void toggleAll() {
    if (selectedIds.length == cartItems.length) {
      selectedIds.clear();
    } else {
      for (final item in cartItems) {
        selectedIds.add(_cartKeyFromItem(item));
      }
    }
  }

  void toggleShopItems(List<CartItemModel> items) {
    final allSelected = items.every((i) => isItemSelected(i));
    if (allSelected) {
      for (final i in items) {
        selectedIds.remove(_cartKeyFromItem(i));
      }
    } else {
      for (final i in items) {
        selectedIds.add(_cartKeyFromItem(i));
      }
    }
  }

  Future<void> addToCart(
    ProductModel product, {
    String size = 'M',
    String color = '',
    int quantity = 1,
  }) async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      auth.requireAuth(message: 'Sign in to add items to your cart.');
      return;
    }
    final key = _cartKey(product.id, size, color);
    final existingIdx = cartItems.indexWhere(
      (item) =>
          _cartKey(item.productId, item.selectedSize, item.selectedColor) ==
          key,
    );
    if (existingIdx != -1) {
      cartItems[existingIdx].quantity += quantity;
      cartItems.refresh();
      try {
        await _firestoreService.updateCartQuantity(
          key,
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
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        freeShipping: product.freeShipping,
      );
      cartItems.add(item);
      try {
        await _firestoreService.addToCart(key, item);
      } catch (_) {}
    }
    AppSnack.success(
      'Added to Cart',
      quantity > 1 ? '$quantity × ${product.name}' : product.name,
    );
  }

  Future<void> removeFromCart(int index) async {
    if (index < 0 || index >= cartItems.length) return;
    final item = cartItems[index];
    final key = _cartKey(item.productId, item.selectedSize, item.selectedColor);
    selectedIds.remove(key);
    cartItems.removeAt(index);
    try {
      await _firestoreService.removeFromCart(key);
    } catch (_) {}
  }

  Future<void> incrementQuantity(int index) async {
    cartItems[index].quantity++;
    cartItems.refresh();
    final item = cartItems[index];
    try {
      await _firestoreService.updateCartQuantity(
        _cartKey(item.productId, item.selectedSize, item.selectedColor),
        item.quantity,
      );
    } catch (_) {}
  }

  Future<void> decrementQuantity(int index) async {
    if (cartItems[index].quantity <= 1) return;
    cartItems[index].quantity--;
    cartItems.refresh();
    final item = cartItems[index];
    try {
      await _firestoreService.updateCartQuantity(
        _cartKey(item.productId, item.selectedSize, item.selectedColor),
        item.quantity,
      );
    } catch (_) {}
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
