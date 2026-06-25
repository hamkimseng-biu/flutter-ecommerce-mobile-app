import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../../config/app_theme.dart';
import '../../../../../config/app_snack.dart';
import '../../../config/kh_phone_util.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Auto-detected mode: false = email, true = phone
  bool _isPhone = false;

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
    super.dispose();
  }

  void _onInputChanged() {
    final raw = _emailOrPhoneController.text;

    // Auto-detect: if contains @ → email, otherwise check if looks like phone
    final looksLikePhone =
        !raw.contains('@') && raw.replaceAll(RegExp(r'[^\d]'), '').length >= 1;
    if (_isPhone != looksLikePhone) {
      setState(() => _isPhone = looksLikePhone);
    }

    // Live phone formatting: add spaces as user types
    if (_isPhone) {
      final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
      final formatted = _formatPhone(digits);
      if (raw != formatted) {
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
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, digits.length > 10 ? 10 : digits.length)}';
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Get.find<AuthController>();
    String? error;

    if (_isPhone) {
      final phone = KhPhoneUtil.toE164(_emailOrPhoneController.text);
      error = await auth.sendPhoneOTP(phone);
      if (error != null) {
        if (mounted) AppSnack.error('Error', error);
        return;
      }
      if (auth.isLoggedIn.value) return;
      _showOTPDialog();
    } else {
      error = await auth.signUp(
        _nameController.text.trim(),
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );
      if (error != null && mounted) {
        AppSnack.error('Registration Failed', error);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = Get.find<AuthController>();
    final error = await auth.signInWithGoogle();
    if (error != null && mounted) {
      AppSnack.error('Google Sign-In Failed', error);
    }
  }

  void _showOTPDialog() {
    final otpCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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
              if (error != null) AppSnack.error('Error', error);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Verify'),
          ),
        ],
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
                        'Tiny Chicken',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
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
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Please enter your name';
                    if (v.trim().length < 2)
                      return 'Name must be at least 2 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Unified Email/Phone field — auto-detects type dynamically
                TextFormField(
                  controller: _emailOrPhoneController,
                  keyboardType: _isPhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  inputFormatters: _isPhone
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ]
                      : null,
                  decoration: InputDecoration(
                    labelText: _isPhone ? 'Phone Number' : 'Email or Phone',
                    hintText: _isPhone ? '12 345 678' : 'you@example.com',
                    prefixIcon: Icon(
                      _isPhone ? Icons.phone_android : Icons.email_outlined,
                    ),
                    suffixIcon: _isPhone
                        ? null
                        : const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.phone_android,
                              size: 18,
                              color: Color(0xFF9E9EAA),
                            ),
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
                    if (v == null || v.trim().isEmpty) {
                      return _isPhone
                          ? 'Please enter your phone number'
                          : 'Please enter your email or phone';
                    }
                    if (_isPhone) {
                      if (v.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
                        return 'Enter a valid phone number';
                      }
                    } else {
                      final hasAt = v.contains('@');
                      final hasDigits =
                          v.replaceAll(RegExp(r'[^\d]'), '').length >= 8;
                      if (!hasAt && !hasDigits) {
                        return 'Enter a valid email or phone number';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
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
                      return 'Please enter a password';
                    }
                    if (v.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
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
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
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
                      return 'Please confirm your password';
                    }
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Register Button
                GetBuilder<AuthController>(
                  builder: (auth) => SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: auth.isLoading.value ? null : _handleRegister,
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
                          : Text(
                              _isPhone
                                  ? 'Send Verification Code'
                                  : 'Create Account',
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

                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
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
