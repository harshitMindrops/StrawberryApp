import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class NoticeAdminPage extends StatefulWidget {
  final AuthService authService;
  const NoticeAdminPage({Key? key, required this.authService})
    : super(key: key);

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

  List<Map<String, dynamic>> _historyNotices = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _loadHistory();
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
    final specificId = _selectedStudent != null
        ? _selectedStudent!['id'] as String
        : null;

    await widget.authService.createNotice(
      title: title,
      body: body,
      audience: audience,
      specificStudentId: specificId,
      category: category,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notice created'),
        backgroundColor: Color(0xFFFF4E7E),
      ),
    );
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _audience = 'All';
      _category = 'General';
      _selectedStudent = null;
    });
    _loadHistory();
  }

  Future<void> _deleteNotice(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Delete Notice',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this notice?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authService.deleteNotice(id);
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          title: const Text(
            'Notice Management',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E1E2C),
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF4E7E),
            labelColor: Color(0xFFFF4E7E),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: 'Create Notice'),
              Tab(text: 'History & Review'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildCreateNoticeTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  Widget _buildCreateNoticeTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF4E7E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Body',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF4E7E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Enter body' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _audience,
              decoration: InputDecoration(
                labelText: 'Audience',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF4E7E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'All', child: Text('All')),
                DropdownMenuItem<String>(
                  value: 'Preschool',
                  child: Text('Preschool'),
                ),
                DropdownMenuItem<String>(
                  value: 'Daycare',
                  child: Text('Daycare'),
                ),
                DropdownMenuItem<String>(value: 'Both', child: Text('Both')),
                DropdownMenuItem<String>(
                  value: 'Specific',
                  child: Text('Specific Student'),
                ),
              ],
              onChanged: (v) => setState(() => _audience = v ?? 'All'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFF4E7E),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'General',
                  child: Text('General'),
                ),
                DropdownMenuItem<String>(
                  value: 'Fees',
                  child: Text('Fees Notice'),
                ),
                DropdownMenuItem<String>(
                  value: 'Holiday',
                  child: Text('Holiday Announcement'),
                ),
                DropdownMenuItem<String>(
                  value: 'Event',
                  child: Text('School Event'),
                ),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'General'),
            ),
            const SizedBox(height: 16),
            if (_audience == 'Specific')
              _loadingStudents
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4E7E),
                      ),
                    )
                  : DropdownSearch<Map<String, dynamic>>(
                      items: _students,
                      itemAsString: (s) => s['name'] as String,
                      selectedItem: _selectedStudent,
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        itemBuilder: (context, item, isSelected) => ListTile(
                          title: Text(item['name'] ?? ''),
                          subtitle: Text(item['student_type'] ?? ''),
                        ),
                      ),
                      onChanged: (v) => setState(() => _selectedStudent = v),
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: 'Student',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFFF4E7E),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4E7E),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Create Notice',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_loadingHistory) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4E7E)),
      );
    }

    if (_historyNotices.isEmpty) {
      return const Center(
        child: Text(
          'No notices created yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: const Color(0xFFFF4E7E),
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

          Color categoryColor = Colors.blueAccent;
          if (category == 'Fees') categoryColor = Colors.orangeAccent;
          if (category == 'Holiday') categoryColor = Colors.redAccent;
          if (category == 'Event') categoryColor = Colors.greenAccent;

          return Card(
            color: const Color(0xFF1E1E2C),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: categoryColor, width: 0.5),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _deleteNotice(notice['id'] as int),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Audience: $audience',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
