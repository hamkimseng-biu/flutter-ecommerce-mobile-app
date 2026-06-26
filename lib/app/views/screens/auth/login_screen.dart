import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  bool _isPhone = false;
  bool _sendingCode = false;

  @override
  void initState() {
    super.initState();
    _emailOrPhoneController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _emailOrPhoneController.removeListener(_onInputChanged);
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final raw = _emailOrPhoneController.text;
    final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
    // Phone if: no @ and 3+ digits (most reliable)
    final looksLikePhone = !raw.contains('@') && digits.length >= 3;
    if (_isPhone != looksLikePhone) setState(() => _isPhone = looksLikePhone);
    // Live phone formatting with spaces
    if (looksLikePhone) {
      final formatted = _formatPhone(digits);
      if (formatted != raw) {
        final sel = _emailOrPhoneController.selection.baseOffset;
        final diff = formatted.length - raw.length;
        _emailOrPhoneController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: (sel + diff).clamp(0, formatted.length),
          ),
        );
      }
    }
  }

  String _formatPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6)
      return digits.substring(0, 3) + ' ' + digits.substring(3);
    return digits.substring(0, 3) +
        ' ' +
        digits.substring(3, 6) +
        ' ' +
        digits.substring(6);
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    final raw = _emailOrPhoneController.text.replaceAll(RegExp(r'[^\d]'), '');

    // Pure digits 8+ = phone OTP
    if (raw.length >= 8) {
      final phone = '+855${raw.startsWith('0') ? raw.substring(1) : raw}';
      // Send OTP first — only navigate on success
      setState(() => _sendingCode = true);
      final error = await auth.sendPhoneOTP(phone);
      if (mounted) setState(() => _sendingCode = false);
      if (error != null && mounted) {
        AppSnack.error('Error', error);
        return;
      }
      // Auto-verified? (e.g. Firebase test numbers)
      if (auth.isLoggedIn.value && mounted) {
        Get.offAllNamed('/main');
        return;
      }
      if (mounted) {
        Get.toNamed(
          AppRoutes.phoneOTP,
          arguments: {'phoneNumber': phone, 'isRegistration': false},
        );
      }
    } else {
      final error = await auth.signIn(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );
      if (error != null && mounted) AppSnack.error('Login Failed', error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = Get.find<AuthController>();
    final error = await auth.signInWithGoogle();
    if (error != null && mounted)
      AppSnack.error('Google Sign-In Failed', error);
  }

  void _handleForgotPassword() => Get.toNamed(AppRoutes.forgotPassword);

  void _focusPhoneField() {
    _emailOrPhoneController.clear();
    _emailFocus.requestFocus();
    setState(() => _isPhone = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Get.find<AuthController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Welcome Back!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sign in to continue.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 36),

                // Email or Phone field — always visible
                TextFormField(
                  controller: _emailOrPhoneController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  maxLength: _isPhone ? 12 : null,
                  inputFormatters: _isPhone
                      ? [LengthLimitingTextInputFormatter(12)]
                      : null,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  decoration: InputDecoration(
                    labelText: _isPhone ? 'Phone Number' : 'Email or Phone',
                    hintText: _isPhone ? '012 345 678' : 'you@example.com',
                    prefixIcon: Icon(
                      _isPhone ? Icons.phone_android : Icons.email_outlined,
                    ),
                    prefixText: _isPhone ? '+855 ' : null,
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkInputFill
                        : AppTheme.lightInputFill,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Enter email or phone number';
                    if (_isPhone &&
                        v.replaceAll(RegExp(r'[^\d]'), '').length < 8)
                      return 'Phone number too short';
                    if (!_isPhone &&
                        !GetUtils.isEmail(v.trim()) &&
                        v.replaceAll(RegExp(r'[^\d]'), '').length < 8)
                      return 'Enter a valid email or phone';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password — always visible
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
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
                    if (v == null || v.isEmpty)
                      return 'Please enter your password';
                    if (v.length < 6)
                      return 'Password must be at least 6 characters';
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

                // Sign In button — always says Sign In
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: (auth.isLoading.value || _sendingCode)
                        ? null
                        : _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: (auth.isLoading.value || _sendingCode)
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

                const SizedBox(height: 20),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                // Social icon buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialIcon(
                      onTap: auth.isLoading.value ? null : _handleGoogleSignIn,
                      asset: 'assets/logo/icons8-google-logo-96.png',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 20),
                    _socialIcon(
                      onTap: auth.isLoading.value ? null : _focusPhoneField,
                      icon: Icons.phone_android,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 20),
                    _socialIcon(
                      onTap: () {},
                      asset: 'assets/logo/Facebook-Logosu-500x281.png',
                      isDark: isDark,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
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

                // Guest
                Center(
                  child: TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.main),
                    child: const Text(
                      'Explore as Guest',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
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

  Widget _socialIcon({
    VoidCallback? onTap,
    String? asset,
    IconData? icon,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        ),
        child: Center(
          child: asset != null
              ? Image.asset(asset, width: 36, height: 36, fit: BoxFit.contain)
              : Icon(icon, size: 26, color: Colors.grey.shade700),
        ),
      ),
    );
  }
}
