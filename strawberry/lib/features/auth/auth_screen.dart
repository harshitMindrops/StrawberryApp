import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  bool _loading = false;
  String? _error;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // User cancelled
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Check if profile exists in Supabase
      final profile = await _authService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null) {
        // New user — create profile using Google name automatically
        final newProfile = await _authService.createProfile();
        if (!mounted) return;

        final role = newProfile['role'];
        if (role == 'admin') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WaitScreen()),
            (route) => false,
          );
        }
      } else {
        // Existing user — route based on role and status
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
          setState(() {
            _error = 'Your registration request was rejected by the Admin.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Sign-in failed. Please try again. $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgTop = Color(0xFFFFFFFF);
    const Color bgBottom = Color(0xFFFFF5F6);
    const Color primary = Color(0xFFE94464);
    const Color primaryDark = Color(0xFFD32F52);
    const Color accent = Color(0xFFFFB4A2);
    const Color textDark = Color(0xFF2D2D2D);
    const Color textMuted = Color(0xFF9B9B9B);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: Stack(
          children: [
            // Decorative blobs
            Positioned(
              top: -60,
              right: -60,
              child: _blob(180, accent.withValues(alpha: 0.20)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _blob(240, primary.withValues(alpha: 0.07)),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              right: -30,
              child: _blob(100, primaryDark.withValues(alpha: 0.06)),
            ),

            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Color(0xFFFFF0F1)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.22),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // App name
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [primary, primaryDark],
                            ).createShader(bounds),
                            child: const Text(
                              'Strawberry',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                height: 1.1,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          const Text(
                            'Preschool & Daycare Management',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: textMuted,
                              letterSpacing: 0.3,
                            ),
                          ),

                          const SizedBox(height: 56),

                          // Welcome card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome Back! 👋',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to access your Strawberry dashboard',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: textMuted,
                                    height: 1.4,
                                  ),
                                ),

                                const SizedBox(height: 32),

                                // Google Sign-In Button
                                _GoogleSignInButton(
                                  loading: _loading,
                                  onTap: _signInWithGoogle,
                                ),

                                // Error message
                                if (_error != null) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline_rounded,
                                          color: Colors.red.shade600,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _error!,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Privacy note
                          Text(
                            'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: textMuted.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;

  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _pressed ? const Color(0xFFF5F5F5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.03 : 0.08),
                blurRadius: _pressed ? 4 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.loading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE94464),
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" logo using SVG-like approach with text
                    _GoogleLogo(),
                    const SizedBox(width: 12),
                    const Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3C4043),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    // Draw the 4 colored quadrants of the Google "G"
    final segments = [
      // Blue segment (top-right)
      {'color': const Color(0xFF4285F4), 'start': -90.0, 'sweep': 90.0},
      // Red segment (top-left)
      {'color': const Color(0xFFEA4335), 'start': 180.0, 'sweep': 90.0},
      // Yellow segment (bottom-left)
      {'color': const Color(0xFFFBBC04), 'start': 90.0, 'sweep': 90.0},
      // Green segment (bottom-right)
      {'color': const Color(0xFF34A853), 'start': 0.0, 'sweep': 90.0},
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.38
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.7),
        _toRad(seg['start'] as double),
        _toRad(seg['sweep'] as double),
        false,
        paint,
      );
    }

    // White cutout center
    final cutout = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), r * 0.46, cutout);

    // Blue horizontal bar (right side of G)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx, cy - r * 0.13, r * 0.82, r * 0.26),
      Radius.circular(r * 0.13),
    );
    canvas.drawRRect(barRect, barPaint);
  }

  double _toRad(double deg) => deg * 3.14159265 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
