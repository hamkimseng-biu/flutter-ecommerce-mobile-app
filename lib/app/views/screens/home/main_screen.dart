import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/cart_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../controllers/wishlist_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../../../config/app_theme.dart';
import 'home_screen.dart';
import '../wishlist/wishlist_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCtrl = Get.find<CartController>();
    final homeCtrl = Get.find<HomeController>();
    final RxInt currentIndex = 0.obs;
    final screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    return Obx(
      () => Scaffold(
        body: IndexedStack(index: currentIndex.value, children: screens),
        bottomNavigationBar: Container(
          height: 64 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(
                Icons.home_rounded,
                Icons.home_outlined,
                'Home',
                0,
                currentIndex,
                () {
                  if (currentIndex.value == 0)
                    homeCtrl.scrollToTop();
                  else
                    currentIndex.value = 0;
                },
              ),
              _nav(
                Icons.favorite_rounded,
                Icons.favorite_border_rounded,
                'Wishlist',
                1,
                currentIndex,
                () {
                  if (currentIndex.value == 1)
                    Get.find<WishlistController>().scrollToTop();
                  else
                    currentIndex.value = 1;
                },
              ),
              _navBadge(
                Icons.shopping_bag_rounded,
                Icons.shopping_bag_outlined,
                'Cart',
                2,
                currentIndex,
                cartCtrl,
                () {
                  if (currentIndex.value == 2)
                    cartCtrl.scrollToTop();
                  else
                    currentIndex.value = 2;
                },
              ),
              _nav(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
                3,
                currentIndex,
                () {
                  if (currentIndex.value == 3)
                    Get.find<AuthController>().scrollToTop();
                  else
                    currentIndex.value = 3;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(
    IconData a,
    IconData i,
    String l,
    int idx,
    RxInt cur,
    VoidCallback t,
  ) => GestureDetector(
    onTap: t,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 72,
      child: Obx(() {
        final s = cur.value == idx;
        final color = s ? AppTheme.primaryColor : const Color(0xFF9E9EAA);
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Icon(s ? a : i, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              l,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: s ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      }),
    ),
  );

  Widget _navBadge(
    IconData a,
    IconData i,
    String l,
    int idx,
    RxInt cur,
    CartController cc,
    VoidCallback t,
  ) => GestureDetector(
    onTap: t,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      width: 72,
      child: Obx(() {
        final s = cur.value == idx;
        final color = s ? AppTheme.primaryColor : const Color(0xFF9E9EAA);
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 6),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(s ? a : i, color: color, size: 24),
                Obx(() {
                  if (cc.selectedCount > 0)
                    return Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${cc.selectedCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: s ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
          ],
        );
      }),
    ),
  );
}
