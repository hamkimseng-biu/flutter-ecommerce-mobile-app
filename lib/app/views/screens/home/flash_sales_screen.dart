import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../models/product_model.dart';
import '../../../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/flash_countdown.dart';
import '../../../routes/app_routes.dart';

class FlashSalesScreen extends StatefulWidget {
  const FlashSalesScreen({super.key});
  @override
  State<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends State<FlashSalesScreen> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final collapsed = _scrollCtrl.hasClients && _scrollCtrl.offset > 140;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

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
      body: Obx(() {
        final products = pc.flashSaleProducts;
        if (products.isEmpty) {
          return CustomScrollView(
            slivers: [
              _heroBanner(products, isDark, false),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 12),
                      Text(
                        'No flash sales right now',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: textPri,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check back later for deals!',
                        style: TextStyle(fontSize: 13, color: textSec),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Compute earliest end time for countdown
        DateTime? endTime;
        for (final p in products) {
          if (p.saleEndsAt != null) {
            if (endTime == null || p.saleEndsAt!.isBefore(endTime)) {
              endTime = p.saleEndsAt;
            }
          }
        }
        endTime ??= DateTime.now().add(const Duration(hours: 24));

        // Group by seller
        final grouped = <String, List<ProductModel>>{};
        for (final p in products) {
          final key = p.sellerId.isNotEmpty ? p.sellerId : 'unknown';
          grouped.putIfAbsent(key, () => []).add(p);
        }

        return RefreshIndicator(
          onRefresh: () async => pc.loadProducts(),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            controller: _scrollCtrl,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ── Hero Banner ──
              _heroBanner(products, isDark, _collapsed),

              // ── Seller Groups ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                sliver: SliverList.separated(
                  itemCount: grouped.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (_, gi) {
                    final sellerId = grouped.keys.elementAt(gi);
                    final items = grouped[sellerId]!;
                    final seller = pc.getSellerById(sellerId);

                    return Container(
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
                          // Seller header
                          GestureDetector(
                            onTap: () {
                              if (seller != null) {
                                Get.toNamed(AppRoutes.shop, arguments: seller);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                              child: Row(
                                children: [
                                  // Flash badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.flashSaleColor,
                                          Color(0xFFFF6B35),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.bolt,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        Text(
                                          'FLASH',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Seller logo
                                  if (seller != null) ...[
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppTheme.darkSurface2
                                            : const Color(0xFFF1F3F5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: seller.isOfficial
                                            ? Border.all(
                                                color: AppTheme.primaryColor,
                                                width: 1.5,
                                              )
                                            : null,
                                      ),
                                      child: seller.logoUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                seller.logoUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    _sellerAvatar(
                                                      seller.name,
                                                      isDark,
                                                    ),
                                              ),
                                            )
                                          : _sellerAvatar(seller.name, isDark),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // Seller name
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            seller?.name ??
                                                items.first.sellerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textPri,
                                            ),
                                          ),
                                        ),
                                        if (seller?.isOfficial == true) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${items.length} deal${items.length > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: textSec,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: textSec,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFF0F0F0),
                          ),
                          const SizedBox(height: 8),
                          // Product row
                          SizedBox(
                            height: 270,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemCount: items.length,
                              itemBuilder: (_, i) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: SizedBox(
                                  width: 170,
                                  child: ProductCard(
                                    product: items[i],
                                    onTap: () => Get.toNamed(
                                      AppRoutes.productDetail,
                                      arguments: items[i],
                                    ),
                                    onAddToCart: () => cc.addToCart(items[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _heroBanner(List<ProductModel> products, bool isDark, bool collapsed) {
    // Compute earliest end time
    DateTime? endTime;
    for (final p in products) {
      if (p.saleEndsAt != null) {
        if (endTime == null || p.saleEndsAt!.isBefore(endTime)) {
          endTime = p.saleEndsAt;
        }
      }
    }
    endTime ??= DateTime.now().add(const Duration(hours: 24));

    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      automaticallyImplyLeading: false,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: collapsed
                ? (isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.lightTextPrimary)
                : Colors.white,
          ),
          onPressed: () => Get.back(),
          splashRadius: 20,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.flashSaleColor, Color(0xFFFF6B35)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Bolt + Title ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Flash Sales',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Grab them before they\'re gone!',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Ends in ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                      FlashCountdown(endTime: endTime),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sellerAvatar(String name, bool isDark) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppTheme.darkTextSecondary : AppTheme.primaryColor,
        ),
      ),
    );
  }
}
