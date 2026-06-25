import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/wishlist_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../../routes/app_routes.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wc = Get.find<WishlistController>();
    final cc = Get.find<CartController>();
    Future.microtask(() => wc.loadWishlist());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        centerTitle: true,
        actions: [
          Obx(
            () => wc.wishlistItems.isNotEmpty
                ? Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 22),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 4),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Obx(() {
        if (wc.wishlistItems.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('💝', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Your wishlist is empty',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the heart on any product to save it here for later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF9E9EAA)),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.main),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Explore Products',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Header with count + add all button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '${wc.wishlistItems.length} ${wc.wishlistItems.length == 1 ? 'item' : 'items'} saved',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E9EAA),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view & pick options',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Wishlist refreshed via controller
                },
                color: AppTheme.primaryColor,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  controller: wc.scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: wc.wishlistItems.length,
                  itemBuilder: (ctx, i) {
                    final p = wc.wishlistItems[i];
                    return Dismissible(
                      key: Key(p.id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => wc.toggleWishlist(p),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.heart_broken,
                          color: Colors.white,
                        ),
                      ),
                      child: ProductCard(
                        product: p,
                        onTap: () =>
                            Get.toNamed(AppRoutes.productDetail, arguments: p),
                        onAddToCart: () => cc.addToCart(p),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
