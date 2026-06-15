import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../config/app_theme.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final themeCtrl = Get.find<ThemeController>();

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        controller: auth.scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ═══ HEADER ═══
            Container(
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
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
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
                        child: const Center(
                          child: Text('🐔', style: TextStyle(fontSize: 38)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _editProfile(context, auth),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Text(
                      auth.userName.value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Obx(
                    () => Text(
                      auth.userEmail.value,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('12', 'Orders'),
                      _stat('3', 'Pending'),
                      _stat('45', 'Points'),
                      _stat('2', 'Vouchers'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ═══ QUICK ACTIONS ═══
            Row(
              children: [
                Expanded(
                  child: _qAct(
                    context,
                    Icons.receipt_long_outlined,
                    'My Orders',
                    () => Get.toNamed(AppRoutes.orders),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.location_on_outlined,
                    'Addresses',
                    () => Get.toNamed(AppRoutes.addresses),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.credit_card_outlined,
                    'Payments',
                    () => Get.toNamed(AppRoutes.paymentMethods),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _qAct(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () => Get.toNamed(AppRoutes.settings),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ═══ MY ACCOUNT ═══
            _section(context, 'My Account', [
              _item(
                context,
                Icons.shopping_bag_outlined,
                'My Orders',
                'Track, return, or buy again',
                () => Get.toNamed(AppRoutes.orders),
                badge: const _Badge('12'),
              ),
              _item(
                context,
                Icons.card_giftcard_outlined,
                'Vouchers & Rewards',
                '2 active vouchers · 45 points',
                () {},
              ),
              _item(
                context,
                Icons.history_outlined,
                'Recently Viewed',
                'Your browsing history',
                () {},
              ),
              _item(
                context,
                Icons.share_outlined,
                'Refer & Earn',
                'Invite friends, get \$5 credit',
                () {},
              ),
            ]),

            const SizedBox(height: 12),

            // ═══ SETTINGS ═══
            _section(context, 'Settings', [
              _item(
                context,
                Icons.person_outline,
                'Edit Profile',
                'Name, email, photo',
                () => _editProfile(context, auth),
              ),
              _item(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Manage your alerts',
                () => Get.toNamed(AppRoutes.notifications),
                badge: const _Badge('3', red: true),
              ),
              _item(
                context,
                Icons.dark_mode_outlined,
                'Dark Mode',
                themeCtrl.isDarkMode.value
                    ? 'Currently enabled'
                    : 'Currently disabled',
                () => themeCtrl.toggleTheme(),
                trailing: Obx(
                  () => Switch(
                    value: themeCtrl.isDarkMode.value,
                    onChanged: (_) => themeCtrl.toggleTheme(),
                    activeTrackColor: AppTheme.primaryColor.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
              _item(
                context,
                Icons.language_outlined,
                'Language',
                'English',
                () {},
              ),
              _item(
                context,
                Icons.settings_outlined,
                'App Settings',
                'Preferences & data',
                () => Get.toNamed(AppRoutes.settings),
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
                () {},
              ),
              _item(
                context,
                Icons.info_outline,
                'About Tiny Chicken',
                'Version 1.0.0 · Build 2026',
                () {},
              ),
            ]),

            const SizedBox(height: 20),
            SizedBox(
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
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──
  Widget _stat(String val, String label) => Column(
    children: [
      Text(
        val,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ),
    ],
  );

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

  // ── Dialogs ──
  void _editProfile(BuildContext ctx, AuthController auth) {
    final nameCtrl = TextEditingController(text: auth.userName.value);
    final emailCtrl = TextEditingController(text: auth.userEmail.value);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              auth.userName.value = nameCtrl.text;
              auth.userEmail.value = emailCtrl.text;
              Get.back();
              _snack('Profile updated!', AppTheme.successColor);
            },
            child: const Text('Save'),
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
            onPressed: () {
              Get.back();
              _snack('Logged out', AppTheme.primaryColor);
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

  void _snack(String msg, Color c) => Get.snackbar(
    '',
    '',
    titleText: Text(
      msg,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    messageText: const SizedBox.shrink(),
    snackPosition: SnackPosition.TOP,
    margin: const EdgeInsets.all(12),
    borderRadius: 14,
    backgroundColor: c,
    duration: const Duration(seconds: 2),
    forwardAnimationCurve: Curves.easeOutBack,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final bool red;
  const _Badge(this.text, {this.red = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: (red ? AppTheme.errorColor : AppTheme.primaryColor).withValues(
        alpha: 0.1,
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: red ? AppTheme.errorColor : AppTheme.primaryColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
