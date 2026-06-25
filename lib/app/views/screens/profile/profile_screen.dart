import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: auth.scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ═══ HEADER ═══
            Obx(() {
              final loggedIn = auth.isLoggedIn.value;
              return Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: loggedIn
                          ? () => Get.toNamed(AppRoutes.editProfile)
                          : null,
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child:
                                  loggedIn && auth.userPhotoURL.value.isNotEmpty
                                  ? Image.network(
                                      auth.userPhotoURL.value,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/icon.png',
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/icon.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          if (loggedIn)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      loggedIn && auth.userName.value.isNotEmpty
                          ? auth.userName.value
                          : 'Welcome!',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loggedIn
                          ? auth.userEmail.value
                          : 'Sign in to unlock all features',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // ═══ QUICK ACTIONS ═══
            Row(
              children: [
                Expanded(
                  child: _qAct(
                    context,
                    Icons.receipt_long_outlined,
                    'Orders',
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view your orders.',
                        )
                        ? Get.toNamed(AppRoutes.orders)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to manage addresses.',
                        )
                        ? Get.toNamed(AppRoutes.addresses)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.credit_card_outlined,
                    'Payments',
                    () =>
                        auth.requireAuth(message: 'Sign in to manage payments.')
                        ? Get.toNamed(AppRoutes.paymentMethods)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _qAct(
                    context,
                    Icons.history_rounded,
                    'History',
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view your history.',
                        )
                        ? Get.toNamed(AppRoutes.shopperHistory)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.store_rounded,
                    'Following',
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view followed shops.',
                        )
                        ? Get.toNamed(AppRoutes.followedShops)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () =>
                        auth.requireAuth(message: 'Sign in to access settings.')
                        ? Get.toNamed(AppRoutes.settings)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ═══ ACCOUNT ═══
            _section(context, 'Account', [
              _item(
                context,
                Icons.person_outline,
                'Edit Profile',
                'Name, photo, phone number',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.editProfile)
                    : null,
              ),
              _item(
                context,
                Icons.history_rounded,
                'Shopping History',
                'Viewed, carted, bought & reviewed',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.shopperHistory)
                    : null,
              ),
              _item(
                context,
                Icons.store_rounded,
                'Followed Shops',
                'Shops you follow',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.followedShops)
                    : null,
              ),
              _item(
                context,
                Icons.card_giftcard_outlined,
                'Loyalty Points',
                'Earn 1 point per \$1 spent',
                () {
                  if (!auth.requireAuth()) return;
                  AppSnack.info(
                    'Coming Soon',
                    'Loyalty rewards coming in the next update!',
                  );
                },
                badge: _buildPointsBadge(context),
              ),
              _item(
                context,
                Icons.share_outlined,
                'Refer & Earn',
                'Invite friends, get \$5 credit',
                () {
                  if (!auth.requireAuth()) return;
                  _showReferralDialog(context);
                },
                badge: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CHICKEN10',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ),
              _item(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Manage your alerts',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.notifications)
                    : null,
              ),
            ]),

            const SizedBox(height: 12),

            // ═══ SUPPORT ═══
            _section(context, 'Support', [
              _item(
                context,
                Icons.help_outline,
                'Help Center',
                'FAQs & guides',
                () => Get.toNamed(AppRoutes.helpCenter),
              ),
              _item(
                context,
                Icons.chat_bubble_outline,
                'Contact Us',
                "We're here 24/7",
                () => _showContactDialog(context),
              ),
              _item(
                context,
                Icons.info_outline,
                'About Tiny Chicken',
                'Version 1.0.0 · Build 2026',
                () => _showAboutDialog(context),
              ),
            ]),

            const SizedBox(height: 20),
            Obx(() {
              if (auth.isLoggedIn.value) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Log Out', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.toNamed(AppRoutes.register),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──
  Widget _qAct(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback tap,
  ) => GestureDetector(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );

  Widget _section(BuildContext ctx, String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(ctx).textTheme.bodyMedium?.color,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
            ),
          ],
        ),
        child: Column(children: items),
      ),
    ],
  );

  Widget _item(
    BuildContext ctx,
    IconData icon,
    String title,
    String sub,
    VoidCallback tap, {
    Widget? trailing,
    Widget? badge,
  }) => InkWell(
    onTap: tap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badge != null) ...[const SizedBox(width: 6), badge],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(ctx).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF9E9EAA),
              ),
        ],
      ),
    ),
  );

  // ── Support Dialogs ──
  void _showContactDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We\'re here to help! Reach us through:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            _ContactRow(
              Icons.email_outlined,
              'Email',
              'support@tinychicken.com',
            ),
            SizedBox(height: 10),
            _ContactRow(Icons.phone_outlined, 'Phone', '+855 23 456 789'),
            SizedBox(height: 10),
            _ContactRow(Icons.access_time, 'Hours', 'Mon–Sat, 8AM–8PM'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              AppSnack.success(
                'Message Sent',
                "We'll get back to you within 24 hours.",
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Send Message',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tiny Chicken',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Small prices, big style!',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9EAA)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0 (Build 2026)\n\n'
              'Tiny Chicken is your one-stop shop for trendy fashion, electronics, and lifestyle products at unbeatable prices.\n\n'
              'Made with ❤️ in Cambodia',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildPointsBadge(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        '125 pts',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.secondaryColor,
        ),
      ),
    );
  }

  void _showReferralDialog(BuildContext ctx) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.share_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text(
              'Refer & Earn',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share your referral code and earn!',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  'CHICKEN10',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You get \$5 credit. Your friend gets 10% off their first order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF9E9EAA)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              AppSnack.success('Copied!', 'Referral code copied to clipboard.');
              Get.back();
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext ctx) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Color(0xFF9E9EAA)),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final auth = Get.find<AuthController>();
              await auth.logout();
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
