import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../../routes/app_routes.dart';

class PopularShopsScreen extends StatelessWidget {
  const PopularShopsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<ProductController>();
    final cc = Get.find<CartController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textPri = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSec = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular Shops'),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Obx(() {
        final shops = pc.popularSellers;
        if (shops.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏪', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                Text(
                  'No popular shops yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: textPri,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Popular shops will appear here.',
                  style: TextStyle(fontSize: 13, color: textSec),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => pc.loadProducts(),
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: shops.length,
            itemBuilder: (_, i) {
              final shop = shops[i];
              final products = pc.getProductsBySeller(shop.id).take(5).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.12 : 0.04,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Shop Header ──
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.shop, arguments: shop),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                        child: Row(
                          children: [
                            // Logo
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface2
                                    : const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(12),
                                border: shop.isOfficial == true
                                    ? Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: shop.logoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        shop.logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _avatar(shop.name, isDark),
                                      ),
                                    )
                                  : _avatar(shop.name, isDark),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          shop.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textPri,
                                          ),
                                        ),
                                      ),
                                      if (shop.isOfficial) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified,
                                          size: 15,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  if (shop.description.isNotEmpty)
                                    Text(
                                      shop.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSec,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // "View shop" link
                            Text(
                              'View shop',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Divider ──
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark ? Colors.white10 : const Color(0xFFF0F0F0),
                    ),

                    // ── Product Row ──
                    if (products.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              'Popular Products',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSec,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${products.length} items',
                              style: TextStyle(fontSize: 11, color: textSec),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 270,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: products.length,
                          itemBuilder: (_, pi) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: 170,
                              child: ProductCard(
                                product: products[pi],
                                onTap: () => Get.toNamed(
                                  AppRoutes.productDetail,
                                  arguments: products[pi],
                                ),
                                onAddToCart: () => cc.addToCart(products[pi]),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No products yet',
                            style: TextStyle(fontSize: 13, color: textSec),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

Widget _avatar(String name, bool isDark) {
  final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
  return Center(
    child: Text(
      letter,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? AppTheme.darkTextSecondary : AppTheme.primaryColor,
      ),
    ),
  );
}
