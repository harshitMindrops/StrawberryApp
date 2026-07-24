import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AuthService _authService = AuthService();
  DateTimeRange? _selectedRange;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  String _formatTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final tod = TimeOfDay(hour: hour, minute: minute);
      
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final hourOfPeriod = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final minStr = tod.minute.toString().padLeft(2, '0');
      return '$hourOfPeriod:$minStr $period';
    } catch (_) {
      return timeStr;
    }
  }

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);
  static const Color _success = Color(0xFF22B07D);
  static const Color _danger = Color(0xFFEF4949);

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    final uid = _authService.currentUserId;
    if (uid != null) {
      final data = await _authService.getStudentAttendance(
        uid,
        start: _selectedRange?.start,
        end: _selectedRange?.end,
      );
      if (!mounted) return;
      setState(() {
        _records = data;
        _loading = false;
      });
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              surface: _surface,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
      await _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'My Attendance',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: _primary),
            onPressed: _pickRange,
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _records.isEmpty
              ? const Center(
                  child: Text(
                    'No attendance records found',
                    style: TextStyle(color: _textMuted, fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final rec = _records[index];
                    final date = rec['date'] ?? '';
                    final status = rec['status'] ?? '';
                    final isPresent = status == 'Present';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isPresent ? _success : _danger).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPresent
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isPresent ? _success : _danger,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          date,
                          style: const TextStyle(
                            color: _textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: $status',
                              style: TextStyle(
                                color: isPresent ? _success : _danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (isPresent && (rec['in_time'] != null || rec['out_time'] != null)) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (rec['in_time'] != null) ...[
                                    const Icon(Icons.login_rounded, size: 12, color: _textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'In: ${_formatTimeString(rec['in_time'])}',
                                      style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  if (rec['in_time'] != null && rec['out_time'] != null) ...[
                                    const SizedBox(width: 12),
                                  ],
                                  if (rec['out_time'] != null) ...[
                                    const Icon(Icons.logout_rounded, size: 12, color: _textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Out: ${_formatTimeString(rec['out_time'])}',
                                      style: const TextStyle(fontSize: 12, color: _textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
