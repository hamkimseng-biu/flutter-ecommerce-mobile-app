// ═══════════════════════════════════════════════════════════════
// COLUMN-BASED HOME SCREEN — pinned search + categories
// Original sliver version backed up to: test_backup/home_screen_sliver.dart
// ═══════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/flash_countdown.dart';
import '../../../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pc = Get.find<ProductController>();
    final cc = Get.find<CartController>();
    final hc = Get.find<HomeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: bg,
        centerTitle: false,
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tiny Chicken',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: () => Get.toNamed(AppRoutes.search),
            splashRadius: 20,
            visualDensity: VisualDensity.compact,
          ),
          Obx(
            () => Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 22),
                  onPressed: () => Get.toNamed(AppRoutes.cart),
                  splashRadius: 20,
                  visualDensity: VisualDensity.compact,
                ),
                if (cc.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cc.itemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ═══ PINNED: Search bar ═══
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.search),
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkInputFill
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search in Tiny Chicken',
                    style: TextStyle(
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : const Color(0xFFAAAAAA),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ═══ PINNED: Category chips ═══
          Obx(() {
            if (pc.categories.isEmpty) return const SizedBox(height: 8);
            final sel = pc.selectedCategoryIndex.value;
            return SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: pc.categories.length,
                itemBuilder: (ctx, i) {
                  final cat = pc.categories[i];
                  final active = sel == i;
                  return GestureDetector(
                    onTap: () => pc.selectCategory(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : (isDark
                                  ? AppTheme.darkSurface2
                                  : const Color(0xFFF5F6FA)),
                        borderRadius: BorderRadius.circular(20),
                        border: active
                            ? Border.all(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat.icon,
                            style: TextStyle(fontSize: active ? 17 : 15),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: active
                                    ? AppTheme.primaryColor
                                    : (isDark
                                          ? AppTheme.darkTextSecondary
                                          : const Color(0xFF666666)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }),

          // ═══ SCROLLABLE: rest of page ═══
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => pc.loadProducts(),
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                controller: hc.scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ── Promo Carousel ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _PromoCarousel(),
                    ),

                    const SizedBox(height: 24),

                    // ── Flash Deals ──
                    Obx(() {
                      final items = pc.filteredFlashSale;
                      if (items.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.flashSaleColor,
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
                                        'Flash Deals',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFlashCountdown(items),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.flashSales),
                                  child: const Text(
                                    'More',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Color(0xFF999999),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 270,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) => Padding(
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
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Recently Viewed ──
                    Obx(() {
                      final _ = pc.selectedCategoryIndex.value;
                      return _RecentlyViewedSection(
                        pc: pc,
                        cc: cc,
                        isDark: isDark,
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Popular Shops ──
                    Obx(() {
                      final sellers = pc.popularSellers;
                      if (sellers.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Popular Shops',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.popularShops),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'See All',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 14,
                                        color: Color(0xFF999999),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: sellers.length,
                              itemBuilder: (ctx, i) {
                                final s = sellers[i];
                                return GestureDetector(
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.shop, arguments: s),
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 10),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppTheme.darkSurface2
                                          : const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: s.isOfficial
                                            ? AppTheme.primaryColor.withValues(
                                                alpha: 0.35,
                                              )
                                            : (isDark
                                                  ? Colors.white12
                                                  : const Color(0xFFE0E0E0)),
                                        width: s.isOfficial ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.06,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: s.logoUrl.isNotEmpty
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(
                                                    s.logoUrl,
                                                    fit: BoxFit.cover,
                                                    width: 44,
                                                    height: 44,
                                                  ),
                                                )
                                              : Center(
                                                  child: Text(
                                                    s.avatar,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppTheme.darkTextPrimary
                                                : AppTheme.lightTextPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Guess You Like ──
                    Obx(() {
                      if (pc.isLoading.value)
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Guess You Like',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _shimmerGrid(),
                            ],
                          ),
                        );
                      final items = pc.filteredProducts;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 3,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Guess You Like',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.68,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: items.length,
                              itemBuilder: (ctx, i) => ProductCard(
                                product: items[i],
                                onTap: () => Get.toNamed(
                                  AppRoutes.productDetail,
                                  arguments: items[i],
                                ),
                                onAddToCart: () => cc.addToCart(items[i]),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashCountdown(List<ProductModel> items) {
    DateTime? endTime;
    for (final p in items) {
      if (p.saleEndsAt != null) {
        if (endTime == null || p.saleEndsAt!.isBefore(endTime))
          endTime = p.saleEndsAt;
      }
    }
    endTime ??= DateTime.now().add(const Duration(hours: 24));
    return FlashCountdown(endTime: endTime);
  }

  Widget _shimmerGrid() => GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.68,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: 6,
    itemBuilder: (_, __) => Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// RECENTLY VIEWED SECTION
// ═══════════════════════════════════════════════════════════════
class _RecentlyViewedSection extends StatefulWidget {
  final ProductController pc;
  final CartController cc;
  final bool isDark;
  const _RecentlyViewedSection({
    required this.pc,
    required this.cc,
    required this.isDark,
  });
  @override
  State<_RecentlyViewedSection> createState() => _RecentlyViewedSectionState();
}

class _RecentlyViewedSectionState extends State<_RecentlyViewedSection> {
  final _firestoreService = FirebaseFirestoreService();
  List<ProductModel> _recentProducts = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final ids = await _firestoreService.getRecentlyViewed();
    if (ids.isEmpty) {
      setState(() => _loaded = true);
      return;
    }
    final products = <ProductModel>[];
    for (final id in ids) {
      final p = widget.pc.getProductById(id);
      if (p != null) products.add(p);
    }
    if (mounted)
      setState(() {
        _recentProducts = products;
        _loaded = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _recentProducts.isEmpty) return const SizedBox.shrink();
    final selIdx = widget.pc.selectedCategoryIndex.value;
    List<ProductModel> filtered;
    if (selIdx == 0 || widget.pc.categories.isEmpty) {
      filtered = _recentProducts;
    } else {
      final cat = widget.pc.categories[selIdx].name;
      filtered = _recentProducts
          .where((p) => p.category.toLowerCase() == cat.toLowerCase())
          .toList();
    }
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              const Text(
                'Recently Viewed',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                width: 170,
                child: ProductCard(
                  product: filtered[i],
                  onTap: () => Get.toNamed(
                    AppRoutes.productDetail,
                    arguments: filtered[i],
                  ),
                  onAddToCart: () => widget.cc.addToCart(filtered[i]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Promo Carousel (auto-sliding) ──
class _PromoCarousel extends StatefulWidget {
  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final PageController _pageCtrl = PageController();
  late final List<_PromoSlide> _slides;
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _slides = const [
      _PromoSlide(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        tag: 'NEW SEASON',
        title: 'Summer Collection',
        subtitle: 'Up to 50% off',
        emoji: '🛍️',
      ),
      _PromoSlide(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B83FF)],
        ),
        tag: 'FLASH SALE',
        title: 'Limited Deals',
        subtitle: 'Grab them before gone!',
        emoji: '⚡',
      ),
      _PromoSlide(
        gradient: LinearGradient(
          colors: [Color(0xFF00BFA6), Color(0xFF1DE9B6)],
        ),
        tag: 'FREE SHIPPING',
        title: 'Tiny Chicken Official',
        subtitle: 'No minimum order',
        emoji: '🐔',
      ),
    ];
    _startAutoSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients) return;
      final next = (_current + 1) % _slides.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => _slides[i].build(context),
          ),
        ),
        const SizedBox(height: 8),
        // dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _current;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: active
                    ? _slides[_current].accentColor
                    : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PromoSlide {
  final Gradient gradient;
  final String tag;
  final String title;
  final String subtitle;
  final String emoji;

  const _PromoSlide({
    required this.gradient,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.emoji,
  });

  Color get accentColor {
    final g = gradient as LinearGradient;
    return g.colors.first;
  }

  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 44)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 130, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
