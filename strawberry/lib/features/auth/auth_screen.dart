import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/enter_name_screen.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  String? _verificationId;
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  // Sends the OTP using the AuthService
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length != 10) {
      setState(() => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fullPhoneNumber = '+91$phone';
      await _authService.sendOTP(
        phone: fullPhoneNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _otpSent = true;
            _loading = false;
          });
        },
        onError: (errorMessage) {
          if (!mounted) return;
          setState(() {
            _error = errorMessage;
            _loading = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to send OTP. Please check the number and try again.';
        _loading = false;
      });
    }
  }

  // Verifies the OTP and routes the user
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      setState(() => _error = 'Please enter a valid 6-digit OTP');
      return;
    }
    if (_verificationId == null) {
      setState(() => _error = 'Session expired. Please request OTP again.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Successfully verified. Let's fetch their profile to see where to redirect.
      final profile = await _authService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null || profile['name'] == null || (profile['name'] as String).isEmpty) {
        // New user or missing profile details
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const EnterNameScreen()),
          (route) => false,
        );
      } else {
        // Existing user
        final role = profile['role'];
        final status = profile['status'];

        if (status == 'pending') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WaitScreen()),
            (route) => false,
          );
        } else if (status == 'approved') {
          if (role == 'admin') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          // Denied or rejected
          setState(() {
            _error = 'Your registration request was rejected by the Admin.';
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid OTP. Please check and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E2C), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo/App Icon
                  const Icon(
                    Icons.bubble_chart_rounded,
                    size: 80,
                    color: Color(0xFFFF4E7E),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Strawberry',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _otpSent
                        ? 'Enter the verification code sent to +91 ${_phoneController.text}'
                        : 'Welcome! Sign in using your mobile number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Phone Input or OTP Input Form
                  if (!_otpSent) ...[
                    // Phone Number Input field
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: const Icon(Icons.phone, color: Color(0xFFFF4E7E)),
                        prefixText: '+91 ',
                        prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF4E7E), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ] else ...[
                    // OTP Input field
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      style: const TextStyle(color: Colors.white, letterSpacing: 8.0, fontSize: 18),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Verification OTP',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), letterSpacing: 0.0),
                        prefixIcon: const Icon(Icons.lock_clock_outlined, color: Color(0xFFFF4E7E)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF4E7E), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Button
                  ElevatedButton(
                    onPressed: _loading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4E7E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFFF4E7E).withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFFF4E7E).withOpacity(0.3),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _otpSent ? 'Verify & Login' : 'Send OTP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),

                  // Option to change number if OTP is sent
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                          _error = null;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.6),
                      ),
                      child: const Text('Change Phone Number'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}

