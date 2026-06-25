import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_snack.dart';
import '../../config/kh_phone_util.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

/// Forgot Password — auto-detects email vs phone, no tabs needed.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _inputCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sending = false;
  bool _sent = false;

  // Auto-detected: false = email, true = phone
  bool _isPhone = false;
  String _detectedCarrier = '';

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    final raw = _inputCtrl.text;

    // Auto-detect: @ → email, digits → phone
    final looksLikePhone =
        !raw.contains('@') && raw.replaceAll(RegExp(r'[^\d]'), '').length >= 1;
    if (_isPhone != looksLikePhone) {
      setState(() => _isPhone = looksLikePhone);
    }

    // Live phone formatting
    if (_isPhone) {
      final digits = raw.replaceAll(RegExp(r'[^\d]'), '');
      final formatted = KhPhoneUtil.formatLocal(digits);
      if (raw != formatted) {
        final sel = _inputCtrl.selection.baseOffset;
        final diff = formatted.length - raw.length;
        _inputCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(
            offset: (sel + diff).clamp(0, formatted.length).toInt(),
          ),
        );
      }
      final carrier = KhPhoneUtil.detectCarrier(digits);
      if (carrier != _detectedCarrier) {
        setState(() => _detectedCarrier = carrier ?? '');
      }
    } else {
      if (_detectedCarrier.isNotEmpty) setState(() => _detectedCarrier = '');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    final auth = Get.find<AuthController>();

    if (_isPhone) {
      final digits = _inputCtrl.text.replaceAll(RegExp(r'[^\d]'), '');
      final e164 = KhPhoneUtil.toE164(digits);
      final error = await auth.sendPhoneOTP(e164);
      if (mounted) setState(() => _sending = false);
      if (error != null) {
        if (mounted) {
          // Check if it's a Firebase console configuration error
          final msg =
              error.contains('not allowed') || error.contains('disabled')
              ? 'Phone sign-in is not enabled. Enable it in Firebase Console → Authentication → Sign-in method → Phone.'
              : error;
          AppSnack.error('Error', msg);
        }
        return;
      }
      if (auth.isLoggedIn.value) {
        AppSnack.success(
          'Signed In',
          'You\'re signed in. Go to Profile → Edit Profile to update your password.',
        );
        return;
      }
      _showOTPDialog();
    } else {
      final error = await auth.resetPassword(_inputCtrl.text.trim());
      if (mounted) {
        setState(() {
          _sending = false;
          _sent = error == null;
        });
        if (error == null) {
          AppSnack.success(
            'Email Sent',
            'Check ${_inputCtrl.text.trim()} for the reset link.',
          );
        } else {
          AppSnack.error('Error', error);
        }
      }
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
              if (error != null) {
                AppSnack.error('Error', error);
              } else {
                AppSnack.success(
                  'Signed In',
                  'Go to Profile → Edit Profile to update your password.',
                );
              }
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
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.offAllNamed(AppRoutes.login),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.asset(
                      'assets/images/icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _sent ? 'Check Your Email' : 'Forgot Password?',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _sent
                      ? 'Follow the instructions in the email.'
                      : 'Enter your email or phone number.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                if (!_sent) ...[
                  // Unified input — auto-detects email vs phone
                  TextFormField(
                    controller: _inputCtrl,
                    keyboardType: _isPhone
                        ? TextInputType.phone
                        : TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                    decoration: InputDecoration(
                      labelText: _isPhone ? 'Phone Number' : 'Email Address',
                      hintText: _isPhone ? '012 345 678' : 'you@example.com',
                      prefixIcon: Icon(
                        _isPhone ? Icons.phone_android : Icons.email_outlined,
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
                            ? 'Enter your phone number'
                            : 'Enter your email';
                      }
                      if (_isPhone) {
                        if (v.replaceAll(RegExp(r'[^\d]'), '').length < 8) {
                          return 'Enter at least 8 digits';
                        }
                      } else if (!v.contains('@')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  // Carrier chip
                  if (_isPhone && _detectedCarrier.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.08,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.sim_card,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _detectedCarrier,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _handleSubmit,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _isPhone
                                  ? Icons.phone_android
                                  : Icons.send_rounded,
                            ),
                      label: Text(
                        _sending
                            ? 'Sending...'
                            : (_isPhone
                                  ? 'Send Verification Code'
                                  : 'Send Reset Link'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                if (_sent) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.successColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_read_rounded,
                          size: 36,
                          color: AppTheme.successColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reset link sent!',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.successColor,
                                ),
                              ),
                              Text(
                                'Check ${_inputCtrl.text.trim()}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9EAA),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Also check spam/junk folder.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFBDBDBD),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _inputCtrl.clear();
                        setState(() => _sent = false);
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Send Again',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () => Get.offAllNamed(AppRoutes.login),
                      icon: const Icon(Icons.login_rounded, size: 18),
                      label: const Text(
                        'I\'ve Reset — Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Get.offAllNamed(AppRoutes.login),
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
