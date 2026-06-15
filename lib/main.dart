import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';
import 'app/controllers/product_controller.dart';
import 'app/controllers/cart_controller.dart';
import 'app/controllers/wishlist_controller.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/home_controller.dart';
import 'app/routes/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TinyChickenApp());
}

class TinyChickenApp extends StatelessWidget {
  const TinyChickenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      initialBinding: InitialBindings(),
      defaultTransition: Transition.fadeIn,
    );
  }
}

class InitialBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(ProductController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(WishlistController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(HomeController(), permanent: true);
  }
}
