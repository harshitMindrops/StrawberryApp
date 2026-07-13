import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:strawberry/features/auth/auth_screen.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'attendance_mark_page.dart';
import 'gallery_admin_page.dart';
import 'notice_admin_page.dart';
import 'package:strawberry/features/chat/chat_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
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

  // Opens approval bottom sheet for a student
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
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Approve Student',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white60),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),
                    Text(
                      'Name: $name',
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Phone: $phone',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 24),

                    // Student Type Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedStudentType,
                      decoration: InputDecoration(
                        labelText: 'Student Type',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: const Icon(Icons.school, color: Color(0xFFFF4E7E)),
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
                        padding: const EdgeInsets.only(top: 12),
                        child: TextFormField(
                          controller: customTypeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Custom Student Type',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                            prefixIcon: const Icon(Icons.edit, color: Color(0xFFFF4E7E)),
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
                          validator: (value) {
                            if (_selectedStudentType == 'Other' && (value == null || value.trim().isEmpty)) {
                              return 'Please specify custom student type';
                            }
                            return null;
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Fees
                    TextFormField(
                      controller: feesController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Fees',
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                        prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFF4E7E)),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter fees';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
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
                            SnackBar(
                              content: Text('Successfully approved $name!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadRequests();
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to approve student. Please try again.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4E7E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Approve & Enroll', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Opens dialog to add a new admin number
  void _openAddAdminDialog() {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add Allowed Admin', style: TextStyle(color: Colors.white)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Enter the phone number that will be granted administrator access upon registration.',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6)),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF4E7E), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
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
                    SnackBar(
                      content: Text('Granted Admin rights to $fullPhone'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadAdmins();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to add admin. Please check permission.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4E7E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Admin'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text('Admin Panel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Log Out',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF4E7E),
          labelColor: const Color(0xFFFF4E7E),
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions_rounded), text: 'Pending'),
            Tab(icon: Icon(Icons.admin_panel_settings_rounded), text: 'Admins'),
            Tab(icon: Icon(Icons.event_available), text: 'Attendance'),
            Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
            Tab(icon: Icon(Icons.campaign), text: 'Notices'),
            Tab(icon: Icon(Icons.school), text: 'Students'),
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
          ],
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

  Widget _buildPendingTab() {
    if (_loadingRequests) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E7E)));
    }

    if (_pendingRequests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        color: const Color(0xFFFF4E7E),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  const Text('No Pending Requests', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Pull down to refresh', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRequests,
      color: const Color(0xFFFF4E7E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingRequests.length,
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          final name = request['name'] ?? 'Unknown User';
          final phone = request['phone'] ?? '';

          return Card(
            color: const Color(0xFF1E1E2C),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFF4E7E),
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(phone, style: TextStyle(color: Colors.white.withOpacity(0.6))),
              trailing: ElevatedButton(
                onPressed: () => _openApprovalSheet(request),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E7E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Review'),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdminsTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminDialog,
        backgroundColor: const Color(0xFFFF4E7E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loadingAdmins
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E7E)))
          : RefreshIndicator(
              onRefresh: _loadAdmins,
              color: const Color(0xFFFF4E7E),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _allowedAdmins.length,
                itemBuilder: (context, index) {
                  final phone = _allowedAdmins[index];
                  final isPrimary = phone == '+918851578850';

                  return Card(
                    color: const Color(0xFF1E1E2C),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: isPrimary ? Colors.amber.withOpacity(0.1) : Colors.white10,
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: isPrimary ? Colors.amber : Colors.white70,
                        ),
                      ),
                      title: Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: Text(
                        isPrimary ? 'Primary Administrator' : 'Co-Administrator',
                        style: TextStyle(color: isPrimary ? Colors.amber[300] : Colors.white60, fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildStudentsTab() {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E7E)));
    }

    if (_allStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStudents,
        color: const Color(0xFFFF4E7E),
        child: const Center(
          child: Text('No enrolled students found.', style: TextStyle(color: Colors.white70)),
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
      color: const Color(0xFFFF4E7E),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.keys.map((type) {
          final list = grouped[type]!;
          return ExpansionTile(
            title: Text(
              '$type Students (${list.length})',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            iconColor: const Color(0xFFFF4E7E),
            collapsedIconColor: Colors.white60,
            children: list.map((student) {
              final name = student['name'] ?? 'Student';
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.person, color: Colors.white70),
                ),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                trailing: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFFF4E7E)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          studentId: student['id'] as String,
                          studentName: name,
                          isAdmin: true,
                        ),
                      ),
                    ).then((_) => _loadChats());
                  },
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatInboxTab() {
    if (_loadingChats) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4E7E)));
    }

    if (_chatStudents.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChats,
        color: const Color(0xFFFF4E7E),
        child: const Center(
          child: Text(
            'No active chats. Students will appear here when they send messages.',
            style: const TextStyle(color: Colors.white38),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChats,
      color: const Color(0xFFFF4E7E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chatStudents.length,
        itemBuilder: (context, index) {
          final student = _chatStudents[index];
          final name = student['name'] ?? 'Unknown Student';
          final type = student['student_type'] ?? 'Regular';

          return Card(
            color: const Color(0xFF1E1E2C),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFF4E7E),
                child: Icon(Icons.chat, color: Colors.white),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              subtitle: Text(type, style: const TextStyle(color: Colors.white60)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white38),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      studentId: student['id'] as String,
                      studentName: name,
                      isAdmin: true,
                    ),
                  ),
                ).then((_) => _loadChats());
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
