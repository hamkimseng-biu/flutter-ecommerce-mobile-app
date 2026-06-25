import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../services/firebase_storage_service.dart';
import '../../../services/seed_data.dart';
import '../../../models/product_model.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/app_dialog.dart';
import '../../../routes/app_routes.dart';

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
  List<String> _categoryNames = [];
  bool _loading = true;
  bool _isAdmin = false;
  bool _checkingAccess = true;

  late TabController _tabCtrl;
  int _tabIndex = 0;

  // Cached orders stream — persists across rebuilds for real-time updates
  Stream<QuerySnapshot>? _ordersStream;

  // Pagination — per-tab display limits (resets on tab switch)
  int _productLimit = 20;
  int _orderLimit = 20;
  int _shopLimit = 20;
  int _catLimit = 20;
  static const _pageSize = 20;

  void _loadMoreCurrentTab() {
    setState(() {
      switch (_tabIndex) {
        case 0:
          _productLimit += _pageSize;
          break;
        case 1:
          _orderLimit += _pageSize;
          break;
        case 2:
          _shopLimit += _pageSize;
          break;
        case 3:
          _catLimit += _pageSize;
          break;
      }
    });
  }

  // Order search & filter
  final TextEditingController _orderSearchCtrl = TextEditingController();
  String _orderStatusFilter = 'All';
  String _orderSearchQuery = '';

  static const _orderStatuses = [
    'All',
    'Processing',
    'Shipping',
    'On Delivery',
    'Delivered',
    'Cancelled',
  ];

  // Firestore doc: settings/admins → field 'emails' (List<String>)
  // Fallback hardcoded list below also works.
  static const _adminEmails = [
    // Add admin emails here (checked in addition to Firestore):
    // 'admin@example.com',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tabIndex = _tabCtrl.index));
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    final email = (user.email ?? '').toLowerCase();

    // 1) Check hardcoded list first
    if (_adminEmails.any((e) => e.toLowerCase() == email)) {
      setState(() {
        _isAdmin = true;
        _checkingAccess = false;
      });
      _loadProducts();
      return;
    }

    // 2) Check Firestore settings/admins doc
    try {
      final doc = await _firestore.collection('settings').doc('admins').get();
      if (doc.exists) {
        final data = doc.data()!;
        // Support both 'emails' (array) and 'email' (single string)
        final emails = <String>[
          if (data['email'] is String) data['email'] as String,
          ...?(data['emails'] is List
              ? List<String>.from(data['emails'])
              : null),
        ];
        if (emails.any((e) => e.toLowerCase() == email)) {
          setState(() {
            _isAdmin = true;
            _checkingAccess = false;
          });
          _loadProducts();
          return;
        }
      }
    } catch (_) {
      // Firestore check failed — fall through to deny
    }

    // Deny access
    setState(() {
      _isAdmin = false;
      _checkingAccess = false;
    });
    AppSnack.error('Access Denied', 'Only admins can access this page.');
    Get.back();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _orderSearchCtrl.dispose();
    _productSearchCtrl.dispose();
    _shopSearchCtrl.dispose();
    _catSearchCtrl.dispose();
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
    // Also load category names for filter dropdown
    _loadCategoryNames();
  }

  Future<void> _loadCategoryNames() async {
    try {
      final snap = await _firestore
          .collection('categories')
          .orderBy('order')
          .get();
      _categoryNames = snap.docs
          .map((d) => (d.data()['name'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } catch (_) {
      _categoryNames = [];
    }
  }

  String _seedLabel() {
    switch (_tabIndex) {
      case 0:
        return 'Seed Products';
      case 2:
        return 'Seed Shops';
      case 3:
        return 'Seed Categories';
      default:
        return 'Seed Data';
    }
  }

  Future<void> _seedCurrentTab() async {
    String? msg;
    try {
      switch (_tabIndex) {
        case 0:
          final r = await SeedDataService.seedProducts();
          final added = r['added'] ?? 0;
          final skipped = r['skipped'] ?? 0;
          if (added == 0 && skipped > 0) {
            AppSnack.info(
              'Already Seeded',
              '$skipped product(s) already exist.',
            );
          } else {
            msg = '$added added, $skipped skipped.';
          }
          _loadProducts();
          break;
        case 2:
          await SeedDataService.seedShops();
          setState(() {});
          msg = '6 shops seeded (skipped if exist).';
          break;
        case 3:
          await SeedDataService.seedCategories();
          _loadCategoryNames();
          setState(() {});
          msg = '10 categories seeded (skipped if exist).';
          break;
      }
      if (msg != null) AppSnack.success('Seeded', msg);
    } catch (_) {
      AppSnack.error('Error', 'Failed to seed data.');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DELETE PRODUCT
  // ═══════════════════════════════════════════════════════════════

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await AppDialog.deleteConfirm(
      title: 'Delete Product?',
      message: 'Are you sure you want to delete "${product.name}"?',
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
    final confirm = await AppDialog.confirm(
      title: 'Seed All Demo Data?',
      message:
          'Seeds products, shops, categories & promo codes.\n\nExisting items (same name) will be skipped.',
      confirmLabel: 'Seed All',
    );
    if (confirm != true) return;

    AppSnack.info('Seeding', 'Adding demo data...');
    final result = await SeedDataService.seedAll();
    final added = result['added'] ?? 0;
    final skipped = result['skipped'] ?? 0;
    _loadProducts();
    _loadCategoryNames();
    if (added == 0 && skipped > 0) {
      AppSnack.info('Already Seeded', '$skipped item(s) already exist.');
    } else {
      AppSnack.success('Done!', '$added added, $skipped skipped.');
    }
  }

  Future<void> _showShippingFeeDialog() async {
    final ctrl = TextEditingController();
    // Load current shipping fee from Firestore
    final doc = await _firestore.collection('settings').doc('shipping').get();
    if (doc.exists) {
      ctrl.text = (doc.data()?['fee'] ?? 5.99).toString();
    } else {
      ctrl.text = '5.99';
    }

    final result = await AppDialog.input(
      title: 'Set Shipping Fee',
      label: 'Shipping Fee (\$)',
      hint: '5.99',
      actionLabel: 'Save',
      initialValue: ctrl.text,
      keyboardType: TextInputType.number,
      prefixIcon: Icons.local_shipping_outlined,
    );
    if (result != null && result.isNotEmpty) {
      final fee = double.tryParse(result) ?? 5.99;
      await _firestore.collection('settings').doc('shipping').set({
        'fee': fee,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppSnack.success(
        'Updated',
        'Shipping fee set to \$${fee.toStringAsFixed(2)}',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ADMINS TAB
  // ═══════════════════════════════════════════════════════════════

  Widget _buildAdminsTab(bool isDark) {
    return StatefulBuilder(
      builder: (ctx, setD) {
        return FutureBuilder<List<String>>(
          future: _loadAdminEmails(),
          builder: (ctx, snap) {
            final emails = snap.data ?? [];
            final addCtrl = TextEditingController();

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin Emails',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Only these users can access this panel.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${emails.length}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Add new admin
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addCtrl,
                          decoration: InputDecoration(
                            hintText: 'email@example.com',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.darkSurface2
                                : const Color(0xFFF1F3F5),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: () async {
                          final newEmail = addCtrl.text.trim().toLowerCase();
                          if (newEmail.isEmpty || !newEmail.contains('@')) {
                            AppSnack.error('Invalid', 'Enter a valid email.');
                            return;
                          }
                          if (emails.contains(newEmail)) {
                            AppSnack.info('Exists', 'Already an admin.');
                            return;
                          }
                          emails.add(newEmail);
                          await _saveAdminEmails(emails);
                          addCtrl.clear();
                          setD(() {});
                          AppSnack.success(
                            'Added',
                            '$newEmail is now an admin.',
                          );
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Admin list
                  Expanded(
                    child: emails.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_add_disabled,
                                  size: 56,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No admins configured',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add an email above to grant access.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9E9EAA),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: emails.length,
                            itemBuilder: (_, i) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.person_outline,
                                      size: 20,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      emails[i],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () async {
                                      emails.removeAt(i);
                                      await _saveAdminEmails(emails);
                                      setD(() {});
                                      AppSnack.info(
                                        'Removed',
                                        '${emails[i]} removed.',
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<String>> _loadAdminEmails() async {
    try {
      final doc = await _firestore.collection('settings').doc('admins').get();
      if (doc.exists) {
        final data = doc.data()!;
        return [
          if (data['email'] is String) data['email'] as String,
          ...?(data['emails'] is List
              ? List<String>.from(data['emails'])
              : null),
        ];
      }
    } catch (_) {}
    return [];
  }

  // ── Manage Admin Emails (dialog, now replaced by tab) ──
  Future<void> _saveAdminEmails(List<String> emails) async {
    // Normalize: store as 'emails' array (modern format)
    await _firestore.collection('settings').doc('admins').set({
      'emails': emails,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
              if (v == 'seedTab') _seedCurrentTab();
              if (v == 'seedAll') _seedDemoData();
              if (v == 'shipping') _showShippingFeeDialog();
            },
            itemBuilder: (_) => [
              if (_tabIndex != 1) // No seed for Orders
                PopupMenuItem(
                  value: 'seedTab',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_download_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(_seedLabel(), style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'seedAll',
                child: Row(
                  children: [
                    Icon(Icons.cloud_download_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Seed All Data', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'shipping',
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Set Shipping Fee', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabIndex == 0) _loadProducts();
              if (_tabIndex == 1) {
                _ordersStream = null;
                setState(() {});
              }
              setState(() {});
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(
              icon: Icon(Icons.inventory_2_outlined, size: 20),
              text: 'Products',
            ),
            Tab(
              icon: Icon(Icons.receipt_long_outlined, size: 20),
              text: 'Orders',
            ),
            Tab(icon: Icon(Icons.store_outlined, size: 20), text: 'Shops'),
            Tab(
              icon: Icon(Icons.category_outlined, size: 20),
              text: 'Categories',
            ),
            Tab(
              icon: Icon(Icons.admin_panel_settings_outlined, size: 20),
              text: 'Admins',
            ),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addEditProduct);
                if (result is String) {
                  AppSnack.success(
                    result == 'updated' ? 'Updated' : 'Added',
                    result == 'updated'
                        ? 'Product updated successfully.'
                        : 'Product added to shop.',
                  );
                  _loadProducts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : _tabIndex == 2
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Get.toNamed(AppRoutes.addEditShop);
                if (result is String) {
                  AppSnack.success(
                    result == 'updated' ? 'Updated' : 'Created',
                    result == 'updated' ? 'Shop updated.' : 'Shop created.',
                  );
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Shop'),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            )
          : _tabIndex == 3
          ? FloatingActionButton.extended(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
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
          _buildCategoriesTab(isDark),
          _buildAdminsTab(isDark),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PRODUCTS TAB
  // ═══════════════════════════════════════════════════════════════

  // Product search state
  final TextEditingController _productSearchCtrl = TextEditingController();
  String _productSearchQuery = '';
  String _productFilterCategory = 'All';

  Widget _buildProductsTab(bool isDark) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    // Build filtered list
    final filtered = _products.where((p) {
      if (_productFilterCategory != 'All' &&
          p.category != _productFilterCategory)
        return false;
      if (_productSearchQuery.isNotEmpty) {
        final q = _productSearchQuery;
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.sellerName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    // Load categories from Firestore for filter (not from product data)
    final cats = <String>{'All'};
    if (_categoryNames.isNotEmpty) {
      cats.addAll(_categoryNames);
    } else {
      // Fallback: use product categories
      for (final p in _products) {
        cats.add(p.category);
      }
    }

    return Column(
      children: [
        // Search & filter
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _productSearchCtrl,
                    onChanged: (v) => setState(
                      () => _productSearchQuery = v.trim().toLowerCase(),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _productSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _productSearchCtrl.clear();
                                setState(() => _productSearchQuery = '');
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
              if (cats.length > 1) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) => setState(() => _productFilterCategory = v),
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
                          _productFilterCategory,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 18),
                      ],
                    ),
                  ),
                  itemBuilder: (_) => cats
                      .map(
                        (c) => PopupMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        // Product list
        Expanded(
          child: _products.isEmpty
              ? Center(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap + to add your first product',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9E9EAA),
                        ),
                      ),
                    ],
                  ),
                )
              : filtered.isEmpty
              ? Center(
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
                        'No matching products',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount:
                        filtered.take(_productLimit).length +
                        (filtered.length > _productLimit ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _productLimit)
                        return _loadMoreButton(filtered.length, _productLimit);
                      final p = filtered.elementAt(i);
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
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.image,
                                              size: 28,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.image,
                                        size: 28,
                                        color: Colors.grey,
                                      ),
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
                                            color: AppTheme.flashSaleColor
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    final result = await Get.toNamed(
                                      AppRoutes.addEditProduct,
                                      arguments: p,
                                    );
                                    if (result is String) {
                                      AppSnack.success(
                                        result == 'updated'
                                            ? 'Updated'
                                            : 'Added',
                                        result == 'updated'
                                            ? 'Product updated successfully.'
                                            : 'Product added to shop.',
                                      );
                                      _loadProducts();
                                    }
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
                ),
        ),
      ],
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
            stream: _ordersStream ??= _firestore
                .collectionGroup('orders')
                .snapshots()
                .handleError((_) => <QueryDocumentSnapshot<Object?>>[]),
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
                // Extract userId from doc path: users/{uid}/orders/{orderId}
                final pathSegments = doc.reference.path.split('/');
                final userId =
                    pathSegments.length >= 3 &&
                        pathSegments[pathSegments.length - 3] == 'users'
                    ? pathSegments[pathSegments.length - 2]
                    : (data['userId'] as String?) ?? 'unknown';
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

              // Sort client-side (newest first)
              orders.sort((a, b) {
                final ta = a['createdAt'] as Timestamp?;
                final tb = b['createdAt'] as Timestamp?;
                if (ta == null && tb == null) return 0;
                if (ta == null) return 1;
                if (tb == null) return -1;
                return tb.compareTo(ta);
              });

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

              // Group orders by user, sort groups by newest order
              final grouped = <String, List<Map<String, dynamic>>>{};
              for (final o in orders) {
                grouped.putIfAbsent(o['userId'] as String, () => []).add(o);
              }
              final groupKeys = grouped.keys.toList()
                ..sort((a, b) {
                  final aNewest = grouped[a]!.first['createdAt'] as Timestamp?;
                  final bNewest = grouped[b]!.first['createdAt'] as Timestamp?;
                  if (aNewest == null) return 1;
                  if (bNewest == null) return -1;
                  return bNewest.compareTo(aNewest);
                });

              final displayedGroups = groupKeys.take(_orderLimit).toList();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount:
                    displayedGroups.length +
                    (groupKeys.length > _orderLimit ? 1 : 0),
                itemBuilder: (ctx, gi) {
                  if (gi >= _orderLimit)
                    return _loadMoreButton(groupKeys.length, _orderLimit);
                  final uid = displayedGroups[gi];
                  final userOrders = grouped[uid]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 4, 0, 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                uid.length > 16
                                    ? '${uid.substring(0, 16)}...'
                                    : uid,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${userOrders.length} order${userOrders.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Orders for this user
                      ...userOrders.map((o) {
                        final status = o['status'] as String;
                        final color = _orderStatusColor(status);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
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
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 18,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onSelected: (newStatus) {
                                        _firestoreService
                                            .adminUpdateOrderStatus(
                                              userId: o['userId'] as String,
                                              orderId:
                                                  o['firestoreId'] as String,
                                              newStatus: newStatus,
                                            );
                                        // Force stream refresh for real-time UI update
                                        _ordersStream = null;
                                        setState(() {});
                                        AppSnack.success(
                                          'Updated',
                                          'Order status changed to $newStatus.',
                                        );
                                      },
                                      itemBuilder: (_) {
                                        final nextStatuses = _nextStatuses(
                                          status,
                                        );
                                        return nextStatuses.map((s) {
                                          return PopupMenuItem(
                                            value: s,
                                            child: Text(
                                              s,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
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
                                          padding: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                      }),
                    ],
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
    const flow = ['Processing', 'Shipping', 'On Delivery', 'Delivered'];
    final idx = flow.indexOf(current);
    if (idx < 0) return ['Processing'];
    final options = <String>['Cancelled'];
    if (idx < flow.length - 1) options.insert(0, flow[idx + 1]);
    return options;
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppTheme.successColor;
      case 'On Delivery':
        return Colors.blue;
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

  // Shop search state
  final TextEditingController _shopSearchCtrl = TextEditingController();
  String _shopSearchQuery = '';

  Widget _buildShopsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('shops').orderBy('name').snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        final allShops = snap.data?.docs ?? [];
        // Filter by search
        final shops = _shopSearchQuery.isEmpty
            ? allShops
            : allShops.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final desc = (data['description'] ?? '')
                    .toString()
                    .toLowerCase();
                return name.contains(_shopSearchQuery) ||
                    desc.contains(_shopSearchQuery);
              }).toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _shopSearchCtrl,
                  onChanged: (v) =>
                      setState(() => _shopSearchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search shops...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _shopSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _shopSearchCtrl.clear();
                              setState(() => _shopSearchQuery = '');
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
            // List
            Expanded(
              child: shops.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('🏪', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          Text(
                            _shopSearchQuery.isNotEmpty
                                ? 'No matching shops'
                                : 'No shops yet',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _shopSearchQuery.isNotEmpty
                                ? 'Try a different search'
                                : 'Tap + to add your first shop',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9EAA),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount:
                          shops.take(_shopLimit).length +
                          (shops.length > _shopLimit ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _shopLimit)
                          return _loadMoreButton(shops.length, _shopLimit);
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
                              GestureDetector(
                                onTap: () async {
                                  final newVal = !(d['isPopular'] == true);
                                  await _firestore
                                      .collection('shops')
                                      .doc(shops[i].id)
                                      .update({'isPopular': newVal});
                                  AppSnack.success(
                                    newVal ? 'Popular' : 'Unmarked',
                                    newVal
                                        ? 'Shop added to Popular section.'
                                        : 'Shop removed from Popular section.',
                                  );
                                  setState(() {});
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (d['isPopular'] == true)
                                        ? AppTheme.secondaryColor
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        (d['isPopular'] == true)
                                            ? Icons.star
                                            : Icons.star_border,
                                        size: 10,
                                        color: (d['isPopular'] == true)
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'Popular',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: (d['isPopular'] == true)
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
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
                                  if (result is String) {
                                    AppSnack.success(
                                      result == 'updated'
                                          ? 'Updated'
                                          : 'Created',
                                      result == 'updated'
                                          ? 'Shop updated.'
                                          : 'Shop created.',
                                    );
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

  // ═══════════════════════════════════════════════════════════════
  // CATEGORIES TAB
  // ═══════════════════════════════════════════════════════════════

  // Category search state
  final TextEditingController _catSearchCtrl = TextEditingController();
  String _catSearchQuery = '';

  Widget _buildCategoriesTab(bool isDark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getCategoriesStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }
        final allCats = snap.data ?? [];
        final categories = _catSearchQuery.isEmpty
            ? allCats
            : allCats.where((c) {
                final name = (c['name'] ?? '').toString().toLowerCase();
                return name.contains(_catSearchQuery);
              }).toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _catSearchCtrl,
                  onChanged: (v) =>
                      setState(() => _catSearchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search categories...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _catSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _catSearchCtrl.clear();
                              setState(() => _catSearchQuery = '');
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
            // List
            Expanded(
              child: allCats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📂', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: 12),
                          const Text(
                            'No categories yet',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap + to add your first category',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9E9EAA),
                            ),
                          ),
                        ],
                      ),
                    )
                  : categories.isEmpty
                  ? Center(
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
                            'No matching categories',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      itemCount:
                          categories.take(_catLimit).length +
                          (categories.length > _catLimit ? 1 : 0),
                      onReorder: (oldIdx, newIdx) {
                        if (oldIdx < newIdx) newIdx--;
                        final list = List<Map<String, dynamic>>.from(
                          categories,
                        );
                        final item = list.removeAt(oldIdx);
                        list.insert(newIdx, item);
                        setState(() {});
                        _firestoreService.reorderCategories(list);
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(14),
                          shadowColor: AppTheme.primaryColor.withValues(
                            alpha: 0.2,
                          ),
                          child: child,
                        );
                      },
                      itemBuilder: (_, i) {
                        if (i >= _catLimit)
                          return _loadMoreButton(categories.length, _catLimit);
                        final cat = categories[i];
                        return Container(
                          key: Key(cat['id'] as String),
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
                              ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.drag_handle,
                                    color: Color(0xFFBDBDBD),
                                    size: 22,
                                  ),
                                ),
                              ),
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    cat['icon'] as String? ?? '🛍️',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  cat['name'] as String? ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                onPressed: () =>
                                    _showCategoryDialog(category: cat),
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
                                onPressed: () => _deleteCategory(cat),
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

  Future<void> _deleteCategory(Map<String, dynamic> cat) async {
    final c = await AppDialog.deleteConfirm(
      title: 'Delete Category?',
      message: 'Delete "${cat['name']}"? This cannot be undone.',
    );
    if (c != true) return;
    try {
      await _firestoreService.deleteCategory(cat['id'] as String);
      AppSnack.success('Deleted', 'Category removed.');
    } catch (_) {
      AppSnack.error('Error', 'Failed to delete category.');
    }
  }

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final iconCtrl = TextEditingController(text: category?['icon'] ?? '');
    final isEdit = category != null;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(isEdit ? 'Edit Category' : 'New Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Clothing, Electronics',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconCtrl,
              decoration: const InputDecoration(
                labelText: 'Icon (emoji)',
                hintText: 'e.g. 👕, 📱, 🏠',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) {
                AppSnack.error('Required', 'Category name cannot be empty.');
                return;
              }
              Get.back();
              try {
                await _firestoreService.saveCategory(
                  name: name,
                  icon: iconCtrl.text.trim().isEmpty
                      ? '🛍️'
                      : iconCtrl.text.trim(),
                  docId: category?['id'] as String?,
                );
                AppSnack.success(
                  isEdit ? 'Updated' : 'Created',
                  isEdit ? 'Category updated.' : 'Category created.',
                );
              } catch (_) {
                AppSnack.error('Error', 'Failed to save category.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _deleteShop(DocumentSnapshot doc) async {
    final c = await AppDialog.deleteConfirm(
      title: 'Delete Shop?',
      message:
          'This cannot be undone. Products belonging to this shop will remain but show as "Unknown Shop".',
    );
    if (c != true) return;
    try {
      await _firestore.collection('shops').doc(doc.id).delete();
      AppSnack.success('Deleted', 'Shop removed.');
    } catch (_) {
      AppSnack.error('Error', 'Failed to delete shop.');
    }
  }

  Widget _loadMoreButton(int total, int current, {double bottomPadding = 16}) {
    if (current >= total) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 4, 16, bottomPadding),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _loadMoreCurrentTab,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: const BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Load More (${current} of $total)',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
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
