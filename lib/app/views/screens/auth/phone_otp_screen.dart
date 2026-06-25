import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../config/app_theme.dart';
import '../../../../config/app_snack.dart';
import '../../../controllers/auth_controller.dart';

class PhoneOTPScreen extends StatefulWidget {
  final String phoneNumber; // E.164 format
  final bool isRegistration; // true = sign up, false = sign in
  const PhoneOTPScreen({
    super.key,
    required this.phoneNumber,
    required this.isRegistration,
  });

  @override
  State<PhoneOTPScreen> createState() => _PhoneOTPScreenState();
}

class _PhoneOTPScreenState extends State<PhoneOTPScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;
  int _resendCooldown = 0;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) _focusNodes[index + 1].requestFocus();
    }
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _code;
    if (code.length != 6) {
      AppSnack.error('Invalid', 'Please enter the 6-digit code.');
      return;
    }
    setState(() => _verifying = true);
    final auth = Get.find<AuthController>();
    final error = await auth.verifyPhoneOTP(code);
    if (mounted && error != null) {
      setState(() => _verifying = false);
      AppSnack.error('Verification Failed', error);
    }
  }

  Future<void> _resendCode() async {
    setState(() => _resendCooldown = 60);
    final auth = Get.find<AuthController>();
    final error = await auth.sendPhoneOTP(widget.phoneNumber);
    if (error != null) {
      AppSnack.error('Error', error);
    } else {
      AppSnack.success('Sent', 'A new code has been sent.');
    }
    // Countdown
    for (int i = 60; i > 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendCooldown = i - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.isRegistration ? 'Verify Sign Up' : 'Verify Sign In',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Enter verification code',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'A 6-digit code was sent to ${widget.phoneNumber}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // OTP Input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  return Container(
                    width: 48,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkSurface2
                            : const Color(0xFFF1F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (v) => _onDigitChanged(v, i),
                      onSubmitted: (_) {
                        if (_code.length == 6) _verify();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Verify button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _verifying ? null : _verify,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _verifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive a code?",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                  TextButton(
                    onPressed: _resendCooldown > 0 ? null : _resendCode,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend in ${_resendCooldown}s'
                          : 'Resend',
                      style: TextStyle(
                        color: _resendCooldown > 0
                            ? Colors.grey
                            : AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
