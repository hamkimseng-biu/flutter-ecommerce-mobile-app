import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_constants.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/kh_phone_util.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Get.find<AuthController>();
    final error = await auth.signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (error != null && mounted) {
      AppSnack.error('Login Failed', error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = Get.find<AuthController>();
    final error = await auth.signInWithGoogle();

    if (error != null && mounted) {
      AppSnack.error('Google Sign-In Failed', error);
    }
  }

  void _handleForgotPassword() {
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void _handlePhoneSignIn(BuildContext context) {
    final phoneCtrl = TextEditingController();
    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Phone Sign In',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your phone number to receive a verification code.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9EAA)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '012 345 678',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final digits = phoneCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
                if (digits.length < 8) {
                  AppSnack.error('Invalid', 'Enter a valid phone number.');
                  return;
                }
                Get.back();
                final e164 = KhPhoneUtil.toE164(digits);
                final auth = Get.find<AuthController>();
                final error = await auth.sendPhoneOTP(e164);
                if (error != null) {
                  AppSnack.error('Error', error);
                  return;
                }
                if (auth.isLoggedIn.value) return;
                _showOTPDialog(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Send Code'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOTPDialog(BuildContext context) {
    final otpCtrl = TextEditingController();
    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Verify Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the 6-digit code sent to your phone.',
                style: TextStyle(fontSize: 13, color: Color(0xFF9E9EAA)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: '000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final code = otpCtrl.text.trim();
                if (code.length != 6) {
                  AppSnack.error('Invalid', 'Enter the 6-digit code.');
                  return;
                }
                Get.back();
                final auth = Get.find<AuthController>();
                final error = await auth.verifyPhoneOTP(code);
                if (error != null) {
                  AppSnack.error('Error', error);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo & App Name
                Center(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/icon.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkInputFill
                        : AppTheme.lightInputFill,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(v.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkInputFill
                        : AppTheme.lightInputFill,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _handleForgotPassword,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Login Button
                GetBuilder<AuthController>(
                  builder: (auth) => SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.isLoading.value ? null : _handleLogin,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading.value
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Google Sign In Button
                GetBuilder<AuthController>(
                  builder: (auth) => SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading.value
                          ? null
                          : _handleGoogleSignIn,
                      icon: SizedBox(
                        width: 22,
                        height: 22,
                        child: Image.asset(
                          'assets/logo/icons8-google-logo-96.png',
                        ),
                      ),
                      label: const Text(
                        'Sign in with Google',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Phone Sign In Button
                GetBuilder<AuthController>(
                  builder: (auth) => SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading.value
                          ? null
                          : () => _handlePhoneSignIn(context),
                      icon: const Icon(Icons.phone_android, size: 22),
                      label: const Text(
                        'Sign in with Phone',
                        style: TextStyle(fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.register),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Explore as Guest
                Center(
                  child: TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.main),
                    child: Text(
                      'Explore as Guest',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: isDark
                            ? Colors.white54
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
