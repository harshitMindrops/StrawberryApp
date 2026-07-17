import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'attendance_mark_page.dart';
import 'gallery_admin_page.dart';
import 'notice_admin_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';

/// ---------------------------------------------------------------------
/// Design tokens — Strawberry admin panel, light / premium / playful
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = Color(0xFFE94464); // strawberry red-pink
  static const primaryDark = Color(0xFFD32F52);
  static const primarySoft = Color(0xFFFFE7EC); // pale pink chip/bg
  static const accentPeach = Color(0xFFFFB4A2);
  static const leafGreen = Color(0xFF5FAD6B);
  static const amber = Color(0xFFE9A23B);

  static const bg = Color(0xFFFBF9FA); // app background
  static const surface = Colors.white; // cards / sheets
  static const border = Color(0xFFF1E4E7);

  static const textDark = Color(0xFF2B2730);
  static const textMuted = Color(0xFF8F8A93);
  static const textFaint = Color(0xFFB9B3BB);

  static const success = Color(0xFF3FAE5C);
  static const danger = Color(0xFFE2504A);
}

class _AdminTextStyles {
  static const title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: _Palette.textDark,
    letterSpacing: 0.1,
  );
  static const sectionHeading = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: _Palette.textDark,
  );
  static const cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: _Palette.textDark,
  );
  static const cardSubtitle = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: _Palette.textMuted,
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService();
  late TabController _tabController;

  List<Map<String, dynamic>> _pendingRequests = [];
  List<String> _allowedAdmins = [];
  bool _loadingRequests = true;
  bool _loadingAdmins = true;

  List<Map<String, dynamic>> _allStudents = [];
  bool _loadingStudents = true;
  List<Map<String, dynamic>> _chatStudents = [];
  bool _loadingChats = true;

  static const List<_TabMeta> _tabMeta = [
    _TabMeta(icon: Icons.pending_actions_rounded, label: 'Pending'),
    _TabMeta(icon: Icons.admin_panel_settings_rounded, label: 'Admins'),
    _TabMeta(icon: Icons.event_available_rounded, label: 'Attendance'),
    _TabMeta(icon: Icons.photo_library_rounded, label: 'Gallery'),
    _TabMeta(icon: Icons.campaign_rounded, label: 'Notices'),
    _TabMeta(icon: Icons.school_rounded, label: 'Students'),
    _TabMeta(icon: Icons.chat_bubble_rounded, label: 'Chats'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    _loadRequests();
    _loadAdmins();
    _loadStudents();
    _loadChats();
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    try {
      final list = await _authService.getAllStudents();
      if (!mounted) return;
      setState(() {
        _allStudents = list;
        _loadingStudents = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStudents = false);
    }
  }

  Future<void> _loadChats() async {
    setState(() => _loadingChats = true);
    try {
      final chats = await _authService.getChatList();
      if (!mounted) return;
      setState(() {
        _chatStudents = chats;
        _loadingChats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingChats = false);
    }
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final requests = await _authService.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _pendingRequests = requests;
        _loadingRequests = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRequests = false);
    }
  }

  Future<void> _loadAdmins() async {
    setState(() => _loadingAdmins = true);
    try {
      final admins = await _authService.getAllowedAdmins();
      if (!mounted) return;
      setState(() {
        _allowedAdmins = admins;
        _loadingAdmins = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
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

  // ---------------------------------------------------------------------
  // Approval bottom sheet
  // ---------------------------------------------------------------------
  void _openApprovalSheet(Map<String, dynamic> request) {
    final name = request['name'] ?? 'Unknown';
    final phone = request['phone'] ?? '';
    final uid = request['id'] ?? '';

    String? _selectedStudentType;
    final customTypeController = TextEditingController();
    final feesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 12,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: _Palette.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Approve Student', style: _AdminTextStyles.title),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _Palette.bg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, color: _Palette.textMuted, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Student summary chip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _Palette.primarySoft.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: _Palette.primary,
                            child: Icon(Icons.person_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700,
                                        color: _Palette.textDark)),
                                const SizedBox(height: 2),
                                Text(phone, style: _AdminTextStyles.cardSubtitle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Student Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedStudentType,
                      dropdownColor: _Palette.surface,
                      style: const TextStyle(color: _Palette.textDark, fontSize: 15),
                      decoration: _adminInputDecoration(
                        label: 'Student Type',
                        icon: Icons.school_rounded,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Preschool', child: Text('Preschool')),
                        DropdownMenuItem(value: 'Daycare', child: Text('Daycare')),
                        DropdownMenuItem(value: 'Both', child: Text('Both')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          _selectedStudentType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select student type';
                        }
                        return null;
                      },
                    ),
                    // If 'Other' is selected, show custom input
                    if (_selectedStudentType == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: TextFormField(
                          controller: customTypeController,
                          style: const TextStyle(color: _Palette.textDark),
                          decoration: _adminInputDecoration(
                            label: 'Custom Student Type',
                            icon: Icons.edit_rounded,
                          ),
                          validator: (value) {
                            if (_selectedStudentType == 'Other' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please specify custom student type';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Fees
                    TextFormField(
                      controller: feesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: _Palette.textDark),
                      decoration: _adminInputDecoration(
                        label: 'Fees',
                        icon: Icons.currency_rupee_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter fees';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;

                          final type = _selectedStudentType == 'Other'
                              ? customTypeController.text.trim()
                              : _selectedStudentType!;
                          final fees = double.tryParse(feesController.text.trim()) ?? 0.0;

                          try {
                            await _authService.approveStudent(uid, type, fees);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar('Successfully approved $name!', success: true),
                            );
                            _loadRequests();
                            Navigator.pop(context);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              _adminSnackBar('Failed to approve student. Please try again.',
                                  success: false),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _Palette.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Approve & Enroll',
                            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static InputDecoration _adminInputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, color: _Palette.primary, size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _Palette.danger),
      ),
      filled: true,
      fillColor: _Palette.bg,
    );
  }

  static SnackBar _adminSnackBar(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  // ---------------------------------------------------------------------
  // Add admin dialog
  // ---------------------------------------------------------------------
  void _openAddAdminDialog() {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _Palette.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Palette.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.person_add_alt_1_rounded, color: _Palette.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Add Allowed Admin',
                  style: TextStyle(color: _Palette.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the phone number that will be granted administrator access upon registration.',
                  style: TextStyle(fontSize: 13, color: _Palette.textMuted, height: 1.4),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w700),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _Palette.primary, width: 1.6),
                    ),
                    filled: true,
                    fillColor: _Palette.bg,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter mobile number';
                    }
                    if (value.trim().length != 10) {
                      return 'Must be 10 digits';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final rawPhone = phoneController.text.trim();
                final fullPhone = '+91$rawPhone';

                try {
                  await _authService.addAdmin(fullPhone);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    _adminSnackBar('Granted Admin rights to $fullPhone', success: true),
                  );
                  _loadAdmins();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _adminSnackBar('Failed to add admin. Please check permission.', success: false),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Admin', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.bg,
      appBar: AppBar(
        title: const Text('Admin Panel', style: _AdminTextStyles.title),
        backgroundColor: _Palette.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _Palette.textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.bg,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: _Palette.primary, size: 20),
            ),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: _Palette.surface,
            padding: const EdgeInsets.only(bottom: 8),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicator: BoxDecoration(
                color: _Palette.primarySoft,
                borderRadius: BorderRadius.circular(30),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(vertical: 4),
              dividerColor: Colors.transparent,
              labelColor: _Palette.primaryDark,
              unselectedLabelColor: _Palette.textMuted,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              tabs: _tabMeta
                  .map((m) => Tab(
                        height: 44,
                        icon: Icon(m.icon, size: 18),
                        text: m.label,
                        iconMargin: const EdgeInsets.only(bottom: 3),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Pending Approvals
          _buildPendingTab(),

          // Tab 2: Manage Admins
          _buildAdminsTab(),

          // Tab 3: Attendance Mark
          AttendanceMarkPage(authService: _authService),

          // Tab 4: Gallery Admin
          GalleryAdminPage(authService: _authService),

          // Tab 5: Notice Admin
          NoticeAdminPage(authService: _authService),

          // Tab 6: Students categorized list
          _buildStudentsTab(),

          // Tab 7: Chats list
          _buildChatInboxTab(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Pending tab
  // ---------------------------------------------------------------------
  Widget _buildPendingTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator(color: _Palette.primary));
    }

    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.check_circle_rounded,
              iconColor: _Palette.success,
              title: 'No Pending Requests',
              subtitle: 'Pull down to refresh',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: _Palette.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final name = request['name'] ?? 'Unknown User';
          final phone = request['phone'] ?? '';

          return _AdminCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: _Palette.primarySoft,
                    child: Icon(Icons.person_rounded, color: _Palette.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _AdminTextStyles.cardTitle),
                        const SizedBox(height: 3),
                        Text(phone, style: _AdminTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _openApprovalSheet(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Palette.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Admins tab
  // ---------------------------------------------------------------------
  Widget _buildAdminsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminDialog,
        backgroundColor: _Palette.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: _loadingAdmins
          ? const Center(child: CircularProgressIndicator(color: _Palette.primary))
          : RefreshIndicator(
              onRefresh: _loadAdmins,
              color: _Palette.primary,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                itemCount: _allowedAdmins.length,
                itemBuilder: (context, index) {
                  final phone = _allowedAdmins[index];
                  final isPrimary = phone == '+918851578850';

                  return _AdminCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                isPrimary ? _Palette.amber.withOpacity(0.15) : _Palette.bg,
                            child: Icon(
                              Icons.admin_panel_settings_rounded,
                              color: isPrimary ? _Palette.amber : _Palette.textMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(phone, style: _AdminTextStyles.cardTitle),
                                const SizedBox(height: 3),
                                Text(
                                  isPrimary ? 'Primary Administrator' : 'Co-Administrator',
                                  style: TextStyle(
                                    color: isPrimary ? _Palette.amber : _Palette.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPrimary)
                            const Icon(Icons.verified_rounded, color: _Palette.amber, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // Students tab
  // ---------------------------------------------------------------------
  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator(color: _Palette.primary));
    }

    if (_allStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStudents,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.school_rounded,
              iconColor: _Palette.textFaint,
              title: 'No Enrolled Students',
              subtitle: 'Approved students will show up here',
            ),
          ),
        ),
      );
    }

    // Group students by type
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var s in _allStudents) {
      final type = s['student_type'] as String? ?? 'Other';
      if (!grouped.containsKey(type)) {
        grouped[type] = [];
      }
      grouped[type]!.add(s);
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      color: _Palette.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: grouped.keys.map((type) {
          final list = grouped[type]!;
          return _AdminCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.only(bottom: 6),
                title: Row(
                  children: [
                    Text('$type', style: _AdminTextStyles.sectionHeading),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _Palette.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${list.length}',
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.primaryDark),
                      ),
                    ),
                  ],
                ),
                iconColor: _Palette.primary,
                collapsedIconColor: _Palette.textMuted,
                children: list.map((student) {
                  final name = student['name'] ?? 'Student';
                  return ListTile(
                    leading: const CircleAvatar(
                      radius: 18,
                      backgroundColor: _Palette.bg,
                      child: Icon(Icons.person_rounded, color: _Palette.textMuted, size: 18),
                    ),
                    title: Text(name, style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: _Palette.primary, size: 20),
                      onPressed: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => ChatPage(
                                  studentId: student['id'] as String,
                                  studentName: name,
                                  isAdmin: true,
                                ),
                              ),
                            )
                            .then((_) => _loadChats());
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Chat inbox tab
  // ---------------------------------------------------------------------
  Widget _buildChatInboxTab() {
    if (_loadingChats) {
      return const Center(child: CircularProgressIndicator(color: _Palette.primary));
    }

    if (_chatStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChats,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: _emptyState(
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: _Palette.textFaint,
              title: 'No Active Chats',
              subtitle: 'Students will appear here when they send messages',
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: _Palette.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _chatStudents.length,
        itemBuilder: (context, index) {
          final student = _chatStudents[index];
          final name = student['name'] ?? 'Unknown Student';
          final type = student['student_type'] ?? 'Regular';

          return _AdminCard(
            margin: const EdgeInsets.only(bottom: 12),
            onTap: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        studentId: student['id'] as String,
                        studentName: name,
                        isAdmin: true,
                      ),
                    ),
                  )
                  .then((_) => _loadChats());
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: _Palette.primary,
                    child: Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: _AdminTextStyles.cardTitle),
                        const SizedBox(height: 3),
                        Text(type, style: _AdminTextStyles.cardSubtitle),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: _Palette.textFaint),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared empty state
  // ---------------------------------------------------------------------
  Widget _emptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 46, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: const TextStyle(fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 13, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _TabMeta {
  final IconData icon;
  final String label;
  const _TabMeta({required this.icon, required this.label});
}

/// Reusable soft-shadow card used across the admin panel.
class _AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _AdminCard({
    required this.child,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}