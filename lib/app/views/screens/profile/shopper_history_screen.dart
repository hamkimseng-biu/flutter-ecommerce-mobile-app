import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../models/product_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../routes/app_routes.dart';

class ShopperHistoryScreen extends StatefulWidget {
  const ShopperHistoryScreen({super.key});
  @override
  State<ShopperHistoryScreen> createState() => _ShopperHistoryScreenState();
}

class _ShopperHistoryScreenState extends State<ShopperHistoryScreen> {
  final _firestore = FirebaseFirestoreService();
  final _searchCtl = TextEditingController();
  int _activeTab = 0;
  bool _loading = true;
  List<ProductModel> _viewed = [];
  List<ProductModel> _inCart = [];
  List<ProductModel> _bought = [];
  List<ProductModel> _reviewed = [];

  final _tabs = const ['Viewed', 'In Cart', 'Bought', 'Reviewed'];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final pc = Get.find<ProductController>();

    // Viewed
    final viewedIds = await _firestore.getRecentlyViewed();
    _viewed = viewedIds
        .map((id) => pc.getProductById(id))
        .whereType<ProductModel>()
        .toList();

    // In cart — read from cart stream snapshot
    try {
      final cartSnapshot = await _firestore.getCartItemsOnce();
      final cartIds = cartSnapshot
          .map((item) => item['productId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      _inCart = cartIds
          .map((id) => pc.getProductById(id))
          .whereType<ProductModel>()
          .toList();
    } catch (_) {
      _inCart = [];
    }

    // Bought
    final boughtIds = await _firestore.getBoughtProductIds();
    _bought = boughtIds
        .map((id) => pc.getProductById(id))
        .whereType<ProductModel>()
        .toList();

    // Reviewed
    final reviewedIds = await _firestore.getReviewedProductIds();
    _reviewed = reviewedIds
        .map((id) => pc.getProductById(id))
        .whereType<ProductModel>()
        .toList();

    if (mounted) setState(() => _loading = false);
  }

  List<ProductModel> _currentList() {
    switch (_activeTab) {
      case 0:
        return _viewed;
      case 1:
        return _inCart;
      case 2:
        return _bought;
      case 3:
        return _reviewed;
      default:
        return [];
    }
  }

  List<ProductModel> _filtered() {
    final q = _searchCtl.text.toLowerCase().trim();
    final list = _currentList();
    if (q.isEmpty) return list;
    return list
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search your history...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB0B0B0),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF9E9EAA),
                ),
                suffixIcon: _searchCtl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.darkSurface
                    : const Color(0xFFF1F3F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Tabs
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _activeTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = i),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: (_tabs[i].length * 10.0 + 32),
                      height: 44,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Spacer(),
                          Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: active ? 3 : 0,
                            width: active ? 28 : 0,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildList(bg, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color bg, bool isDark) {
    final items = _filtered();
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_emptyIcon(), style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              _emptyTitle(),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _emptySub(),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => Get.toNamed(AppRoutes.productDetail, arguments: p),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 52,
                height: 52,
                color: isDark ? AppTheme.darkSurface2 : const Color(0xFFF1F3F5),
                child: p.images.isNotEmpty
                    ? Image.network(
                        p.images[0],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          size: 22,
                          color: Colors.grey,
                        ),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        size: 22,
                        color: Colors.grey,
                      ),
              ),
            ),
            title: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              p.category,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9E9EAA)),
            ),
            trailing: Text(
              '\$${p.effectivePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        );
      },
    );
  }

  String _emptyIcon() {
    switch (_activeTab) {
      case 0:
        return '👀';
      case 1:
        return '🛒';
      case 2:
        return '📦';
      case 3:
        return '⭐';
      default:
        return '🛍️';
    }
  }

  String _emptyTitle() {
    switch (_activeTab) {
      case 0:
        return 'Nothing viewed yet';
      case 1:
        return 'Cart is empty';
      case 2:
        return 'No purchases yet';
      case 3:
        return 'No reviews yet';
      default:
        return 'No history';
    }
  }

  String _emptySub() {
    switch (_activeTab) {
      case 0:
        return 'Products you view will appear here.';
      case 1:
        return 'Add items to your cart to see them here.';
      case 2:
        return 'Complete an order to see it here.';
      case 3:
        return 'Products you review will appear here.';
      default:
        return '';
    }
  }
}
