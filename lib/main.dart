import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';
import 'app/controllers/product_controller.dart';
import 'app/controllers/cart_controller.dart';
import 'app/controllers/wishlist_controller.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/home_controller.dart';
import 'app/routes/app_routes.dart';
import 'app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // App Check — debug provider for development,
  // SafetyNet/Play Integrity for release builds
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  // Init FCM (push notifications) — non-blocking
  FcmService().initialize();

  // ThemeController must be initialized before runApp since
  // TinyChickenApp.build() calls Get.find<ThemeController>()
  Get.put(ThemeController(), permanent: true);
  runApp(const TinyChickenApp());
}

class TinyChickenApp extends StatelessWidget {
  const TinyChickenApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCtrl = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeCtrl.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('km')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.pages,
        initialBinding: InitialBindings(),
        defaultTransition: Transition.fadeIn,
      ),
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
    // ThemeController initialized in main() above
    Get.put(HomeController(), permanent: true);
  }
}
