import 'package:get/get.dart';
import '../views/screens/splash_screen.dart';
import '../views/screens/main_screen.dart';

import '../views/screens/shop_screen.dart';
import '../views/screens/product_detail_screen.dart';
import '../views/screens/cart_screen.dart';
import '../views/screens/checkout_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/search_screen.dart';
import '../views/screens/wishlist_screen.dart';
import '../views/screens/profile_sub_screens.dart';
import '../controllers/theme_controller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String main = '/main';
  static const String home = '/home';
  static const String shop = '/shop';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String wishlist = '/wishlist';
  static const String orders = '/orders';
  static const String addresses = '/addresses';
  static const String paymentMethods = '/payment-methods';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String helpCenter = '/help-center';

  static List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: main,
      page: () => const MainScreen(),
      transition: Transition.fadeIn,
      binding: BindingsBuilder(() {
        Get.put(ThemeController(), permanent: true);
      }),
    ),
    GetPage(
      name: shop,
      page: () => const ShopScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: productDetail,
      page: () => const ProductDetailScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: cart,
      page: () => const CartScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: checkout,
      page: () => const CheckoutScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: profile,
      page: () => const ProfileScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: wishlist,
      page: () => const WishlistScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: orders,
      page: () => const OrdersScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: addresses,
      page: () => const AddressesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: paymentMethods,
      page: () => const PaymentMethodsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: helpCenter,
      page: () => const HelpCenterScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
