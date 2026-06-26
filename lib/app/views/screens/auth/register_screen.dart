import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _nameController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // Check directly — never stale
  bool _isPhoneInput() {
    final raw = _emailOrPhoneController.text;
    return !raw.contains('@') &&
        raw.replaceAll(RegExp(r'[^\d]'), '').isNotEmpty;
  }

  void _onInputChanged() {
    if (!_isPhoneInput()) {
      if (_isPhone) setState(() => _isPhone = false);
      return;
    }
    if (!_isPhone) setState(() => _isPhone = true);
    final digits = _emailOrPhoneController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final formatted = _formatPhone(digits);
    if (_emailOrPhoneController.text != formatted) {
      final sel = _emailOrPhoneController.selection.baseOffset;
      final diff = formatted.length - _emailOrPhoneController.text.length;
      _emailOrPhoneController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: (sel + diff).clamp(0, formatted.length),
        ),
      );
    }
  }

  String _formatPhone(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6)
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Get.find<AuthController>();
    final raw = _emailOrPhoneController.text.replaceAll(RegExp(r'[^\d]'), '');

    // Pure digits 8+ = phone OTP flow
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
          arguments: {'phoneNumber': phone, 'isRegistration': true},
        );
      }
    } else {
      final error = await auth.signUp(
        _nameController.text.trim(),
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );
      if (error != null && mounted)
        AppSnack.error('Registration Failed', error);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = Get.find<AuthController>();
    final error = await auth.signInWithGoogle();
    if (error != null && mounted)
      AppSnack.error('Google Sign-In Failed', error);
  }

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
                const SizedBox(height: 36),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_add_outlined,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Create Account',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Sign up to get started.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppTheme.darkInputFill
                        : AppTheme.lightInputFill,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailOrPhoneController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: _isPhone ? 'Phone Number' : 'Email or Phone',
                    hintText: _isPhone ? '012 345 678' : 'you@example.com',
                    prefixIcon: Icon(
                      _isPhone ? Icons.phone_android : Icons.email_outlined,
                    ),
                    prefixText: _isPhone ? '+855 ' : null,
                    prefixStyle: const TextStyle(fontWeight: FontWeight.w600),
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
                    final d = v.replaceAll(RegExp(r'[^\d]'), '');
                    final isPhone = !v.contains('@') && d.isNotEmpty;
                    if (isPhone && d.length < 8) return 'Phone too short';
                    if (!isPhone && !GetUtils.isEmail(v.trim()) && d.length < 8)
                      return 'Enter a valid email or phone';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
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
                      return 'Please enter a password';
                    if (v.length < 6) return 'At least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
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
                    if (v == null || v.isEmpty) return 'Please confirm';
                    if (v != _passwordController.text)
                      return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: (auth.isLoading.value || _sendingCode)
                        ? null
                        : _handleRegister,
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
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () => Get.offAllNamed(AppRoutes.login),
                      child: const Text(
                        'Sign In',
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
