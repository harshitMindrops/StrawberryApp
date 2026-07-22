import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/auth/push_notification_service.dart';


/// ---------------------------------------------------------------------
/// Design tokens — kept consistent with the rest of the admin panel
/// ---------------------------------------------------------------------
class _Palette {
  static const primary = Color(0xFFE94464);
  static const primaryDark = Color(0xFFD32F52);
  static const primarySoft = Color(0xFFFFE7EC);

  static const bg = Color(0xFFFBF9FA);
  static const surface = Colors.white;
  static const border = Color(0xFFF1E4E7);

  static const textDark = Color(0xFF2B2730);
  static const textMuted = Color(0xFF8F8A93);
  static const textFaint = Color(0xFFB9B3BB);

  static const success = Color(0xFF3FAE5C);
  static const danger = Color(0xFFE2504A);

  // Category accent colors
  static const catGeneral = Color(0xFF4C86E0);
  static const catFees = Color(0xFFE9A23B);
  static const catHoliday = Color(0xFFE2504A);
  static const catEvent = Color(0xFF3FAE5C);
}

class NoticeAdminPage extends StatefulWidget {
  final AuthService authService;
  const NoticeAdminPage({Key? key, required this.authService}) : super(key: key);

  @override
  State<NoticeAdminPage> createState() => _NoticeAdminPageState();
}

