import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AuthService _authService = AuthService();
  DateTimeRange? _selectedRange;
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

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
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
      await _loadAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'My Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4E7E)),
            )
          : _records.isEmpty
          ? const Center(
              child: Text(
                'No attendance records',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final rec = _records[index];
                final date = rec['date'] ?? '';
                final status = rec['status'] ?? '';
                return Card(
                  color: const Color(0xFF1E1E2C),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      status == 'Present' ? Icons.check_circle : Icons.cancel,
                      color: status == 'Present'
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                    title: Text(
                      date,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Status: $status',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
