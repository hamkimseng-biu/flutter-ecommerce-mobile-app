import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../services/firebase_firestore_service.dart';
import '../../config/app_snack.dart';

class WishlistController extends GetxController {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<ProductModel> wishlistItems = <ProductModel>[].obs;
  final ScrollController scrollController = ScrollController();
  bool _initialized = false;

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

  /// Load wishlist from Firestore and fetch full product data
  Future<void> loadWishlist() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final ids = await _firestoreService.getWishlistIds();
      if (ids.isEmpty) return;
      // Fetch products in batches
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
  }

  bool isInWishlist(String productId) {
    return wishlistItems.any((p) => p.id == productId);
  }

  Future<void> toggleWishlist(ProductModel product) async {
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
}
