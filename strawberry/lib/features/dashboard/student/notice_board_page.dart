import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class NoticeBoardPage extends StatefulWidget {
  const NoticeBoardPage({Key? key}) : super(key: key);

  @override
  State<NoticeBoardPage> createState() => _NoticeBoardPageState();
}

class _NoticeBoardPageState extends State<NoticeBoardPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _loading = true);
    final uid = _authService.currentUserId;
    try {
      // Fetch general notices for 'All' audience
      final all = await _authService.getNotices(audience: 'All');
      // Fetch student-specific notices (targeted at this student)
      final specific = await _authService.getStudentSpecificNotices(uid ?? '');
      if (!mounted) return;
      setState(() {
        _notices = [...all, ...specific];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter notices
    final filteredNotices = _selectedCategory == 'All'
        ? _notices
        : _notices
              .where((n) => (n['category'] ?? 'General') == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Notice Board',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildCategoryFilterRow(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4E7E)),
                  )
                : filteredNotices.isEmpty
                ? const Center(
                    child: Text(
                      'No notices available',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotices,
                    color: const Color(0xFFFF4E7E),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotices.length,
                      itemBuilder: (context, index) {
                        final n = filteredNotices[index];
                        final title = n['title'] ?? '';
                        final body = n['body'] ?? '';
                        final category = n['category'] ?? 'General';
                        final created = n['created_at'] != null
                            ? n['created_at'].toString().split('T').first
                            : '';

                        Color catColor = Colors.blueAccent;
                        if (category == 'Fees') catColor = Colors.orangeAccent;
                        if (category == 'Holiday') catColor = Colors.redAccent;
                        if (category == 'Event') catColor = Colors.greenAccent;

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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: catColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: catColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Colors.white10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Posted on: $created',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow() {
    final categories = ['All', 'General', 'Fees', 'Holiday', 'Event'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFF1E1E2C),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: const Color(0xFFFF4E7E),
              backgroundColor: const Color(0xFF0F0F1A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFFF4E7E) : Colors.white10,
                ),
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
