import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../routes/app_routes.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../services/fcm_service.dart';
import '../../../controllers/theme_controller.dart';
import '../../../controllers/product_controller.dart';

// ╔══════════════════════════════════════════════════════════════╗
// ║                        ORDERS SCREEN                         ║
// ╚══════════════════════════════════════════════════════════════╝
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  int _activeTab = 0;
  final _tabs = [
    'All',
    'Processing',
    'Shipping',
    'On Delivery',
    'Delivered',
    'Cancelled',
    'To Review',
  ];

  final List<Map<String, dynamic>> _mockOrders = [
    {
      'id': '#TC-2024001',
      'date': 'June 5, 2026',
      'status': 'Delivered',
      'items': [
        {
          'name': 'Slim Fit T-Shirt',
          'image': 'https://picsum.photos/seed/tshirt1/200/200',
          'qty': 2,
          'price': 24.99,
        },
        {
          'name': 'Denim Jacket',
          'image': 'https://picsum.photos/seed/jacket1/200/200',
          'qty': 1,
          'price': 74.99,
        },
      ],
      'total': 124.97,
    },
    {
      'id': '#TC-2024002',
      'date': 'June 7, 2026',
      'status': 'Shipping',
      'items': [
        {
          'name': 'Running Sneakers',
          'image': 'https://picsum.photos/seed/sneaker1/200/200',
          'qty': 1,
          'price': 49.99,
        },
      ],
      'total': 49.99,
    },
    {
      'id': '#TC-2024003',
      'date': 'June 8, 2026',
      'status': 'Processing',
      'items': [
        {
          'name': 'Cotton Dress',
          'image': 'https://picsum.photos/seed/dress1/200/200',
          'qty': 1,
          'price': 39.99,
        },
        {
          'name': 'Leather Belt',
          'image': 'https://picsum.photos/seed/belt1/200/200',
          'qty': 1,
          'price': 39.99,
        },
      ],
      'total': 79.98,
    },
    {
      'id': '#TC-2024004',
      'date': 'June 13, 2026',
      'status': 'Delivered',
      'items': [
        {
          'name': 'Wireless Earbuds',
          'image': 'https://picsum.photos/seed/earbuds1/200/200',
          'qty': 1,
          'price': 89.99,
        },
      ],
      'total': 89.99,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> list) {
    if (_activeTab == 0) return list;
    if (_activeTab == 6)
      return list.where((o) => o['status'] == 'Delivered').toList();
    final status = _tabs[_activeTab];
    return list.where((o) => o['status'] == status).toList();
  }

  Color _statusColor(String status) {
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

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Delivered':
        return Icons.check_circle;
      case 'On Delivery':
        return Icons.delivery_dining;
      case 'Shipping':
        return Icons.local_shipping;
      case 'Processing':
        return Icons.hourglass_top;
      case 'Cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  int _statusStep(String status) {
    switch (status) {
      case 'Processing':
        return 1;
      case 'Shipping':
        return 2;
      case 'On Delivery':
        return 3;
      case 'Delivered':
        return 4;
      default:
        return 0;
    }
  }

  Map<String, dynamic> _orderForDetail(Map<String, dynamic> o) {
    return {
      'id': o['id'],
      'firestoreId': o['firestoreId'],
      'date': o['date'],
      'status': o['status'],
      'items': o['items'],
      'total': o['total'],
      'icon': _statusIcon(o['status']),
      'color': _statusColor(o['status']),
    };
  }

  Future<void> _clearAllInTab() async {
    final tab = _tabs[_activeTab];
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear $tab Orders'),
        content: Text(
          _activeTab == 0
              ? 'Delete ALL orders? This cannot be undone.'
              : 'Delete all orders in "$tab"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      // Get all orders and filter
      final snapshot = await _firestoreService.getOrdersStream().first;
      int deleted = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String? ?? '';
        if (_activeTab == 0 || status == tab) {
          await _firestoreService.deleteOrder(doc.id);
          deleted++;
        }
      }
      AppSnack.success('Cleared', '$deleted order(s) deleted.');
    } catch (_) {
      AppSnack.error('Error', 'Could not clear orders.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          if (_activeTab == 4 || _activeTab == 5)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear ${_tabs[_activeTab]}',
              onPressed: _clearAllInTab,
            ),
        ],
      ),
      body: Column(
        children: [
          // Twitter-style tab bar
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
                            width: active ? 32 : 0,
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
          // Order list — real-time stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getOrdersStream(),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  );
                }
                List<Map<String, dynamic>> orders;
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  orders = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final ts = data['createdAt'] as Timestamp?;
                    return {
                      'id': '#${doc.id.substring(0, 8).toUpperCase()}',
                      'firestoreId': doc.id,
                      'date': ts != null
                          ? '${ts.toDate().day} ${_monthName(ts.toDate().month)} ${ts.toDate().year}'
                          : 'Just now',
                      'status': data['status'] ?? 'Processing',
                      'items': List<Map<String, dynamic>>.from(
                        data['items'] ?? [],
                      ),
                      'total': (data['total'] ?? 0).toDouble(),
                    };
                  }).toList();
                } else {
                  // No Firestore data — show empty state
                  orders = [];
                }
                final filtered = _filterList(orders);

                if (filtered.isEmpty) {
                  return _buildEmptyState(_tabs[_activeTab]);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final o = filtered[i];
                    final items = o['items'] as List;
                    final status = o['status'] as String;
                    final color = _statusColor(status);
                    final card = _buildOrderCard(
                      cardBg,
                      isDark,
                      o,
                      items,
                      status,
                      color,
                    );
                    // Allow swipe-to-delete for cancelled orders
                    if (status == 'Cancelled') {
                      return Dismissible(
                        key: Key(o['firestoreId'] ?? o['id'] as String),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          await _deleteOrder(o);
                          return true;
                        },
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        child: card,
                      );
                    }
                    return card;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrderFromList(Map<String, dynamic> o) {
    final fid = o['firestoreId'] as String?;
    if (fid == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Cancel Order',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Cancel this order?',
          style: TextStyle(color: Color(0xFF9E9EAA)),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              try {
                await _firestoreService.cancelOrder(fid);
                AppSnack.success('Cancelled', 'Order has been cancelled.');
              } catch (_) {
                AppSnack.error('Error', 'Could not cancel order.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmArrival(Map<String, dynamic> o) {
    final fid = o['firestoreId'] as String?;
    if (fid == null) return;
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Confirm Arrival',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Have you received this order?',
          style: TextStyle(color: Color(0xFF9E9EAA)),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Not yet')),
          FilledButton(
            onPressed: () async {
              Get.back();
              try {
                await _firestoreService.adminUpdateOrderStatus(
                  userId: FirebaseFirestoreService().currentUserId,
                  orderId: fid,
                  newStatus: 'Delivered',
                );
                AppSnack.success(
                  'Confirmed',
                  'Order marked as delivered. You can now review the products.',
                );
              } catch (_) {
                AppSnack.error('Error', 'Could not confirm arrival.');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(Map<String, dynamic> o) async {
    final fid = o['firestoreId'] as String?;
    if (fid == null) return;
    try {
      await _firestoreService.deleteOrder(fid);
      AppSnack.info('Deleted', 'Order removed.');
    } catch (_) {
      AppSnack.error('Error', 'Could not delete order.');
    }
  }

  Widget _buildEmptyState(String tab) {
    String icon;
    String title;
    String subtitle;
    switch (tab) {
      case 'To Review':
        icon = '⭐';
        title = 'Nothing to review';
        subtitle = 'Delivered orders will appear here for you to rate.';
        break;
      case 'Processing':
        icon = '📦';
        title = 'No processing orders';
        subtitle = 'Orders being prepared will show up here.';
        break;
      case 'Shipping':
        icon = '🚚';
        title = 'No shipped orders';
        subtitle = 'Orders on the way will appear here.';
        break;
      case 'Delivered':
        icon = '✅';
        title = 'No delivered orders';
        subtitle = 'Completed orders will show up here.';
        break;
      case 'Cancelled':
        icon = '🗑️';
        title = 'No cancelled orders';
        subtitle = 'Cancelled orders will appear here.';
        break;
      default:
        icon = '🛍️';
        title = 'No orders yet';
        subtitle = 'Start shopping to see your orders!';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.offAllNamed(AppRoutes.main),
            icon: const Icon(Icons.shopping_bag_outlined, size: 16),
            label: const Text('Start Shopping', style: TextStyle(fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
    Color cardBg,
    bool isDark,
    Map<String, dynamic> o,
    List items,
    String status,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: color),
                      const SizedBox(width: 5),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  o['id'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: List.generate(3, (j) {
                final filled = j < _statusStep(status);
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(left: j > 0 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: filled
                          ? color
                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                ...items
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: isDark
                                ? AppTheme.darkSurface2
                                : const Color(0xFFF1F3F5),
                            child: Image.network(
                              item['image'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_outlined,
                                size: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                if (items.length > 3)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '+${items.length - 3}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(o['total'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '${o['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Cancel button for Processing orders
                  if (status == 'Processing')
                    TextButton.icon(
                      onPressed: () => _cancelOrderFromList(o),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: AppTheme.errorColor,
                      ),
                      label: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  // Confirm Arrival for On Delivery
                  if (status == 'On Delivery')
                    TextButton.icon(
                      onPressed: () => _confirmArrival(o),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      label: const Text(
                        'Confirm Arrival',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  // Review buttons for Delivered orders — navigate to product
                  if (status == 'Delivered')
                    TextButton.icon(
                      onPressed: () {
                        final raw = o['items'];
                        if (raw is! List || raw.isEmpty) return;
                        final pc = Get.find<ProductController>();
                        // Try each item until a valid product is found
                        for (final item in raw) {
                          if (item is! Map) continue;
                          final pid = (item['productId'] as String?) ?? '';
                          if (pid.isNotEmpty) {
                            final product = pc.getProductById(pid);
                            if (product != null) {
                              Get.toNamed(
                                AppRoutes.productDetail,
                                arguments: product,
                              );
                              return;
                            }
                          }
                        }
                        // Fallback: navigate to first item's product detail
                        final first = raw.first as Map;
                        Get.toNamed(
                          AppRoutes.productDetail,
                          arguments: {
                            'id': first['productId'] ?? '',
                            'name':
                                first['name'] ?? first['title'] ?? 'Product',
                            'image': first['image'] ?? '',
                          },
                        );
                      },
                      icon: const Icon(
                        Icons.star_outline,
                        size: 16,
                        color: AppTheme.secondaryColor,
                      ),
                      label: const Text(
                        'Review',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.orderDetail,
                      arguments: _orderForDetail(o),
                    ),
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppTheme.primaryColor,
                    ),
                    label: const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

// ╔══════════════════════════════════════════════════════════════╗
// ║                      ADDRESSES SCREEN                        ║
// ╚══════════════════════════════════════════════════════════════╝
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final FirebaseFirestoreService _firestoreService = FirebaseFirestoreService();
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    try {
      final addrs = await _firestoreService.getAddresses();
      if (addrs.isNotEmpty) {
        setState(() {
          _addresses = addrs;
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    // Fallback mock if Firestore empty — removed; use empty state instead
    setState(() {
      _addresses = [];
      _loading = false;
    });
  }

  void _showAddressDialog({int? index}) {
    final isEdit = index != null;
    final existing = isEdit ? _addresses[index] : null;
    final recipientCtrl = TextEditingController(
      text: existing?['recipient'] ?? '',
    );
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final streetCtrl = TextEditingController(text: existing?['street'] ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] ?? '');
    final provinceCtrl = TextEditingController(
      text: existing?['province'] ?? '',
    );
    final zipCtrl = TextEditingController(text: existing?['zip'] ?? '');
    var isDefault = existing?['isDefault'] == true || _addresses.isEmpty;
    var saving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEdit ? 'Edit Address' : 'New Address',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        recipientCtrl,
                        'Recipient Name',
                        Icons.person_outlined,
                        maxLength: 50,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        phoneCtrl,
                        'Phone Number',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  labelCtrl,
                  'Label (Home, Office, etc.)',
                  Icons.label_outlined,
                  maxLength: 30,
                ),
                const SizedBox(height: 12),
                _field(
                  streetCtrl,
                  'Street Address',
                  Icons.location_on_outlined,
                  keyboardType: TextInputType.streetAddress,
                  maxLines: 2,
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        cityCtrl,
                        'City',
                        Icons.location_city_outlined,
                        maxLength: 50,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _field(
                        provinceCtrl,
                        'Province/State',
                        Icons.map_outlined,
                        maxLength: 50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  zipCtrl,
                  'Postal Code',
                  Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Set as default address',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: isDefault,
                  onChanged: (v) => setD(() => isDefault = v),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (recipientCtrl.text.trim().isEmpty ||
                          streetCtrl.text.trim().isEmpty ||
                          cityCtrl.text.trim().isEmpty) {
                        AppSnack.error(
                          'Required',
                          'Please fill recipient, street, and city.',
                        );
                        return;
                      }
                      setD(() => saving = true);
                      final addr = {
                        'firestoreId': isEdit
                            ? existing!['firestoreId'] ?? ''
                            : '',
                        'recipient': recipientCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'label': labelCtrl.text.trim().isEmpty
                            ? 'Address'
                            : labelCtrl.text.trim(),
                        'street': streetCtrl.text.trim(),
                        'city': cityCtrl.text.trim(),
                        'province': provinceCtrl.text.trim(),
                        'zip': zipCtrl.text.trim(),
                        'isDefault': isDefault,
                      };
                      try {
                        if (isEdit &&
                            (addr['firestoreId'] as String).isNotEmpty) {
                          await _firestoreService.saveAddress(
                            addr,
                            docId: addr['firestoreId'] as String,
                          );
                        } else {
                          await _firestoreService.saveAddress(addr);
                        }
                        Get.back();
                        _loadAddresses();
                        AppSnack.success(
                          'Saved',
                          isEdit ? 'Address updated.' : 'Address added.',
                        );
                      } catch (_) {
                        setD(() => saving = false);
                        AppSnack.error('Error', 'Could not save address.');
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: Text(saving ? 'Saving...' : (isEdit ? 'Update' : 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
        isDense: true,
      ),
    );
  }

  void _deleteAddress(int index) {
    final addr = _addresses[index];
    final docId = addr['firestoreId'] as String?;
    if (docId != null && docId.isNotEmpty && !docId.startsWith('mock')) {
      _firestoreService.deleteAddress(docId);
    }
    setState(() => _addresses.removeAt(index));
    AppSnack.info('Removed', 'Address removed.');
  }

  Future<void> _setAddressDefault(int index) async {
    final addr = _addresses[index];
    final docId = addr['firestoreId'] as String?;
    // Update locally
    setState(() {
      for (var a in _addresses) {
        a['isDefault'] = false;
      }
      _addresses[index]['isDefault'] = true;
    });
    // Update Firestore
    if (docId != null && docId.isNotEmpty) {
      try {
        await _firestoreService.saveAddress({
          ..._addresses[index],
        }, docId: docId);
      } catch (_) {}
    }
    AppSnack.success('Default Set', 'Default address updated.');
  }

  void _editAddress(int index) async {
    final a = _addresses[index];
    final result = await Get.toNamed(AppRoutes.addEditAddress, arguments: a);
    if (result != null) _loadAddresses();
  }

  String _formatPhone(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '';
    if (d.length <= 3) return d;
    if (d.length <= 6) return '${d.substring(0, 3)} ${d.substring(3)}';
    return '${d.substring(0, 3)} ${d.substring(3, 6)} ${d.substring(6, d.length > 10 ? 10 : d.length)}';
  }

  IconData _labelIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'office':
        return Icons.business_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.toNamed(AppRoutes.addEditAddress);
          if (result != null) _loadAddresses();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved addresses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add an address for faster checkout',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: List.generate(_addresses.length, (i) {
                final a = _addresses[i];
                return Dismissible(
                  key: Key('addr-$i'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    _deleteAddress(i);
                    return true;
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: a['isDefault'] == true
                            ? AppTheme.primaryColor
                            : (isDark ? Colors.white10 : Colors.grey.shade200),
                        width: a['isDefault'] == true ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: a['isDefault'] == true
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _labelIcon(a['label'] ?? 'Address'),
                            color: a['isDefault'] == true
                                ? Colors.white
                                : AppTheme.primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    a['label'] ?? 'Address',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (a['isDefault'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                a['recipient'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${a['street']}\n${a['city']}${(a['province'] as String? ?? '').isNotEmpty ? ', ${a['province']}' : ''} ${a['zip']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.color,
                                  height: 1.5,
                                ),
                              ),
                              if ((a['phone'] as String? ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _formatPhone(a['phone'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                size: 20,
                                color: Color(0xFF9E9EAA),
                              ),
                              color: isDark
                                  ? AppTheme.darkSurface
                                  : Colors.white,
                              onSelected: (v) {
                                if (v == 'edit') _editAddress(i);
                                if (v == 'default') _setAddressDefault(i);
                                if (v == 'delete') _deleteAddress(i);
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(
                                    'Edit Address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (a['isDefault'] != true)
                                  PopupMenuItem(
                                    value: 'default',
                                    child: Text(
                                      'Set as Default',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Remove Address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                    PAYMENT METHODS SCREEN                    ║
// ╚══════════════════════════════════════════════════════════════╝
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final _firestoreService = FirebaseFirestoreService();
  List<Map<String, dynamic>> _cards = [];
  List<Map<String, dynamic>> _bankAccounts = [];
  bool _loading = true;
  int _paymentTab = 0; // 0 = Cards, 1 = Bank Accounts

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    try {
      final cards = await _firestoreService.getCards();
      final banks = await _firestoreService.getBankAccounts();
      setState(() {
        _cards = cards;
        _bankAccounts = banks;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _cards = [];
        _bankAccounts = [];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _mockCards() => [
    {
      'firestoreId': 'mock1',
      'number': '4242424242424242',
      'holder': 'SENG HAMKI',
      'expiry': '12/27',
      'brand': 'visa',
      'isDefault': true,
    },
    {
      'firestoreId': 'mock2',
      'number': '5555555555554444',
      'holder': 'SENG HAMKI',
      'expiry': '06/26',
      'brand': 'mastercard',
      'isDefault': false,
    },
  ];

  List<Map<String, dynamic>> _mockBanks() => [
    {
      'firestoreId': 'bank_mock1',
      'bankName': 'ABA Bank',
      'accountHolder': 'SENG HAMKI',
      'accountNumber': '00123456789',
      'routingNumber': '',
      'accountType': 'checking',
      'isDefault': true,
    },
    {
      'firestoreId': 'bank_mock2',
      'bankName': 'ACLEDA Bank',
      'accountHolder': 'SENG HAMKI',
      'accountNumber': '98765432100',
      'routingNumber': '',
      'accountType': 'savings',
      'isDefault': false,
    },
  ];

  IconData _brandIcon(String brand) {
    switch (brand) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_score;
      default:
        return Icons.payment;
    }
  }

  String _formatNumber(String num) {
    if (num.length >= 4) return '•••• ${num.substring(num.length - 4)}';
    return num;
  }

  Color _brandColor(String brand) {
    switch (brand) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      default:
        return AppTheme.primaryColor;
    }
  }

  void _deleteCard(int index) {
    final card = _cards[index];
    final docId = card['firestoreId'] as String?;
    if (docId != null && docId.isNotEmpty && !docId.startsWith('mock')) {
      _firestoreService.deleteCard(docId);
    }
    setState(() => _cards.removeAt(index));
    AppSnack.info('Removed', 'Card removed.');
  }

  void _setDefault(int index) {
    setState(() {
      for (var c in _cards) {
        c['isDefault'] = false;
      }
      _cards[index]['isDefault'] = true;
    });
  }

  void _editCard(int index) async {
    final card = _cards[index];
    final result = await Get.toNamed(AppRoutes.addCard, arguments: card);
    if (result is String && mounted) {
      AppSnack.success(
        result == 'updated' ? 'Updated' : 'Added',
        result == 'updated' ? 'Card updated.' : 'Card added.',
      );
      _loadCards();
    }
  }

  void _deleteBank(int index) {
    final bank = _bankAccounts[index];
    final docId = bank['firestoreId'] as String?;
    if (docId != null && docId.isNotEmpty && !docId.startsWith('mock')) {
      _firestoreService.deleteBankAccount(docId);
    }
    setState(() => _bankAccounts.removeAt(index));
    AppSnack.info('Removed', 'Bank account removed.');
  }

  void _setBankDefault(int index) {
    setState(() {
      for (var b in _bankAccounts) {
        b['isDefault'] = false;
      }
      _bankAccounts[index]['isDefault'] = true;
    });
  }

  void _editBank(int index) async {
    final bank = _bankAccounts[index];
    final result = await Get.toNamed(AppRoutes.addBank, arguments: bank);
    if (result is String && mounted) {
      AppSnack.success(
        result == 'updated' ? 'Updated' : 'Added',
        result == 'updated' ? 'Bank account updated.' : 'Bank account added.',
      );
      _loadCards();
    }
  }

  // Bank account add navigation
  Future<void> _addBank() async {
    final result = await Get.toNamed(AppRoutes.addBank);
    if (result is String && mounted) {
      AppSnack.success('Added', 'Bank account added.');
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (_paymentTab == 0) {
            final result = await Get.toNamed(AppRoutes.addCard);
            if (result is String && mounted) {
              AppSnack.success(
                result == 'updated' ? 'Updated' : 'Added',
                result == 'updated' ? 'Card updated.' : 'Card added.',
              );
              _loadCards();
            }
          } else {
            _addBank();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_paymentTab == 0 ? 'Add Card' : 'Add Bank'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Twitter-style tabs — in body to avoid AppBar overflow
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [_tabBtn('Cards', 0), _tabBtn('Bank Accounts', 1)],
            ),
          ),
          Expanded(
            child: _paymentTab == 0
                ? _buildCardsList(isDark)
                : _buildBanksList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int tab) {
    final active = _paymentTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _paymentTab = tab),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.primaryColor : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: active ? 3 : 0,
                width: active ? 32 : 0,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsList(bool isDark) {
    if (_cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_rounded,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved cards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: List.generate(_cards.length, (i) {
        final c = _cards[i];
        final brandColor = _brandColor(c['brand'] ?? 'visa');
        return Dismissible(
          key: Key('card-${c['firestoreId'] ?? i}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            _deleteCard(i);
            return true;
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 14),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor, brandColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      _brandIcon(c['brand'] ?? 'visa'),
                      color: Colors.white70,
                      size: 28,
                    ),
                    Row(
                      children: [
                        if (c['isDefault'] == true)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
                            size: 20,
                          ),
                          color: isDark ? AppTheme.darkSurface : Colors.white,
                          onSelected: (v) {
                            if (v == 'edit') _editCard(i);
                            if (v == 'default') _setDefault(i);
                            if (v == 'delete') _deleteCard(i);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                'Edit Card',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'default',
                              child: Text(
                                'Set as Default',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Remove Card',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _formatNumber(c['number'] ?? ''),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARD HOLDER',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['holder'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRES',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c['expiry'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      (c['brand'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBanksList(bool isDark) {
    if (_bankAccounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 72,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'No bank accounts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a bank account for direct transfers',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: List.generate(_bankAccounts.length, (i) {
        final b = _bankAccounts[i];
        return Dismissible(
          key: Key('bank-${b['firestoreId'] ?? i}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            _deleteBank(i);
            return true;
          },
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 26,
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: b['isDefault'] == true
                    ? AppTheme.primaryColor
                    : (isDark ? Colors.white10 : Colors.grey.shade200),
                width: b['isDefault'] == true ? 2 : 1,
              ),
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            b['bankName'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (b['isDefault'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        b['accountHolder'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '••••${(b['accountNumber'] ?? '').toString().length > 4 ? (b['accountNumber'] as String).substring((b['accountNumber'] as String).length - 4) : b['accountNumber']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  onSelected: (v) {
                    if (v == 'edit') _editBank(i);
                    if (v == 'default') _setBankDefault(i);
                    if (v == 'delete') _deleteBank(i);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit Account',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'default',
                      child: Text(
                        'Set as Default',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                      SETTINGS SCREEN                         ║
// ╚══════════════════════════════════════════════════════════════╝
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _language = 'English';
  String _currency = 'USD (\$)';
  String _country = 'Cambodia';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore.collection('settings').doc('app').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _currency = data['currency'] ?? 'USD (\$)';
          _language = data['language'] ?? 'English';
          _country = data['country'] ?? 'Cambodia';
        });
      }
    } catch (_) {}
  }

  Future<void> _saveCurrency(String v) async {
    await _firestore.collection('settings').doc('app').set({
      'currency': v,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _selectOption(
    String title,
    String current,
    List<String> options,
    Function(String) onSelect,
  ) {
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
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (o) => ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    fontWeight: current == o
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: current == o ? AppTheme.primaryColor : null,
                  ),
                ),
                trailing: current == o
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  onSelect(o);
                  Navigator.pop(context);
                },
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
    final themeCtrl = Get.find<ThemeController>();
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        const Color(0xFF9E9EAA);
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dark Mode Toggle
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            child: Obx(
              () => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Row(
                  children: [
                    Icon(Icons.dark_mode_outlined, size: 22),
                    SizedBox(width: 12),
                    Text('Dark Mode', style: TextStyle(fontSize: 15)),
                  ],
                ),
                subtitle: Text(
                  themeCtrl.isDarkMode.value ? 'Enabled' : 'Disabled',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
                value: themeCtrl.isDarkMode.value,
                onChanged: (_) => themeCtrl.toggleTheme(),
                activeColor: AppTheme.primaryColor,
              ),
            ),
          ),
          _tile(
            'Language',
            _language,
            () => _selectOption('Language', _language, [
              'English',
              'Khmer',
              'Chinese',
              'French',
            ], (v) => setState(() => _language = v)),
            subColor,
          ),
          _tile(
            'Currency',
            _currency,
            () => _selectOption(
              'Currency',
              _currency,
              ['USD (\$)', 'KHR (៛)', 'EUR (€)'],
              (v) {
                setState(() => _currency = v);
                _saveCurrency(v);
              },
            ),
            subColor,
          ),
          _tile(
            'Country / Region',
            _country,
            () => _selectOption('Country', _country, [
              'Cambodia',
              'Vietnam',
              'Thailand',
              'Laos',
            ], (v) => setState(() => _country = v)),
            subColor,
          ),
          _tile('Cache Size', '24.5 MB', () {}, subColor),
          _adminAccessTile('App Version', '1.0.0', subColor),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Get.snackbar(
                  'Done',
                  'Local data cleared!',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppTheme.successColor,
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
              ),
              child: const Text('Clear All Data'),
            ),
          ),
        ],
      ),
    );
  }

  // Triple-tap to access admin panel
  int _adminTapCount = 0;
  DateTime _lastAdminTap = DateTime.now();

  Widget _adminAccessTile(String title, String value, Color sub) {
    return InkWell(
      onTap: () {
        final now = DateTime.now();
        if (now.difference(_lastAdminTap).inMilliseconds > 800) {
          _adminTapCount = 0;
        }
        _lastAdminTap = now;
        _adminTapCount++;
        if (_adminTapCount >= 3) {
          _adminTapCount = 0;
          Get.toNamed(AppRoutes.adminProducts);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 15)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontSize: 14, color: sub)),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF9E9EAA),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, String value, VoidCallback tap, Color sub) =>
      InkWell(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: TextStyle(fontSize: 14, color: sub)),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF9E9EAA),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                    NOTIFICATIONS SCREEN                      ║
// ╚══════════════════════════════════════════════════════════════╝
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final FcmService _fcm = FcmService();
  int _unreadCount = 0;

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        const Color(0xFF9E9EAA);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: () {
                _fcm.markAllAsRead();
                setState(() => _unreadCount = 0);
              },
              child: const Text(
                'Mark All Read',
                style: TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fcm.getNotificationsStream(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Fallback to mock data if no Firestore notifications
            return _buildMockNotifications(cardBg, subColor);
          }

          final docs = snapshot.data!.docs;
          // Count unread
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final unread = docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              return data['read'] != true;
            }).length;
            if (_unreadCount != unread) {
              setState(() => _unreadCount = unread);
            }
          });

          if (docs.isEmpty) {
            return _buildMockNotifications(cardBg, subColor);
          }

          return Column(
            children: [
              if (_unreadCount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  child: Text(
                    '$_unreadCount unread',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final title = data['title'] as String? ?? '';
                    final body = data['body'] as String? ?? '';
                    final read = data['read'] == true;
                    final ts = data['createdAt'] as Timestamp?;
                    final time = ts != null ? _fmtTime(ts.toDate()) : '';
                    final emoji = _emojiFor(title);

                    return Dismissible(
                      key: Key('notif-${docs[i].id}'),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => docs[i].reference.delete(),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (!read) {
                            _fcm.markAsRead(docs[i].id);
                            setState(
                              () => _unreadCount = (_unreadCount - 1).clamp(
                                0,
                                999,
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: read
                                ? cardBg
                                : AppTheme.primaryColor.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: read
                                ? null
                                : Border.all(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 26)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: read
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (!read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      body,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: subColor,
                                      ),
                                    ),
                                    if (time.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMockNotifications(Color cardBg, Color subColor) {
    final mockNotifs = [
      _Notif(
        '🎉',
        'Welcome!',
        'Thanks for joining Tiny Chicken. Start exploring!',
        '2 days ago',
        false,
      ),
      _Notif(
        '💰',
        'Flash Sale Alert!',
        'Items in your wishlist are now up to 40% off!',
        '5 hours ago',
        false,
      ),
      _Notif(
        '📦',
        'Order Shipped',
        'Your order #TC-2024002 is on its way!',
        '1 day ago',
        false,
      ),
      _Notif(
        '⭐',
        'Leave a Review',
        'How was your recent purchase? Share your feedback.',
        '3 days ago',
        false,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockNotifs.length,
      itemBuilder: (ctx, i) {
        final n = mockNotifs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.read
                ? cardBg
                : AppTheme.primaryColor.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: n.read
                ? null
                : Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: n.read
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: TextStyle(fontSize: 12, color: subColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.time,
                      style: TextStyle(fontSize: 10, color: subColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _emojiFor(String title) {
    final t = title.toLowerCase();
    if (t.contains('order') || t.contains('ship')) return '📦';
    if (t.contains('sale') || t.contains('offer')) return '💰';
    if (t.contains('review') || t.contains('rate')) return '⭐';
    if (t.contains('welcome')) return '🎉';
    if (t.contains('cancel')) return '❌';
    if (t.contains('deliver')) return '✅';
    return '🔔';
  }

  String _fmtTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _Notif {
  final String emoji, title, body, time;
  bool read;
  _Notif(this.emoji, this.title, this.body, this.time, this.read);
}

// ╔══════════════════════════════════════════════════════════════╗
// ║                     HELP CENTER SCREEN                       ║
// ╚══════════════════════════════════════════════════════════════╝
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final faqs = [
      _FAQ(
        'How do I track my order?',
        'Go to My Orders → tap "View Order Details" on any order to see real-time tracking with step-by-step progress (Processing → Shipping → Delivered).',
      ),
      _FAQ(
        'What is the return policy?',
        'Return most items within 30 days of delivery. Items must be unworn, with original tags and packaging. Refunds are processed within 5-7 business days.',
      ),
      _FAQ(
        'How do I apply a promo code?',
        'At checkout, enter your code in the Promo Code field and tap Apply. Try CHICKEN10 for 10% off your first order!',
      ),
      _FAQ(
        'What payment methods are accepted?',
        'We accept Visa, Mastercard, ABA Pay, Wing, TrueMoney, and Cash on Delivery (COD) within Cambodia.',
      ),
      _FAQ(
        'How long does shipping take?',
        'Standard: 3-5 business days. Express: 1-2 business days within Phnom Penh and Siem Reap. Free shipping on orders over \$50!',
      ),
      _FAQ(
        'How do I contact customer support?',
        'Go to Profile → Contact Us, email support@tinychicken.com, or call +855 23 456 789. We respond within 24 hours.',
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: AppTheme.primaryColor, size: 20),
                SizedBox(width: 10),
                Text(
                  'Search help articles...',
                  style: TextStyle(color: Color(0xFF9E9EAA), fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...faqs.map((faq) => _FaqTile(faq: faq)),
        ],
      ),
    );
  }
}

class _FAQ {
  final String question;
  final String answer;
  _FAQ(this.question, this.answer);
}

class _FaqTile extends StatefulWidget {
  final _FAQ faq;
  const _FaqTile({required this.faq});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          widget.faq.question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        onExpansionChanged: (v) => setState(() => _expanded = v),
        trailing: Icon(
          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: AppTheme.primaryColor,
        ),
        children: [
          Text(
            widget.faq.answer,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
