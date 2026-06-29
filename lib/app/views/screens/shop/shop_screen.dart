import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/seller_model.dart';
import '../../../models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/cart_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../widgets/product_card.dart';
import '../../../routes/app_routes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ProductController pc = Get.find<ProductController>();
  final CartController cc = Get.find<CartController>();
  final FirebaseFirestoreService _firestore = FirebaseFirestoreService();
  final RxBool isFollowing = false.obs;
  String _sortBy = 'default'; // default, price-asc, price-desc, rating, newest
  String? _filterSize;
  String? _filterColor;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is SellerModel) {
      _sellerId = args.id;
    } else if (args is String) {
      _sellerId = args;
    } else if (args is Map) {
      _sellerId = args['id'] ?? args['sellerId'] ?? '';
    }
    _checkFollowStatus(_sellerId);
  }

  String _sellerId = '';

  Future<void> _checkFollowStatus(String shopId) async {
    final following = await _firestore.isShopFollowed(shopId);
    isFollowing.value = following;
  }

  List<ProductModel> _sorted(List<ProductModel> products) {
    var list = List<ProductModel>.from(products);
    if (_filterSize != null)
      list = list.where((p) => p.sizes.contains(_filterSize)).toList();
    if (_filterColor != null)
      list = list.where((p) => p.colors.contains(_filterColor)).toList();
    switch (_sortBy) {
      case 'price-asc':
        list.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price-desc':
        list.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'newest':
        break; // would need createdAt field
    }
    return list;
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final isSheetDark = Theme.of(context).brightness == Brightness.dark;
        final sheetText = isSheetDark ? Colors.white : Colors.black87;
        final sheetSubText = isSheetDark ? Colors.white70 : Colors.black54;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: sheetText,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text('Default', style: TextStyle(color: sheetText)),
                leading: Icon(
                  Icons.sort,
                  color: _sortBy == 'default'
                      ? AppTheme.primaryColor
                      : sheetSubText,
                ),
                onTap: () {
                  setState(() => _sortBy = 'default');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  'Price: Low to High',
                  style: TextStyle(color: sheetText),
                ),
                leading: Icon(
                  Icons.trending_up,
                  color: _sortBy == 'price-asc'
                      ? AppTheme.primaryColor
                      : sheetSubText,
                ),
                onTap: () {
                  setState(() => _sortBy = 'price-asc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  'Price: High to Low',
                  style: TextStyle(color: sheetText),
                ),
                leading: Icon(
                  Icons.trending_down,
                  color: _sortBy == 'price-desc'
                      ? AppTheme.primaryColor
                      : sheetSubText,
                ),
                onTap: () {
                  setState(() => _sortBy = 'price-desc');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Top Rated', style: TextStyle(color: sheetText)),
                leading: Icon(
                  Icons.star,
                  color: _sortBy == 'rating'
                      ? AppTheme.primaryColor
                      : sheetSubText,
                ),
                onTap: () {
                  setState(() => _sortBy = 'rating');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String fmt(int c) =>
        c >= 1000 ? '${(c / 1000).toStringAsFixed(1)}k' : c.toString();
    final products = pc.getProductsBySeller(_sellerId);
    final sorted = _sorted(products);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;

    Widget sortChip(BuildContext ctx, bool dark) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: _showSortSheet,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: dark ? AppTheme.darkSurface2 : const Color(0xFFF1F3F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: dark ? Colors.white24 : const Color(0xFFD0D0D6),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort_rounded, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 4),
              Text(
                'Sort & Filter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Obx(() {
      final seller = pc.getSellerById(_sellerId);
      final productCount = pc.getSellerProductCount(_sellerId);
      if (seller == null)
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      final sellerName = seller.name;
      final sellerBanner = seller.banner;
      final sellerLogo = seller.logoUrl;
      final sellerAvatar = seller.avatar;
      final sellerOfficial = seller.isOfficial;
      final sellerFollowers = seller.followerCount;
      final sellerRating = seller.rating;
      final sellerDesc = seller.description;

      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async => pc.loadProducts(),
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      sellerBanner.isNotEmpty
                          ? Image.network(
                              sellerBanner,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            )
                          : Container(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 70,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: sellerLogo.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Image.network(
                                        sellerLogo,
                                        width: 54,
                                        height: 54,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Text(
                                          sellerAvatar,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      sellerAvatar,
                                      style: const TextStyle(fontSize: 30),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          sellerName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (sellerOfficial) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.verified,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${fmt(sellerFollowers)} followers · ${productCount} products',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Obx(
                              () => ElevatedButton(
                                onPressed: () async {
                                  await _firestore.toggleFollowShop(_sellerId);
                                  isFollowing.toggle();
                                  AppSnack.success(
                                    isFollowing.value
                                        ? 'Following'
                                        : 'Unfollowed',
                                    isFollowing.value
                                        ? 'You are now following ${sellerName}'
                                        : 'You unfollowed ${sellerName}',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(72, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  backgroundColor: isFollowing.value
                                      ? AppTheme.primaryColor
                                      : Colors.white,
                                  foregroundColor: isFollowing.value
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: Text(
                                  isFollowing.value ? 'Following' : 'Follow',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shop description row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppTheme.secondaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${sellerRating}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sellerDesc,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : const Color(0xFF666666),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Stats + sort row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${sorted.length} Products',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          sortChip(context, isDark),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: products.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No products yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => ProductCard(
                            product: sorted[i],
                            onTap: () => Get.toNamed(
                              AppRoutes.productDetail,
                              arguments: sorted[i],
                            ),
                            onAddToCart: () => cc.addToCart(sorted[i]),
                          ),
                          childCount: sorted.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
