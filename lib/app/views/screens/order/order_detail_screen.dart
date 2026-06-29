import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/app_dialog.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../controllers/product_controller.dart';
import '../../../routes/app_routes.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final order = Get.arguments as Map<String, dynamic>;
    final firestoreId = order['firestoreId'] as String?;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(order['id'] as String)),
      body: firestoreId != null && uid.isNotEmpty
          ? StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('orders')
                  .doc(firestoreId)
                  .snapshots(),
              builder: (ctx, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildStatic(context, order);
                }
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return _buildContent(context, order, data, firestoreId);
              },
            )
          : _buildStatic(context, order),
    );
  }

  Widget _buildStatic(BuildContext context, Map<String, dynamic> order) {
    return _buildContent(context, order, {
      'status': order['status'] ?? 'Processing',
      'total': order['total'] ?? 0.0,
      'createdAt': null,
    }, null);
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> order,
    Map<String, dynamic> firestoreData,
    String? firestoreId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = Theme.of(context).cardColor;
    final status =
        firestoreData['status'] as String? ?? order['status'] as String;
    final displayStatus = status == 'Shipping' ? 'In Transit' : status;
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final date = order['date'] as String? ?? '';
    final rawItems = order['items'];
    final itemCount = rawItems is List
        ? rawItems.length
        : (rawItems as int? ?? 0);
    final total =
        (firestoreData['total'] as num?)?.toDouble() ??
        (order['total'] as num?)?.toDouble() ??
        0.0;
    final subtotal =
        (firestoreData['subtotal'] as num?)?.toDouble() ?? total * 0.9;
    final shipping = (firestoreData['shipping'] as num?)?.toDouble() ?? 5.99;
    final tax =
        (firestoreData['tax'] as num?)?.toDouble() ??
        (total * 0.05).roundToDouble().toDouble();
    final discount = (firestoreData['discount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = firestoreData['createdAt'] as Timestamp?;
    final shippingAddress =
        firestoreData['shippingAddress'] as Map<String, dynamic>?;
    final paymentMethod = firestoreData['paymentMethod'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: 10),
                Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date · $itemCount items',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tracking timeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Tracking',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _step(
                  Icons.receipt_long,
                  'Order Placed',
                  'Your order has been confirmed',
                  true,
                  false,
                  createdAt,
                ),
                _step(
                  Icons.inventory,
                  'Processing',
                  'We are preparing your items',
                  _stepDone(status, 'Processing'),
                  _stepActive(status, 'Processing'),
                  _stepTime(status, 'Processing', createdAt, 2),
                ),
                _step(
                  Icons.local_shipping,
                  'Shipped',
                  'Package is on the way',
                  _stepDone(status, 'Shipping'),
                  _stepActive(status, 'Shipping'),
                  _stepTime(status, 'Shipping', createdAt, 12),
                ),
                _step(
                  Icons.delivery_dining,
                  'Out for Delivery',
                  'Courier is delivering your package',
                  status == 'On Delivery' || status == 'Delivered',
                  status == 'On Delivery',
                  status == 'On Delivery' || status == 'Delivered'
                      ? _stepTime(status, 'On Delivery', createdAt, 24)
                      : null,
                ),
                _step(
                  Icons.check_circle,
                  'Delivered',
                  'Package delivered successfully',
                  status == 'Delivered',
                  status == 'Delivered',
                  status == 'Delivered' ? createdAt : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Order info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Order Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _row('Order ID', order['id'] as String),
                _row('Date', date),
                _row('Items', '$itemCount items'),
                if (paymentMethod != null) _row('Payment', paymentMethod),
                const Divider(height: 24),
                _row('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                _row('Shipping', '\$${shipping.toStringAsFixed(2)}'),
                _row('Tax', '\$${tax.toStringAsFixed(2)}'),
                if (discount > 0)
                  _row('Discount', '-\$${discount.toStringAsFixed(2)}'),
                const Divider(height: 24),
                _row(
                  'Total',
                  '\$${total.toStringAsFixed(2)}',
                  bold: true,
                  primary: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shipping address
          if (shippingAddress != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Shipping Address',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${shippingAddress['recipient'] ?? ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shippingAddress['street'] ?? ''}, ${shippingAddress['city'] ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${shippingAddress['province'] ?? ''} ${shippingAddress['zip'] ?? ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '${shippingAddress['phone'] ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Items list
          if (rawItems is List && rawItems.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...rawItems.map((item) {
                    if (item is! Map) return const SizedBox.shrink();
                    final name = item['name'] ?? item['title'] ?? 'Product';
                    final qty = item['qty'] ?? 1;
                    final price = (item['price'] ?? 0.0).toDouble();
                    final image = item['image'] as String? ?? '';
                    final productId = (item['productId'] as String?) ?? '';

                    // Live image fallback
                    String displayImage = image;
                    if (productId.isNotEmpty) {
                      try {
                        final pc = Get.find<ProductController>();
                        final product = pc.getProductById(productId);
                        if (product != null && product.images.isNotEmpty) {
                          displayImage = product.images[0];
                        }
                      } catch (_) {}
                    }

                    return GestureDetector(
                      onTap: () {
                        if (productId.isNotEmpty) {
                          final pc = Get.find<ProductController>();
                          final product = pc.getProductById(productId);
                          if (product != null) {
                            Get.toNamed(
                              AppRoutes.productDetail,
                              arguments: product,
                            );
                            return;
                          }
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 48,
                                height: 48,
                                color: isDark
                                    ? AppTheme.darkSurface2
                                    : const Color(0xFFF1F3F5),
                                child:
                                    displayImage.isNotEmpty &&
                                        displayImage.startsWith('http')
                                    ? Image.network(
                                        displayImage,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(
                                              Icons.image_outlined,
                                              size: 24,
                                              color: Colors.grey,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.image_outlined,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'x$qty',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '\$${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Continue Shopping'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (status == 'Processing') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelOrder(
                  context,
                  firestoreId ?? order['firestoreId'] as String?,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Cancel Order'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AppSnack.info(
                'Support',
                'Our support team will assist you shortly.',
              ),
              icon: const Icon(Icons.headset_mic_outlined, size: 18),
              label: const Text('Need Help?'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  bool _stepDone(String current, String step) {
    const order = ['Processing', 'Shipping', 'On Delivery', 'Delivered'];
    final curIdx = order.indexOf(current);
    if (curIdx == -1) return step == 'Processing';
    final stepIdx = order.indexOf(step);
    return stepIdx <= curIdx;
  }

  bool _stepActive(String current, String step) {
    return current == step;
  }

  Timestamp? _stepTime(
    String current,
    String step,
    Timestamp? created,
    int hoursOffset,
  ) {
    if (!_stepDone(current, step)) return null;
    if (created == null) return null;
    return Timestamp.fromDate(
      created.toDate().add(Duration(hours: hoursOffset)),
    );
  }

  String _fmtTime(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    return '${d.day} ${_month(d.month)}, ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _month(int m) {
    const mons = [
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
    return mons[m - 1];
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return AppTheme.successColor;
      case 'On Delivery':
      case 'Shipping':
      case 'In Transit':
        return AppTheme.primaryColor;
      case 'Processing':
        return Colors.amber;
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
      default:
        return Icons.schedule;
    }
  }

  Widget _step(
    IconData icon,
    String title,
    String subtitle,
    bool completed,
    bool active,
    Timestamp? time,
  ) {
    final timeStr = time != null && completed ? _fmtTime(time) : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryColor
                    : completed
                    ? AppTheme.primaryColor.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active
                    ? Colors.white
                    : (completed ? AppTheme.primaryColor : Colors.grey),
                size: 20,
              ),
            ),
            Container(
              width: 2,
              height: timeStr.isNotEmpty ? 48 : 40,
              color: completed
                  ? AppTheme.primaryColor.withValues(alpha: 0.3)
                  : Colors.grey.shade200,
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: timeStr.isNotEmpty ? 32 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: completed ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: completed ? const Color(0xFF9E9EAA) : Colors.grey,
                  ),
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    bool primary = false,
  }) {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: primary ? AppTheme.primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context, String? firestoreId) {
    if (firestoreId == null) return;
    AppDialog.confirm(
      title: 'Cancel Order',
      message: 'Are you sure you want to cancel this order?',
      confirmLabel: 'Yes, Cancel',
      confirmColor: AppTheme.errorColor,
    ).then((confirmed) {
      if (confirmed != true) return;
      FirebaseFirestoreService()
          .cancelOrder(firestoreId)
          .then((_) {
            AppSnack.success('Cancelled', 'Your order has been cancelled.');
          })
          .catchError((_) {
            AppSnack.error('Error', 'Could not cancel order. Try again.');
          });
    });
  }
}
