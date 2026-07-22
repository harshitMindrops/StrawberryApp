import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class WaitScreen extends StatefulWidget {
  /// Pass [isRejected] = true when coming from the rejection flow
  final bool isRejected;
  const WaitScreen({super.key, this.isRejected = false});

  @override
  State<WaitScreen> createState() => _WaitScreenState();
}

class _WaitScreenState extends State<WaitScreen> {
  final _authService = AuthService();
  bool _loading = false;
  late bool _isRejected;

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _amber = Color(0xFFF5A623);
  static const Color _danger = Color(0xFFEF4949);
  static const Color _border = Color(0xFFEDEDF4);

  @override
  void initState() {
    super.initState();
    _isRejected = widget.isRejected;
  }

  Future<void> _checkStatus() async {
    setState(() => _loading = true);

    try {
      final profile = await _authService.getCurrentProfile();
      if (!mounted) return;

      if (profile != null) {
        final status = profile['status'];
        final role = profile['role'];

        if (status == 'approved') {
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
          return;
        }

        // Update rejection status dynamically
        if (status == 'rejected' && !_isRejected) {
          setState(() => _isRejected = true);
          return;
        }
        if (status == 'pending' && _isRejected) {
          setState(() => _isRejected = false);
        }
      }

      if (!_isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Your request is still pending approval.',
            ),
            backgroundColor: _amber,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to check status. Please try again.'),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reRequestApproval() async {
    setState(() => _loading = true);
    try {
      final uid = _authService.currentUserId;
      if (uid == null) throw Exception('Not logged in');
      await _authService.reRequestApproval(uid);
      if (!mounted) return;
      setState(() {
        _isRejected = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Your request has been re-submitted. Please wait for approval.',
          ),
          backgroundColor: const Color(0xFF22B07D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to re-submit request. Please try again.'),
            backgroundColor: _danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: _isRejected ? _buildRejectedView() : _buildPendingView(),
        ),
      ),
    );
  }

  Widget _buildPendingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 80,
              color: _amber,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Pending Approval',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Your request has been submitted to the administrator. You will be able to access the student dashboard once approved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: _textMuted,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: _primary),
            ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _checkStatus,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Check Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: TextButton.styleFrom(
              foregroundColor: _textMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRejectedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: _danger.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_rounded,
              size: 80,
              color: _danger,
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Request Rejected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _textDark,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            'Unfortunately, your registration request has been rejected by the administrator. You may re-submit your request or contact the school for more information.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              color: _textMuted,
              height: 1.5,
            ),
          ),
        ),
        const Spacer(),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: _primary),
            ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: _reRequestApproval,
            icon: const Icon(Icons.send_rounded),
            label: const Text(
              'Request Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out'),
            style: TextButton.styleFrom(
              foregroundColor: _textMuted,
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
