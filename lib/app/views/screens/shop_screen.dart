import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/seller_model.dart';
import '../../models/product_model.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../../config/app_theme.dart';
import '../widgets/product_card.dart';
import '../../routes/app_routes.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ProductController pc = Get.find<ProductController>();
  final CartController cc = Get.find<CartController>();
  final RxBool isFollowing = false.obs;
  String _sortBy = 'default'; // default, price-asc, price-desc, rating, newest
  String? _filterSize;
  String? _filterColor;

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
      builder: (_) => SafeArea(
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
            const Text(
              'Sort & Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Default'),
              leading: Icon(
                Icons.sort,
                color: _sortBy == 'default'
                    ? AppTheme.primaryColor
                    : Colors.grey,
              ),
              onTap: () {
                setState(() => _sortBy = 'default');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Price: Low to High'),
              leading: Icon(
                Icons.trending_up,
                color: _sortBy == 'price-asc'
                    ? AppTheme.primaryColor
                    : Colors.grey,
              ),
              onTap: () {
                setState(() => _sortBy = 'price-asc');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              leading: Icon(
                Icons.trending_down,
                color: _sortBy == 'price-desc'
                    ? AppTheme.primaryColor
                    : Colors.grey,
              ),
              onTap: () {
                setState(() => _sortBy = 'price-desc');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Top Rated'),
              leading: Icon(
                Icons.star,
                color: _sortBy == 'rating'
                    ? AppTheme.primaryColor
                    : Colors.grey,
              ),
              onTap: () {
                setState(() => _sortBy = 'rating');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Size: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            ['S', 'M', 'L', 'XL']
                                .map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: FilterChip(
                                      label: Text(s),
                                      selected: _filterSize == s,
                                      onSelected: (v) => setState(
                                        () => _filterSize = v ? s : null,
                                      ),
                                      selectedColor: AppTheme.primaryColor,
                                      checkmarkColor: Colors.white,
                                    ),
                                  ),
                                )
                                .toList()
                              ..insert(
                                0,
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    label: const Text('All'),
                                    selected: _filterSize == null,
                                    onSelected: (_) =>
                                        setState(() => _filterSize = null),
                                    selectedColor: AppTheme.primaryColor,
                                    checkmarkColor: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seller = Get.arguments as SellerModel;
    final products = pc.getProductsBySeller(seller.id);
    final sorted = _sorted(products);

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
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    seller.banner.isNotEmpty
                        ? Image.network(
                            seller.banner,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                            child: Center(
                              child: Text(
                                seller.avatar,
                                style: const TextStyle(fontSize: 30),
                              ),
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
                                        seller.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (seller.isOfficial) ...[
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
                                  '${_fmt(seller.followerCount)} followers · ${seller.productCount} products',
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
                              onPressed: () => isFollowing.toggle(),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          '${seller.rating}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            seller.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${sorted.length} Products',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
  }

  String _fmt(int c) =>
      c >= 1000 ? '${(c / 1000).toStringAsFixed(1)}k' : c.toString();
}
