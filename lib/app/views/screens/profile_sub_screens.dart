import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

// ═══ ORDERS ═══
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final orders = [
      {
        'id': '#TC-2024001',
        'date': 'June 5, 2026',
        'status': 'Delivered',
        'items': 3,
        'total': 124.97,
        'icon': Icons.check_circle,
        'color': AppTheme.successColor,
      },
      {
        'id': '#TC-2024002',
        'date': 'June 7, 2026',
        'status': 'Shipping',
        'items': 1,
        'total': 49.99,
        'icon': Icons.local_shipping,
        'color': AppTheme.primaryColor,
      },
      {
        'id': '#TC-2024003',
        'date': 'June 8, 2026',
        'status': 'Processing',
        'items': 2,
        'total': 79.98,
        'icon': Icons.hourglass_top,
        'color': Colors.amber,
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No orders yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final o = orders[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
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
                      Row(
                        children: [
                          Text(
                            o['id'] as String,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (o['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  o['icon'] as IconData,
                                  size: 14,
                                  color: o['color'] as Color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  o['status'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: o['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${o['date']} · ${o['items']} items',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total: \$${(o['total'] as double).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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
}

// ═══ ADDRESSES ═══
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Shipping Addresses')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _addrCard(
            context,
            cardBg,
            'Home',
            '123 Cluck Street, Hen House District\nPhnom Penh, Cambodia',
            true,
          ),
          const SizedBox(height: 10),
          _addrCard(
            context,
            cardBg,
            'Office',
            '456 Feather Lane, Suite 200\nSiem Reap, Cambodia',
            false,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add New Address'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addrCard(
    BuildContext ctx,
    Color bg,
    String label,
    String addr,
    bool def,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: def ? AppTheme.primaryColor : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                addr,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (def)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Default',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

// ═══ PAYMENT METHODS ═══
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _pmCard(
            context,
            cardBg,
            Icons.credit_card,
            'Visa ending in 4242',
            'Expires 12/2027',
            true,
          ),
          const SizedBox(height: 10),
          _pmCard(
            context,
            cardBg,
            Icons.account_balance_wallet,
            'ABA Pay',
            'Connected',
            false,
          ),
          const SizedBox(height: 10),
          _pmCard(
            context,
            cardBg,
            Icons.payment,
            'Mastercard ending in 8888',
            'Expires 06/2026',
            false,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Payment Method'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pmCard(
    BuildContext ctx,
    Color bg,
    IconData icon,
    String title,
    String sub,
    bool def,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: def ? AppTheme.primaryColor : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
        if (def)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Default',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    ),
  );
}

// ═══ SETTINGS ═══
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        const Color(0xFF9E9EAA);
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Language', 'English', () {}, subColor),
          _tile('Currency', 'USD (\$)', () {}, subColor),
          _tile('Country / Region', 'Cambodia', () {}, subColor),
          _tile('Cache Size', '24.5 MB', () {}, subColor),
          _tile('App Version', '1.0.0', () {}, subColor),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
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

  Widget _tile(String title, String value, VoidCallback tap, Color sub) =>
      InkWell(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15)),
              Text(value, style: TextStyle(fontSize: 14, color: sub)),
            ],
          ),
        ),
      );
}

// ═══ NOTIFICATIONS ═══
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).cardColor;
    final subColor =
        Theme.of(context).textTheme.bodyMedium?.color ??
        const Color(0xFF9E9EAA);
    final notifs = [
      [
        '🎉',
        'Welcome to Tiny Chicken!',
        'Thanks for joining our flock.',
        '2 days ago',
      ],
      [
        '💰',
        'Flash Sale Alert!',
        'Your wishlist item is now 40% off!',
        '5 hours ago',
      ],
      [
        '📦',
        'Order Shipped',
        'Your order #TC-2024002 is on its way!',
        '1 day ago',
      ],
      ['⭐', 'Leave a Review', 'How was your recent purchase?', '3 days ago'],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (ctx, i) {
          final n = notifs[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n[0], style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n[1],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n[2],
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n[3],
                        style: TextStyle(fontSize: 10, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═══ HELP CENTER ═══
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});
  @override
  Widget build(BuildContext context) {
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
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Search help articles...',
                  style: TextStyle(
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...[
            'How do I track my order?',
            'What is the return policy?',
            'How do I apply a promo code?',
            'What payment methods are accepted?',
            'How long does shipping take?',
            'How do I contact customer support?',
          ].map(
            (q) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(q, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF9E9EAA),
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
