import 'package:get/get.dart';
import '../views/screens/auth/splash_screen.dart';
import '../views/screens/home/main_screen.dart';
import '../views/screens/auth/login_screen.dart';
import '../views/screens/auth/register_screen.dart';
import '../views/screens/auth/phone_otp_screen.dart';
import '../views/screens/profile/edit_profile_screen.dart';
import '../views/screens/order/order_detail_screen.dart';
import '../views/screens/admin/admin_products_screen.dart';

import '../views/screens/shop/shop_screen.dart';
import '../views/screens/product/product_detail_screen.dart';
import '../views/screens/product/all_reviews_screen.dart';
import '../views/screens/cart/cart_screen.dart';
import '../views/screens/checkout/checkout_screen.dart';
import '../views/screens/profile/profile_screen.dart';
import '../views/screens/home/search_screen.dart';
import '../views/screens/wishlist/wishlist_screen.dart';
import '../views/screens/profile/profile_sub_screens.dart';
import '../views/screens/profile/add_edit_address_screen.dart';
import '../views/screens/profile/add_edit_card_screen.dart';
import '../views/screens/profile/shopper_history_screen.dart';
import '../views/screens/profile/followed_shops_screen.dart';
import '../views/screens/home/flash_sales_screen.dart';
import '../views/screens/home/popular_shops_screen.dart';
import '../views/screens/admin/add_edit_product_screen.dart';
import '../views/screens/admin/add_edit_shop_screen.dart';
import '../views/screens/profile/add_edit_bank_screen.dart';
import '../views/screens/forgot_password_screen.dart';
import '../controllers/theme_controller.dart';
import '../controllers/currency_controller.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String shop = '/shop';
  static const String productDetail = '/product-detail';
  static const String allReviews = '/all-reviews';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String orderDetail = '/order-detail';
  static const String search = '/search';
  static const String wishlist = '/wishlist';
  static const String orders = '/orders';
  static const String addresses = '/addresses';
  static const String addEditAddress = '/add-edit-address';
  static const String paymentMethods = '/payment-methods';
  static const String addCard = '/add-card';
  static const String addBank = '/add-bank';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String helpCenter = '/help-center';
  static const String shopperHistory = '/shopper-history';
  static const String followedShops = '/followed-shops';
  static const String adminProducts = '/admin-products';
  static const String addEditProduct = '/add-edit-product';
  static const String addEditShop = '/add-edit-shop';
  static const String flashSales = '/flash-sales';
  static const String popularShops = '/popular-shops';

  static const String phoneOTP = '/phone-otp';

  static List<GetPage> pages = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: forgotPassword,
      page: () => const ForgotPasswordScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: phoneOTP,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return PhoneOTPScreen(
          phoneNumber: args['phoneNumber'] as String,
          isRegistration: args['isRegistration'] as bool? ?? false,
        );
      },
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: main,
      page: () => const MainScreen(),
      transition: Transition.fadeIn,
      binding: BindingsBuilder(() {
        Get.put(ThemeController(), permanent: true);
        Get.put(CurrencyController(), permanent: true);
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
      name: allReviews,
      page: () {
        final args = Get.arguments as Map<String, String>;
        return AllReviewsScreen(
          productId: args['productId']!,
          productName: args['productName']!,
        );
      },
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
      name: editProfile,
      page: () => const EditProfileScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: orderDetail,
      page: () => const OrderDetailScreen(),
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
      name: addEditAddress,
      page: () => const AddEditAddressScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: paymentMethods,
      page: () => const PaymentMethodsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: addCard,
      page: () => const AddEditCardScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: addBank,
      page: () => const AddEditBankScreen(),
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
    GetPage(
      name: shopperHistory,
      page: () => const ShopperHistoryScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: followedShops,
      page: () => const FollowedShopsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: adminProducts,
      page: () => const AdminProductsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: addEditProduct,
      page: () => const AddEditProductScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: addEditShop,
      page: () => const AddEditShopScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: flashSales,
      page: () => const FlashSalesScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: popularShops,
      page: () => const PopularShopsScreen(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
