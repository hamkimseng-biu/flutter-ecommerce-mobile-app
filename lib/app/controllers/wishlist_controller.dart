import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/product_model.dart';

class WishlistController extends GetxController {
  final RxList<ProductModel> wishlistItems = <ProductModel>[].obs;
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

  bool isInWishlist(String productId) {
    return wishlistItems.any((p) => p.id == productId);
  }

  void toggleWishlist(ProductModel product) {
    if (isInWishlist(product.id)) {
      wishlistItems.removeWhere((p) => p.id == product.id);
      Get.snackbar(
        'Removed',
        '${product.name} removed from wishlist.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF6C757D),
        colorText: Colors.white,
      );
    } else {
      wishlistItems.add(product.copyWith(isFavorite: true));
      Get.snackbar(
        'Added!',
        '${product.name} added to wishlist.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFFF6B35),
        colorText: Colors.white,
      );
    }
  }
}
