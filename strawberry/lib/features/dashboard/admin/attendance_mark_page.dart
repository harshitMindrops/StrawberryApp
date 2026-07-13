import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:intl/intl.dart';

class AttendanceMarkPage extends StatefulWidget {
  final AuthService authService;
  const AttendanceMarkPage({Key? key, required this.authService})
    : super(key: key);

  @override
  State<AttendanceMarkPage> createState() => _AttendanceMarkPageState();
}

class _AttendanceMarkPageState extends State<AttendanceMarkPage> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _students = [];
  Map<String, String> _attendanceStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _loading = true);
    final students = await widget.authService.getAllStudents();
    if (!mounted) return;
    setState(() {
      _students = students;
      for (var s in _students) {
        _attendanceStatus[s['id'] as String] = 'Present';
      }
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a date first'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final entries = _students
        .map(
          (s) => {
            'student_id': s['id'],
            'status': _attendanceStatus[s['id'] as String] ?? 'Present',
          },
        )
        .toList();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    await widget.authService.markAttendance(dateStr, entries);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attendance saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4E7E)),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4E7E),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        final id = student['id'] as String;
                        final name = student['name'] as String? ?? 'Student';
                        final type =
                            student['student_type'] as String? ?? 'Unknown';
                        return Card(
                          color: const Color(0xFF1E1E2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Type: $type',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            trailing: DropdownButton<String>(
                              value: _attendanceStatus[id],
                              dropdownColor: const Color(0xFF1E1E2C),
                              items: const [
                                DropdownMenuItem(
                                  value: 'Present',
                                  child: Text(
                                    'Present',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Absent',
                                  child: Text(
                                    'Absent',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Late',
                                  child: Text(
                                    'Late',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _attendanceStatus[id] = val!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4E7E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Attendance'),
                  ),
                ],
              ),
            ),
    );
  }
}
