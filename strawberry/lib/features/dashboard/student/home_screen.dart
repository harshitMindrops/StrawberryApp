import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/dashboard/student/attendance_page.dart';
import 'package:strawberry/features/dashboard/student/gallery_page.dart';
import 'package:strawberry/features/dashboard/student/notice_board_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  StreamSubscription? _noticesSubscription;
  int _unreadNoticesCount = 0;

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _accentPeach = Color(0xFFFF8FA3);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _noticesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await _authService.getCurrentProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
      _loadUnreadNoticesCount();
      _subscribeToNotices();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUnreadNoticesCount() async {
    final uid = _authService.currentUserId ?? '';
    final studentType = _profile?['student_type'] as String?;
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastViewedStr = prefs.getString('last_viewed_notices_time_$uid');
      final DateTime lastViewed = lastViewedStr != null
          ? DateTime.parse(lastViewedStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      final notices = await _authService.getNoticesForStudent(uid, studentType);
      int unread = 0;
      for (var n in notices) {
        final createdStr = n['created_at'] as String?;
        if (createdStr != null) {
          final created = DateTime.tryParse(createdStr);
          if (created != null && created.isAfter(lastViewed)) {
            unread++;
          }
        }
      }
      if (mounted) {
        setState(() {
          _unreadNoticesCount = unread;
        });
      }
    } catch (e) {
      print('Error loading unread notices count: $e');
    }
  }

  void _subscribeToNotices() {
    _noticesSubscription?.cancel();
    final uid = _authService.currentUserId ?? '';
    final studentType = _profile?['student_type'] as String?;
    if (uid.isEmpty) return;

    bool isFirstEmit = true;
    List<int> initialIds = [];

    _noticesSubscription = _authService
        .getNoticesRealtimeStream(uid, studentType)
        .listen((notices) {
      final currentIds = notices.map((n) => n['id'] as int).toList();
      
      if (isFirstEmit) {
        initialIds = currentIds;
        isFirstEmit = false;
        return;
      }

      // Check for new notices
      for (var notice in notices) {
        final id = notice['id'] as int;
        if (!initialIds.contains(id)) {
          initialIds.add(id);
          _showInAppNotification(notice);
          _loadUnreadNoticesCount();
        }
      }
    });
  }

  void _showInAppNotification(Map<String, dynamic> notice) {
    if (!mounted) return;
    final title = notice['title'] ?? 'New Notice';
    final body = notice['body'] ?? '';
    final category = notice['category'] ?? 'General';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign_rounded, color: _primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'New Announcement!',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: _primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _textMuted),
            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NoticeBoardPage()),
              ).then((_) => _loadUnreadNoticesCount());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View Board', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
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
      appBar: AppBar(
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: _textDark,
          ),
        ),
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: _primary),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_primary, _accentPeach],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white24,
                                backgroundImage: (_profile?['photo_url'] as String?) != null &&
                                        (_profile!['photo_url'] as String).isNotEmpty
                                    ? NetworkImage(_profile!['photo_url'])
                                    : null,
                                child: (_profile?['photo_url'] as String?) == null ||
                                        (_profile!['photo_url'] as String).isEmpty
                                    ? const Icon(
                                        Icons.person,
                                        size: 32,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _profile?['name'] ?? 'Student',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (_profile?['email'] ?? _profile?['phone'] ?? '').toString(),
                            style: TextStyle(
                              fontSize: 13.5,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Academic Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detail Row 1: Student Type
                    _buildInfoCard(
                      icon: Icons.school_rounded,
                      title: 'Admission Type',
                      value: _profile?['student_type'] ?? 'Regular',
                      color: const Color(0xFF3E8EFF),
                    ),
                    const SizedBox(height: 12),

                    // Detail Row 2: Fees details
                    _buildInfoCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Academic Fees',
                      value: '₹${_profile?['fees'] ?? 0}/month',
                      color: const Color(0xFF22B07D),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      children: [
                        _buildNavCard(
                          icon: Icons.event_available_rounded,
                          title: 'Attendance',
                          subtitle: 'View records',
                          color: const Color(0xFF22B07D),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AttendancePage(),
                            ),
                          ),
                        ),
                        _buildNavCard(
                          icon: Icons.photo_library_rounded,
                          title: 'Gallery',
                          subtitle: 'School events',
                          color: const Color(0xFFF5A623),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const GalleryPage(),
                            ),
                          ),
                        ),
                        _buildNavCard(
                          icon: Icons.campaign_rounded,
                          title: 'Notices',
                          subtitle: 'Latest updates',
                          color: const Color(0xFF3E8EFF),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NoticeBoardPage(),
                            ),
                          ).then((_) => _loadUnreadNoticesCount()),
                          badgeCount: _unreadNoticesCount,
                        ),
                        _buildNavCard(
                          icon: Icons.forum_rounded,
                          title: 'Chat Support',
                          subtitle: 'Talk with Admin',
                          color: _primary,
                          onTap: () {
                            final uid = _authService.currentUserId ?? '';
                            final name = _profile?['name'] ?? 'Student';
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  studentId: uid,
                                  studentName: name,
                                  isAdmin: false,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Welcome to your Strawberry Student ERP.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
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
}
