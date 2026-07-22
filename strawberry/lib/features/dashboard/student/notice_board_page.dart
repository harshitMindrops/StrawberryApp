import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class NoticeBoardPage extends StatefulWidget {
  const NoticeBoardPage({super.key});

  @override
  State<NoticeBoardPage> createState() => _NoticeBoardPageState();
}

class _NoticeBoardPageState extends State<NoticeBoardPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _notices = [];
  bool _loading = true;
  String _selectedCategory = 'All';

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    setState(() => _loading = true);
    final uid = _authService.currentUserId;
    try {
      final all = await _authService.getNotices(audience: 'All');
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
    final filteredNotices = _selectedCategory == 'All'
        ? _notices
        : _notices
              .where((n) => (n['category'] ?? 'General') == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Notice Board',
          style: TextStyle(
            color: _textDark,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        backgroundColor: _surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      body: Column(
        children: [
          _buildCategoryFilterRow(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : filteredNotices.isEmpty
                ? const Center(
                    child: Text(
                      'No notices available',
                      style: TextStyle(color: _textMuted, fontSize: 14),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadNotices,
                    color: _primary,
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

                        Color catColor = const Color(0xFF3E8EFF);
                        if (category == 'Fees') catColor = const Color(0xFFF5A623);
                        if (category == 'Holiday') catColor = const Color(0xFFEF4949);
                        if (category == 'Event') catColor = const Color(0xFF22B07D);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: catColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: catColor,
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                const Divider(color: _border, height: 1),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    'Posted on: $created',
                                    style: const TextStyle(
                                      color: _textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
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
      height: 56,
      color: _surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: _primary,
              backgroundColor: _bg,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? _primary : _border,
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
