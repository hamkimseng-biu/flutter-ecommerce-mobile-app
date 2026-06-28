import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../controllers/wishlist_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../../config/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wc = Get.find<WishlistController>();
    final bg = isDark ? AppTheme.darkSurface : Colors.white;
    // Currency controller — instantiate once at top of build
    final curCtrl = Get.find<CurrencyController>();

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'product-${product.id}',
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image — fixed 150px, badges overlay via Stack
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: product.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: product.images[0],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _ph(),
                              errorWidget: (_, __, ___) => _ph(),
                            )
                          : _ph(),
                    ),
                  ),
                  if (product.discountPercentDisplay > 3)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _b(
                        '-${product.discountPercentDisplay.toInt()}%',
                        product.isFlashSale
                            ? AppTheme.flashSaleColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  if (product.isFlashSale &&
                      product.discountPercentDisplay <= 3)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: _b('FLASH', Colors.amber, icon: Icons.bolt, sz: 8),
                    ),
                  if (product.isFlashSale && product.discountPercentDisplay > 3)
                    Positioned(
                      top: 22,
                      left: 6,
                      child: _b('FLASH', Colors.amber, icon: Icons.bolt, sz: 8),
                    ),
                  if (product.showSoldCount && product.soldCount > 1000)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: _b(
                        '${(product.soldCount / 1000).toStringAsFixed(1)}k sold',
                        Colors.black54,
                      ),
                    ),
                  if (product.freeShipping)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: _b(
                        'Free Ship',
                        AppTheme.successColor.withValues(alpha: 0.85),
                        sz: 7,
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Obx(() {
                      final fav = wc.isInWishlist(product.id);
                      return GestureDetector(
                        onTap: () => wc.toggleWishlist(product),
                        child: TweenAnimationBuilder<double>(
                          key: ValueKey(fav),
                          tween: Tween(begin: 0.6, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.elasticOut,
                          builder: (_, s, __) => Transform.scale(
                            scale: s,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.3 : 0.06,
                                    ),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Icon(
                                fav ? Icons.favorite : Icons.favorite_border,
                                color: fav
                                    ? AppTheme.errorColor
                                    : (isDark ? Colors.white54 : Colors.grey),
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              // Info — fills remaining space
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.lightTextPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.sellerName,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.darkTextSecondary
                              : AppTheme.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product.showRating)
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppTheme.secondaryColor,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${product.rating}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (product.showReviewCount) ...[
                              const SizedBox(width: 2),
                              Text(
                                '(${product.reviewCount})',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : const Color(0xFF9E9EAA),
                                ),
                              ),
                            ],
                          ],
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(
                                () => Text(
                                  curCtrl.formatPriceCompact(
                                    product.effectivePrice,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              if (product.originalPrice > 0 &&
                                  product.discountPercentDisplay > 0)
                                Obx(
                                  () => Text(
                                    curCtrl.formatPriceCompact(
                                      product.originalPrice,
                                    ),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppTheme.darkTextSecondary
                                          : const Color(0xFF9E9EAA),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          GestureDetector(
                            onTap: onTap,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ph() => const Center(
    child: Icon(Icons.image_outlined, size: 36, color: Colors.grey),
  );

  /// Returns black or white depending on the perceived brightness of [color].
  Color _textColorForBg(Color bg) {
    // Compute relative luminance (sRGB)
    final r = bg.r, g = bg.g, b = bg.b;
    final luma = (0.299 * r + 0.587 * g + 0.114 * b) * bg.opacity;
    return luma > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _b(String t, Color c, {IconData? icon, double sz = 9}) {
    final textColor = _textColorForBg(c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(5),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: sz, color: textColor),
                const SizedBox(width: 2),
                Text(
                  t,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Text(
              t,
              style: TextStyle(
                color: textColor,
                fontSize: sz,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