class _NoticeAdminPageState extends State<NoticeAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'All';
  String _category = 'General';
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  bool _loadingStudents = true;
  bool _submitting = false;

  List<Map<String, dynamic>> _historyNotices = [];
  bool _loadingHistory = true;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadHistory();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await widget.authService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
      });
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _loadStudents() async {
    setState(() => _loadingStudents = true);
    final list = await widget.authService.getAllStudents();
    if (!mounted) return;
    setState(() {
      _students = list;
      _loadingStudents = false;
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final history = await widget.authService.getSentNotices();
      if (!mounted) return;
      setState(() {
        _historyNotices = history;
        _loadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHistory = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final audience = _audience;
    final category = _category;
    final specificId = _selectedStudent != null ? _selectedStudent!['id'] as String : null;

    setState(() => _submitting = true);
    try {
      await widget.authService.createNotice(
        title: title,
        body: body,
        audience: audience,
        specificStudentId: specificId,
        category: category,
      );

      // Send system push notifications to matching audience devices asynchronously
      PushNotificationService().sendNoticeNotification(
        title: title,
        body: body,
        audience: audience,
        specificStudentId: specificId,
      ).catchError((err) {
        print("Push notification dispatch failed: $err");
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_snack('Notice created', success: true));
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _audience = 'All';
        _category = 'General';
        _selectedStudent = null;
      });
      _loadHistory();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _Palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _Palette.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Delete Notice',
                style: TextStyle(color: _Palette.textDark, fontSize: 17, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this notice?',
          style: TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _Palette.textMuted),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.deleteNotice(id);
      _loadHistory();
    }
  }

  SnackBar _snack(String message, {required bool success}) {
    return SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: success ? _Palette.success : _Palette.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    );
  }

  static InputDecoration _fieldDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _Palette.textMuted, fontSize: 14),
      prefixIcon: icon != null ? Icon(icon, color: _Palette.primary, size: 20) : null,
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
      fillColor: _Palette.surface,
    );
  }

  static Color _categoryColor(String category) {
    switch (category) {
      case 'Fees':
        return _Palette.catFees;
      case 'Holiday':
        return _Palette.catHoliday;
      case 'Event':
        return _Palette.catEvent;
      default:
        return _Palette.catGeneral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _Palette.bg,
        appBar: AppBar(
          title: const Text('Notice Management',
              style: TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w800, fontSize: 19)),
          backgroundColor: _Palette.surface,
          surfaceTintColor: Colors.transparent,
          foregroundColor: _Palette.textDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: _Palette.surface,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _Palette.bg,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: _Palette.primary,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: _Palette.textMuted,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Create Notice'),
                    Tab(text: 'History & Review'),
                  ],
                ),
              ),
            ),
          ),
          shape: const Border(bottom: BorderSide(color: _Palette.border, width: 1)),
        ),
        body: TabBarView(
          children: [_buildCreateNoticeTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildCreateNoticeTab() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text('COMPOSE', style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textFaint, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600),
            decoration: _fieldDecoration(label: 'Title', icon: Icons.title_rounded),
            validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _bodyController,
            maxLines: 4,
            style: const TextStyle(color: _Palette.textDark),
            decoration: _fieldDecoration(label: 'Body', icon: Icons.notes_rounded),
            validator: (v) => v == null || v.isEmpty ? 'Enter body' : null,
          ),
          const SizedBox(height: 22),
          Text('TARGETING', style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: _Palette.textFaint, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _audience,
            dropdownColor: _Palette.surface,
            style: const TextStyle(color: _Palette.textDark, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: _fieldDecoration(label: 'Audience', icon: Icons.groups_rounded),
            items: [
              const DropdownMenuItem<String>(value: 'All', child: Text('All')),
              ..._categories.map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat))),
              const DropdownMenuItem<String>(value: 'Specific', child: Text('Specific Student')),
            ],
            onChanged: (v) => setState(() => _audience = v ?? 'All'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _category,
            dropdownColor: _Palette.surface,
            style: const TextStyle(color: _Palette.textDark, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: _fieldDecoration(label: 'Category', icon: Icons.label_rounded),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'General', child: Text('General')),
              DropdownMenuItem<String>(value: 'Fees', child: Text('Fees Notice')),
              DropdownMenuItem<String>(value: 'Holiday', child: Text('Holiday Announcement')),
              DropdownMenuItem<String>(value: 'Event', child: Text('School Event')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'General'),
          ),
          if (_audience == 'Specific') ...[
            const SizedBox(height: 14),
            _loadingStudents
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: _Palette.primary)),
                  )
                : DropdownSearch<Map<String, dynamic>>(
                    items: _students,
                    itemAsString: (s) => s['name'] as String,
                    selectedItem: _selectedStudent,
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      containerBuilder: (context, popupWidget) => Container(
                        decoration: BoxDecoration(
                          color: _Palette.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: popupWidget,
                      ),
                      searchFieldProps: TextFieldProps(
                        style: const TextStyle(color: _Palette.textDark),
                        decoration: _fieldDecoration(label: 'Search student', icon: Icons.search_rounded),
                      ),
                      itemBuilder: (context, item, isSelected) => ListTile(
                        title: Text(item['name'] ?? '',
                            style: const TextStyle(color: _Palette.textDark, fontWeight: FontWeight.w600)),
                        subtitle: Text(item['student_type'] ?? '',
                            style: const TextStyle(color: _Palette.textMuted, fontSize: 12)),
                      ),
                    ),
                    onChanged: (v) => setState(() => _selectedStudent = v),
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: _fieldDecoration(label: 'Student', icon: Icons.person_rounded),
                    ),
                  ),
          ],
          const SizedBox(height: 26),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.primary,
                disabledBackgroundColor: _Palette.primary.withOpacity(0.6),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text('Create Notice',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator(color: _Palette.primary));
    }

    if (_historyNotices.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadHistory,
        color: _Palette.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _Palette.textFaint.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.campaign_rounded, size: 46, color: _Palette.textFaint),
                  ),
                  const SizedBox(height: 18),
                  const Text('No Notices Created Yet',
                      style: TextStyle(fontSize: 16.5, color: _Palette.textDark, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Notices you create will show up here',
                      style: TextStyle(fontSize: 13, color: _Palette.textMuted, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: _Palette.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyNotices.length,
        itemBuilder: (context, index) {
          final notice = _historyNotices[index];
          final title = notice['title'] ?? '';
          final body = notice['body'] ?? '';
          final category = notice['category'] ?? 'General';
          final audience = notice['target_audience'] ?? '';
          final dateStr = notice['created_at'] != null
              ? notice['created_at'].toString().split('T').first
              : '';

          final categoryColor = _categoryColor(category);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(color: categoryColor, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _deleteNotice(notice['id'] as int),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: _Palette.bg, shape: BoxShape.circle),
                        child: const Icon(Icons.delete_outline_rounded, color: _Palette.danger, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(title,
                    style: const TextStyle(
                        color: _Palette.textDark, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(body,
                    style: const TextStyle(color: _Palette.textMuted, fontSize: 13.5, height: 1.4)),
                const SizedBox(height: 14),
                Container(height: 1, color: _Palette.border),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded, size: 13, color: _Palette.textFaint),
                        const SizedBox(width: 4),
                        Text(audience,
                            style: const TextStyle(color: _Palette.textFaint, fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Text(dateStr,
                        style: const TextStyle(color: _Palette.textFaint, fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}