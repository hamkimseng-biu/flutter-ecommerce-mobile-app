import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/firebase_firestore_service.dart';
import '../../../config/app_dialog.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _orderCount = 0;
  int _followingCount = 0;
  int _wishlistCount = 0;
  final FirebaseFirestoreService _fs = FirebaseFirestoreService();

  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _followedSub;
  StreamSubscription<List<String>>? _wishlistSub;

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
    // Re-subscribe when user logs in/out so stats switch to the right user
    FirebaseAuth.instance.authStateChanges().listen((_) {
      _cancelSubs();
      _subscribeToStreams();
    });
  }

  void _subscribeToStreams() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted)
        setState(() {
          _orderCount = 0;
          _followingCount = 0;
          _wishlistCount = 0;
        });
      return;
    }

    // Orders count — real-time
    _ordersSub = _fs.getOrdersStream().listen((snap) {
      if (mounted) setState(() => _orderCount = snap.docs.length);
    });

    // Followed shops count — real-time
    _followedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followed_shops')
        .snapshots()
        .listen((snap) {
          if (mounted) setState(() => _followingCount = snap.docs.length);
        });

    // Wishlist count — real-time
    _wishlistSub = _fs.getWishlistStream().listen((ids) {
      if (mounted) setState(() => _wishlistCount = ids.length);
    });
  }

  void _cancelSubs() {
    _ordersSub?.cancel();
    _followedSub?.cancel();
    _wishlistSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }

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
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7B3D), Color(0xFFFFA940)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF7B3D).withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: loggedIn
                              ? () => Get.toNamed(AppRoutes.editProfile)
                              : null,
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child:
                                      loggedIn &&
                                          auth.userPhotoURL.value.isNotEmpty
                                      ? Image.network(
                                          auth.userPhotoURL.value,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                                'assets/logo/Chicken Logo.png',
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                      : Image.asset(
                                          'assets/logo/Chicken Logo.png',
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              if (loggedIn)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Color(0xFFFF7B3D),
                                      size: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name + email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loggedIn && auth.userName.value.isNotEmpty
                                    ? auth.userName.value
                                    : 'Welcome!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loggedIn
                                    ? auth.userEmail.value
                                    : 'Sign in to unlock all features',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.80),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (loggedIn) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _stat('$_orderCount', 'Orders'),
                            _stat('$_followingCount', 'Following'),
                            _stat('$_wishlistCount', 'Wishlist'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // ═══ QUICK ACTIONS ═══
            Row(
              children: [
                Expanded(
                  child: _qAct(
                    context,
                    Icons.receipt_long_rounded,
                    'Orders',
                    const Color(0xFF6366F1),
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view your orders.',
                        )
                        ? Get.toNamed(AppRoutes.orders)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.location_on_rounded,
                    'Address',
                    const Color(0xFF10B981),
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to manage addresses.',
                        )
                        ? Get.toNamed(AppRoutes.addresses)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.credit_card_rounded,
                    'Payments',
                    const Color(0xFFF59E0B),
                    () =>
                        auth.requireAuth(message: 'Sign in to manage payments.')
                        ? Get.toNamed(AppRoutes.paymentMethods)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _qAct(
                    context,
                    Icons.schedule_rounded,
                    'History',
                    const Color(0xFF8B5CF6),
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view your history.',
                        )
                        ? Get.toNamed(AppRoutes.shopperHistory)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.storefront_rounded,
                    'Following',
                    const Color(0xFFEC4899),
                    () =>
                        auth.requireAuth(
                          message: 'Sign in to view followed shops.',
                        )
                        ? Get.toNamed(AppRoutes.followedShops)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.settings_rounded,
                    'Settings',
                    const Color(0xFF6B7280),
                    () =>
                        auth.requireAuth(message: 'Sign in to access settings.')
                        ? Get.toNamed(AppRoutes.settings)
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ═══ ACCOUNT ═══
            _section(context, 'Account', [
              _item(
                context,
                Icons.person_rounded,
                'Edit Profile',
                'Name, photo, phone number',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.editProfile)
                    : null,
                iconColor: const Color(0xFF6366F1),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.receipt_long_rounded,
                'Shopping History',
                'Viewed, carted, bought & reviewed',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.shopperHistory)
                    : null,
                iconColor: const Color(0xFF8B5CF6),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.storefront_rounded,
                'Followed Shops',
                'Shops you follow',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.followedShops)
                    : null,
                iconColor: const Color(0xFFEC4899),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.emoji_events_rounded,
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
                iconColor: const Color(0xFFF59E0B),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.share_rounded,
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
                iconColor: AppTheme.successColor,
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.notifications_active_rounded,
                'Notifications',
                'Manage your alerts',
                () => auth.requireAuth()
                    ? Get.toNamed(AppRoutes.notifications)
                    : null,
                iconColor: const Color(0xFFEF4444),
              ),
            ]),

            const SizedBox(height: 16),

            // ═══ SUPPORT ═══
            _section(context, 'Support', [
              _item(
                context,
                Icons.help_rounded,
                'Help Center',
                'FAQs & guides',
                () => Get.toNamed(AppRoutes.helpCenter),
                iconColor: const Color(0xFF3B82F6),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.headset_mic_rounded,
                'Contact Us',
                "We're here 24/7",
                () => _showContactDialog(context),
                iconColor: const Color(0xFF10B981),
              ),
              _sectionDivider(context),
              _item(
                context,
                Icons.info_rounded,
                'About Tiny Chicken',
                'Version 1.0.0 · Build 2026',
                () => _showAboutDialog(context),
                iconColor: const Color(0xFF6B7280),
              ),
            ]),

            const SizedBox(height: 24),
            Obx(() {
              if (auth.isLoggedIn.value) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(
                          color: AppTheme.errorColor.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: AppTheme.errorColor.withValues(
                          alpha: 0.04,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Get.toNamed(AppRoutes.login),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF7B3D),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFF7B3D),
                          side: BorderSide(
                            color: const Color(
                              0xFFFF7B3D,
                            ).withValues(alpha: 0.3),
                          ),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──
  Widget _stat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.white.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );

  Widget _sectionDivider(BuildContext ctx) => Divider(
    height: 1,
    indent: 72,
    endIndent: 18,
    color: Theme.of(ctx).dividerColor.withValues(alpha: 0.4),
  );

  Widget _qAct(
    BuildContext ctx,
    IconData icon,
    String label,
    Color color,
    VoidCallback tap,
  ) => GestureDetector(
    onTap: tap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );

  Widget _section(BuildContext ctx, String title, List<Widget> items) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primaryColor;
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[const SizedBox(width: 8), badge],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9EAA),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFC0C0C0),
            ),
          ],
        ),
      ),
    );
  }

  // ── Support Dialogs ──
  void _showContactDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.headset_mic_rounded, color: Color(0xFF10B981), size: 24),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  'assets/logo/Chicken Logo.png',
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: AppTheme.successColor, size: 24),
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              AppSnack.success('Copied!', 'Referral code copied to clipboard.');
              Navigator.of(context).pop();
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
    AppDialog.confirm(
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      confirmColor: AppTheme.errorColor,
    ).then((confirmed) {
      if (confirmed != true) return;
      final auth = Get.find<AuthController>();
      auth.logout().then((_) => Get.offAllNamed(AppRoutes.login));
    });
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
