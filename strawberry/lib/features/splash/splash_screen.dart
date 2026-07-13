import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/enter_name_screen.dart';
import 'package:strawberry/features/dashboard/student/home_screen.dart';
import 'package:strawberry/features/dashboard/student/wait_screen.dart';
import 'package:strawberry/features/dashboard/admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final authService = AuthService();
    final loggedIn = authService.isLoggedIn();

    if (!mounted) return;

    if (!loggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      return;
    }

    try {
      final profile = await authService.getCurrentProfile();

      if (!mounted) return;

      if (profile == null || profile['name'] == null || (profile['name'] as String).trim().isEmpty) {
        // Logged in but profile details are not fully filled
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EnterNameScreen()),
        );
      } else {
        final role = profile['role'];
        final status = profile['status'];

        if (status == 'pending') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaitScreen()),
          );
        } else if (status == 'approved') {
          if (role == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        } else {
          // If rejected or any other status, force logout and return to auth screen
          await authService.logout();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthScreen()),
          );
        }
      }
    } catch (e) {
      // In case of error, fall back to AuthScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome to Strawberry',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

