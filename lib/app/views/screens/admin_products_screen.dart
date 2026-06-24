import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_firestore_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/seed_data.dart';
import '../../models/product_model.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';
import '../../routes/app_routes.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _firestoreService = FirebaseFirestoreService();
  final _storageService = FirebaseStorageService();
  List<ProductModel> _products = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _checkingAccess = true;

  late TabController _tabCtrl;
  int _tabIndex = 0;

  // Order search & filter
  final TextEditingController _orderSearchCtrl = TextEditingController();
  String _orderStatusFilter = 'All';
  String _orderSearchQuery = '';

  static const _orderStatuses = [
    'All',
    'Processing',
    'Shipping',
    'Delivered',
    'Cancelled',
  ];

  // Add your admin email(s) here
  static const _adminEmails = [
    // Replace with your Gmail or any admin emails:
    // 'youradmin@gmail.com',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tabIndex = _tabCtrl.index));
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    // If no admin emails configured, allow all logged-in users
    // (for development). Add emails to _adminEmails to restrict.
    if (_adminEmails.isEmpty) {
      setState(() {
        _isAdmin = true;
        _checkingAccess = false;
      });
      _loadProducts();
      return;
    }
    final email = user.email ?? '';
    setState(() {
      _isAdmin = _adminEmails.contains(email.toLowerCase());
      _checkingAccess = false;
    });
    if (!_isAdmin) {
      AppSnack.error('Access Denied', 'Only admins can access this page.');
      Get.back();
      return;
    }
    _loadProducts();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _orderSearchCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() {
        _products = snapshot.docs
            .map((d) => ProductModel.fromFirestore(d))
            .toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE PRODUCT
  // ═══════════════════════════════════════════════════════════════

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Product?'),
        content: Text(
          'Are you sure you want to delete "${product.name}"?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('products').doc(product.id).delete();
      _loadProducts();
      AppSnack.success('Deleted', 'Product removed.');
    } catch (e) {
      AppSnack.error('Error', 'Failed to delete.');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SEED DEMO DATA
  // ═══════════════════════════════════════════════════════════════

  Future<void> _seedDemoData() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Seed Demo Data?'),
        content: const Text(
          'This will add 12 demo products and 3 promo codes to Firestore.\n\n'
          'Existing products (same name) will be skipped.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Seed Data'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    AppSnack.info('Seeding', 'Adding demo products...');
    final result = await SeedDataService.seedAll();
    _loadProducts();
    AppSnack.success(
      'Done!',
      '${result['added']} products added, ${result['skipped']} skipped.\n3 promo codes seeded.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_checkingAccess) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text('Access Denied', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onSelected: (v) {
              if (v == 'seed') _seedDemoData();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'seed',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Seed Demo Data', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _tabIndex == 0 ? _loadProducts : () {},
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Products'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Orders'),
            Tab(icon: Icon(Icons.store_outlined), text: 'Shops'),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addEditProduct);
                if (result == true) _loadProducts();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildProductsTab(isDark),
          _buildOrdersTab(isDark),
          _buildShopsTab(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRODUCTS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildProductsTab(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No products yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap + to add your first product',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9EAA)),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final p = _products[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: isDark
                        ? AppTheme.darkSurface2
                        : Colors.grey.shade100,
                    child: p.images.isNotEmpty
                        ? Image.network(
                            p.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image,
                              size: 28,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(Icons.image, size: 28, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (p.isFlashSale) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.flashSaleColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FLASH',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.flashSaleColor,
                                ),
                              ),
                            ),
                          ],
                          if (p.isFeatured) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Stock: ${p.stock} · ${p.category}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () async {
                        final result = await Get.toNamed(
                          AppRoutes.addEditProduct,
                          arguments: p,
                        );
                        if (result == true) _loadProducts();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.errorColor,
                      ),
                      onPressed: () => _deleteProduct(p),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ORDERS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildOrdersTab(bool isDark) {
    return Column(
      children: [
        // Search & filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _orderSearchCtrl,
                    onChanged: (v) => setState(
                      () => _orderSearchQuery = v.trim().toLowerCase(),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search orders...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _orderSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _orderSearchCtrl.clear();
                                setState(() => _orderSearchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? AppTheme.darkSurface2
                          : const Color(0xFFF1F3F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (v) => setState(() => _orderStatusFilter = v),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkSurface2
                        : const Color(0xFFF1F3F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _orderStatusFilter,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18),
                    ],
                  ),
                ),
                itemBuilder: (_) => _orderStatuses
                    .map(
                      (s) => PopupMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        // Orders list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getAllOrdersStream(),
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 72,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No orders yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              var orders = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ts = data['createdAt'] as Timestamp?;
                final userId = doc.reference.parent.parent?.id ?? 'unknown';
                return {
                  'firestoreId': doc.id,
                  'userId': userId,
                  'status': data['status'] ?? 'Processing',
                  'total': (data['total'] ?? 0).toDouble(),
                  'items': List<Map<String, dynamic>>.from(data['items'] ?? []),
                  'paymentMethod': data['paymentMethod'] ?? 'N/A',
                  'createdAt': ts,
                  'date': ts != null
                      ? '${ts.toDate().day} ${_monthName(ts.toDate().month)} ${ts.toDate().year}'
                      : 'Just now',
                };
              }).toList();

              // Apply filters
              if (_orderStatusFilter != 'All') {
                orders = orders
                    .where((o) => o['status'] == _orderStatusFilter)
                    .toList();
              }
              if (_orderSearchQuery.isNotEmpty) {
                orders = orders.where((o) {
                  final id = (o['firestoreId'] as String).toLowerCase();
                  final uid = (o['userId'] as String).toLowerCase();
                  final pm = (o['paymentMethod'] as String).toLowerCase();
                  final status = (o['status'] as String).toLowerCase();
                  return id.contains(_orderSearchQuery) ||
                      uid.contains(_orderSearchQuery) ||
                      pm.contains(_orderSearchQuery) ||
                      status.contains(_orderSearchQuery);
                }).toList();
              }

              if (orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 56,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No matching orders',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: orders.length,
                itemBuilder: (ctx, i) {
                  final o = orders[i];
                  final status = o['status'] as String;
                  final color = _orderStatusColor(status);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${o['firestoreId'].toString().substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ),
                            if (status != 'Delivered' &&
                                status != 'Cancelled') ...[
                              const SizedBox(width: 6),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onSelected: (newStatus) {
                                  _firestoreService.adminUpdateOrderStatus(
                                    userId: o['userId'] as String,
                                    orderId: o['firestoreId'] as String,
                                    newStatus: newStatus,
                                  );
                                  AppSnack.success(
                                    'Updated',
                                    'Order status changed to $newStatus.',
                                  );
                                },
                                itemBuilder: (_) {
                                  final nextStatuses = _nextStatuses(status);
                                  return nextStatuses.map((s) {
                                    return PopupMenuItem(
                                      value: s,
                                      child: Text(
                                        s,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...(o['items'] as List)
                                .take(3)
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        color: isDark
                                            ? AppTheme.darkSurface2
                                            : const Color(0xFFF1F3F5),
                                        child: Image.network(
                                          item['image'] as String? ?? '',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.image,
                                                size: 20,
                                                color: Colors.grey,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            if ((o['items'] as List).length > 3)
                              Text(
                                '+${(o['items'] as List).length - 3}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '\$${(o['total'] as double).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              o['paymentMethod'] as String? ?? 'N/A',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              o['date'] as String? ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'User: ${(o['userId'] as String).substring(0, 6)}...',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<String> _nextStatuses(String current) {
    const flow = ['Processing', 'Shipping', 'Delivered'];
    final idx = flow.indexOf(current);
    if (idx < 0) return ['Processing'];
    final options = <String>['Cancelled'];
    if (current == 'Processing') options.insert(0, 'Shipping');
    if (current == 'Shipping') options.insert(0, 'Delivered');
    return options;
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppTheme.successColor;
      case 'Shipping':
        return AppTheme.primaryColor;
      case 'Processing':
        return Colors.amber;
      case 'Cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SHOPS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildShopsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('shops').orderBy('name').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        final shops = snap.data?.docs ?? [];

        return Column(
          children: [
            if (_tabIndex == 2)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final result = await Get.toNamed(AppRoutes.addEditShop);
                      if (result == true) {
                        // Refresh shops list
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create Shop'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: shops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏪', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          const Text(
                            'No shops yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Create your first shop above',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9EAA),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: shops.length,
                      itemBuilder: (_, i) {
                        final d = shops[i].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child:
                                    d['logoUrl'] is String &&
                                        (d['logoUrl'] as String).isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          d['logoUrl'] as String,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          d['avatar'] ?? '🏪',
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['name'] ?? 'Shop',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      d['description'] ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (d['isOfficial'] == true)
                                Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Official',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () async {
                                  final result = await Get.toNamed(
                                    AppRoutes.addEditShop,
                                    arguments: {
                                      'docId': shops[i].id,
                                      'data': d,
                                    },
                                  );
                                  if (result == true) {
                                    setState(() {});
                                  }
                                },
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppTheme.errorColor,
                                ),
                                onPressed: () => _deleteShop(shops[i]),
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _deleteShop(DocumentSnapshot doc) async {
    final c = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Shop?'),
        content: const Text(
          'This cannot be undone. Products belonging to this shop will remain but show as "Unknown Shop".',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (c != true) return;
    await _firestore.collection('shops').doc(doc.id).delete();
    AppSnack.success('Deleted', 'Shop removed.');
  }

  String _monthName(int month) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return m[month - 1];
  }
}
