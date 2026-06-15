import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/wishlist_controller.dart';
import '../../controllers/auth_controller.dart';
import 'home_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartCtrl = Get.find<CartController>();
    final homeCtrl = Get.find<HomeController>();
    final RxInt currentIndex = 0.obs;
    final bottomPad = MediaQuery.of(context).padding.bottom;
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
          height: 60 + bottomPad,
          padding: EdgeInsets.only(bottom: bottomPad),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
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
                  if (currentIndex.value == 0) {
                    homeCtrl.scrollToTop();
                  } else {
                    currentIndex.value = 0;
                  }
                },
              ),
              _nav(
                Icons.favorite_rounded,
                Icons.favorite_border_rounded,
                'Wishlist',
                1,
                currentIndex,
                () {
                  if (currentIndex.value == 1) {
                    Get.find<WishlistController>().scrollToTop();
                  } else {
                    currentIndex.value = 1;
                  }
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
                  if (currentIndex.value == 2) {
                    cartCtrl.scrollToTop();
                  } else {
                    currentIndex.value = 2;
                  }
                },
              ),
              _nav(
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
                3,
                currentIndex,
                () {
                  if (currentIndex.value == 3) {
                    Get.find<AuthController>().scrollToTop();
                  } else {
                    currentIndex.value = 3;
                  }
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
    child: Obx(() {
      final s = cur.value == idx;
      return TweenAnimationBuilder<double>(
        tween: Tween(end: s ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (ctx, v, _) => Transform.scale(
          scale: 1.0 + (v * 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: s
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  s ? a : i,
                  color: s ? const Color(0xFFFF6B35) : const Color(0xFF9E9EAA),
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  l,
                  style: TextStyle(
                    color: s
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF9E9EAA),
                    fontSize: 10,
                    fontWeight: s ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
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
    child: Obx(() {
      final s = cur.value == idx;
      return TweenAnimationBuilder<double>(
        tween: Tween(end: s ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (ctx, v, _) => Transform.scale(
          scale: 1.0 + (v * 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: s
                  ? const Color(0xFFFF6B35).withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      s ? a : i,
                      color: s
                          ? const Color(0xFFFF6B35)
                          : const Color(0xFF9E9EAA),
                      size: 22,
                    ),
                    if (cc.itemCount > 0)
                      Positioned(
                        right: -8,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${cc.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  l,
                  style: TextStyle(
                    color: s
                        ? const Color(0xFFFF6B35)
                        : const Color(0xFF9E9EAA),
                    fontSize: 10,
                    fontWeight: s ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }),
  );
}
