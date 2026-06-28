import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/app_dialog.dart';
import '../../../services/firebase_firestore_service.dart';

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
    final createdAt = firestoreData['createdAt'] as Timestamp?;

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
                  status,
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
                  true,
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
                const Divider(height: 24),
                _row('Subtotal', '\$${total.toStringAsFixed(2)}', bold: true),
                _row('Shipping', '\$5.99'),
                const Divider(height: 24),
                _row(
                  'Total',
                  '\$${(total + 5.99).toStringAsFixed(2)}',
                  bold: true,
                  primary: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons — full-width stacked
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
    const order = ['Processing', 'Shipping', 'Delivered'];
    final curIdx = order.indexOf(current);
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
    if (step == 'Processing') return created;
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
      case 'Shipping':
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
