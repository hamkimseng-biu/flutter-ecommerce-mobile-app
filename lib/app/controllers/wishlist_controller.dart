import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_firestore_service.dart';
import '../../config/app_snack.dart';
import 'auth_controller.dart';

class WishlistController extends GetxController {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<ProductModel> wishlistItems = <ProductModel>[].obs;
  final ScrollController scrollController = ScrollController();
  bool _loading = false;

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

  /// Load wishlist from Firestore and fetch full product data.
  /// Re-fetches on every call so discount/price changes are reflected.
  /// Guarded against re-entrant calls from repeated widget rebuilds.
  Future<void> loadWishlist() async {
    if (_loading) return;
    _loading = true;
    try {
      final ids = await _firestoreService.getWishlistIds();
      if (ids.isEmpty) {
        wishlistItems.clear();
        return;
      }
      // Fetch products fresh from Firestore
      final products = <ProductModel>[];
      for (final id in ids) {
        try {
          final doc = await _firestore.collection('products').doc(id).get();
          if (doc.exists) {
            products.add(ProductModel.fromFirestore(doc));
          }
        } catch (_) {}
      }
      wishlistItems.assignAll(products);
    } catch (_) {}
    _loading = false;
  }

  bool isInWishlist(String productId) {
    return wishlistItems.any((p) => p.id == productId);
  }

  Future<void> toggleWishlist(ProductModel product) async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      auth.requireAuth(message: 'Sign in to save items to your wishlist.');
      return;
    }
    if (isInWishlist(product.id)) {
      wishlistItems.removeWhere((p) => p.id == product.id);
      try {
        await _firestoreService.removeFromWishlist(product.id);
      } catch (_) {}
      AppSnack.info('Removed', '${product.name} removed from wishlist.');
    } else {
      wishlistItems.add(product.copyWith(isFavorite: true));
      try {
        await _firestoreService.addToWishlist(product.id);
      } catch (_) {}
      AppSnack.success('Added!', '${product.name} added to wishlist.');
    }
  }

  Future<void> clearAll() async {
    try {
      await _firestoreService.clearAllWishlist();
      wishlistItems.clear();
      AppSnack.success('Cleared', 'All wishlist items removed.');
    } catch (_) {
      AppSnack.error('Error', 'Could not clear wishlist.');
    }
  }
}
