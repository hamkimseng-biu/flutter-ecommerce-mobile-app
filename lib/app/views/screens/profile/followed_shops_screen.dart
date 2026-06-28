import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/product_controller.dart';
import '../../../models/seller_model.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/app_dialog.dart';
import '../../../routes/app_routes.dart';

class FollowedShopsScreen extends StatefulWidget {
  const FollowedShopsScreen({super.key});
  @override
  State<FollowedShopsScreen> createState() => _FollowedShopsScreenState();
}

class _FollowedShopsScreenState extends State<FollowedShopsScreen> {
  final _firestore = FirebaseFirestoreService();
  final _searchCtl = TextEditingController();
  bool _loading = true;
  List<SellerModel> _shops = [];

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _loading = true);
    final pc = Get.find<ProductController>();
    final followedIds = await _firestore.getFollowedShopIds();
    final shops = followedIds
        .map((id) => pc.getSellerById(id))
        .whereType<SellerModel>()
        .toList();
    if (mounted) {
      setState(() {
        _shops = shops;
        _loading = false;
      });
    }
  }

  List<SellerModel> get _filtered {
    final q = _searchCtl.text.toLowerCase().trim();
    if (q.isEmpty) return _shops;
    return _shops
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              (s.description.toLowerCase().contains(q)),
        )
        .toList();
  }

  Future<void> _unfollow(SellerModel shop) async {
    final confirm = await AppDialog.confirm(
      title: 'Unfollow Shop?',
      message: 'Stop following ${shop.name}?',
      confirmLabel: 'Unfollow',
      confirmColor: AppTheme.errorColor,
    );
    if (confirm == true) {
      await _firestore.toggleFollowShop(shop.id);
      AppSnack.info('Unfollowed', 'You unfollowed ${shop.name}.');
      _loadShops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Followed Shops'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadShops,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search shops...',
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
    final shops = _filtered;
    if (shops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏪', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 14),
            Text(
              _searchCtl.text.isNotEmpty
                  ? 'No matching shops'
                  : 'No followed shops',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              _searchCtl.text.isNotEmpty
                  ? 'Try a different search.'
                  : 'Follow shops to see them here.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
            ),
            if (_searchCtl.text.isEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Get.offAllNamed(AppRoutes.main),
                icon: const Icon(Icons.explore_outlined, size: 16),
                label: const Text(
                  'Discover Shops',
                  style: TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: shops.length,
      itemBuilder: (_, i) {
        final shop = shops[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => Get.toNamed(AppRoutes.shop, arguments: shop),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: isDark
                  ? AppTheme.darkSurface2
                  : const Color(0xFFF1F3F5),
              backgroundImage: shop.logoUrl.isNotEmpty
                  ? NetworkImage(shop.logoUrl)
                  : null,
              child: shop.logoUrl.isEmpty
                  ? Text(
                      shop.name.isNotEmpty ? shop.name[0] : '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    shop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (shop.isOfficial) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              shop.description.isNotEmpty ? shop.description : 'Official store',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9EAA)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              color: AppTheme.errorColor,
              tooltip: 'Unfollow',
              onPressed: () => _unfollow(shop),
            ),
          ),
        );
      },
    );
  }
}
