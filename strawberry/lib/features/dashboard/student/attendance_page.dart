import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final AuthService _authService = AuthService();
  
  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _attendanceRecords = [];
  List<Map<String, dynamic>> _monthHolidays = [];
  
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _violet = Color(0xFF7C6FF0);
  static const Color _violetSoft = Color(0xFFEDE9FE);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);
  static const Color _success = Color(0xFF22B07D);
  static const Color _successSoft = Color(0xFFE4F6E8);
  static const Color _danger = Color(0xFFEF4949);
  static const Color _dangerSoft = Color(0xFFFBE7E6);
  static const Color _amber = Color(0xFFF5A623);
  static const Color _amberSoft = Color(0xFFFCF0DD);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        final profileFuture = _authService.getCurrentProfile();
        final attendanceFuture = _authService.getStudentAttendance(uid);
        final holidaysFuture = _authService.getHolidaysForMonth(
          _visibleMonth.year,
          _visibleMonth.month,
        );

        final results = await Future.wait([
          profileFuture,
          attendanceFuture,
          holidaysFuture,
        ]);

        if (!mounted) return;
        setState(() {
          _profile = results[0] as Map<String, dynamic>?;
          _attendanceRecords = results[1] as List<Map<String, dynamic>>;
          _monthHolidays = results[2] as List<Map<String, dynamic>>;
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta, 1);
    });
    _loadData();
  }

  // ── Derived Stats & Helper Methods ────────────────────────────────────

  String get _category => (_profile?['student_type'] as String?)?.trim() ?? 'All';

  Map<String, Map<String, dynamic>> get _recordsByDate {
    final map = <String, Map<String, dynamic>>{};
    for (final r in _attendanceRecords) {
      final d = r['date']?.toString();
      if (d != null) map[d] = r;
    }
    return map;
  }

  /// Map of holidays for visible month (Sunday, Saturday if applicable, or explicit DB holiday)
  Map<String, Map<String, dynamic>> get _holidaysByDate {
    final holidayMap = <String, Map<String, dynamic>>{};
    final isSatDefault = _authService.isSaturdayDefaultHoliday(_category);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;

    for (int day = 1; day <= daysInMonth; day++) {
      final dt = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(dt);
      if (dt.weekday == DateTime.sunday) {
        holidayMap[dateStr] = {'type': 'sunday', 'title': 'Sunday'};
      } else if (dt.weekday == DateTime.saturday && isSatDefault) {
        holidayMap[dateStr] = {'type': 'saturday', 'title': 'Saturday'};
      }
    }

    for (final h in _monthHolidays) {
      final dateStr = h['date']?.toString();
      if (dateStr == null) continue;
      if (h['type'] == 'holiday' &&
          (h['category'] == 'All' || h['category'] == _category)) {
        holidayMap[dateStr] = {
          'type': 'holiday',
          'title': h['title'],
          'category': h['category'],
        };
      }
      if (h['type'] == 'working_day' && h['category'] == _category) {
        holidayMap[dateStr] = {
          'type': 'working_day',
          'title': h['title'],
        };
      }
    }

    return holidayMap;
  }

  // Attendance Overall Stats
  int get _presentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Present').length;
  int get _absentCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Absent').length;
  int get _lateCount =>
      _recordsByDate.values.where((r) => r['status'] == 'Late').length;

  int get _totalWorkingDaysMarked => _recordsByDate.length;

  double get _attendancePercentage {
    if (_totalWorkingDaysMarked == 0) return 0.0;
    return ((_presentCount + _lateCount) / _totalWorkingDaysMarked) * 100;
  }

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

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);

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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // 1. Overview Attendance & Percentage Card
                  _buildPercentageOverviewCard(),

                  const SizedBox(height: 20),

                  // 2. Month Selector Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Calendar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded, color: _textDark),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Text(
                            monthLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded, color: _textDark),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 3. Calendar Grid (With Attendance & Holiday Highlights)
                  _buildCalendarGrid(),

                  const SizedBox(height: 20),

                  // 4. Selected Date Detail Card
                  _buildSelectedDateDetailCard(),

                  const SizedBox(height: 24),

                  // 5. Recent Activity Logs List
                  const Text(
                    'Attendance Log History',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAttendanceLogList(),
                ],
              ),
            ),
    );
  }

  // ── 1. Attendance Percentage Summary Card ──────────────────────────────
  Widget _buildPercentageOverviewCard() {
    final pctStr = _attendancePercentage.toStringAsFixed(1);
    final color = _attendancePercentage >= 75
        ? _success
        : _attendancePercentage >= 50
            ? _amber
            : _danger;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attendance Rate',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$pctStr%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _attendancePercentage >= 75 ? 'Good' : 'Needs Focus',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Circular Progress Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: _totalWorkingDaysMarked == 0 ? 0 : _attendancePercentage / 100,
                      strokeWidth: 6,
                      backgroundColor: _bg,
                      color: color,
                    ),
                  ),
                  Icon(
                    _attendancePercentage >= 75
                        ? Icons.verified_rounded
                        : Icons.info_rounded,
                    color: color,
                    size: 26,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 16),

          // Mini metrics breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('Present', '$_presentCount', _success, _successSoft),
              _buildMiniMetric('Late', '$_lateCount', _amber, _amberSoft),
              _buildMiniMetric('Absent', '$_absentCount', _danger, _dangerSoft),
              _buildMiniMetric('Total Days', '$_totalWorkingDaysMarked', _primary, _primarySoft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color, Color bg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  // ── 3. Calendar Grid View ──────────────────────────────────────────────
  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final paddingDays = firstWeekday % 7; // Sunday = 7 -> 0 offset

    final weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) {
              final isSun = d == 'Sun';
              return SizedBox(
                width: 36,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSun ? _danger : _textMuted,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: paddingDays + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < paddingDays) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - paddingDays + 1;
              final dateObj = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final dateStr = DateFormat('yyyy-MM-dd').format(dateObj);

              final rec = _recordsByDate[dateStr];
              final hol = _holidaysByDate[dateStr];

              final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dateStr;
              final isWorkingDayException = hol?['type'] == 'working_day';
              final isHoliday = hol != null && !isWorkingDayException;

              Color cellBg = _bg;
              Color textColor = _textDark;
              Widget? badgeWidget;

              if (rec != null) {
                final status = rec['status'];
                if (status == 'Present') {
                  cellBg = _successSoft;
                  textColor = _success;
                  badgeWidget = const Icon(Icons.check_circle_rounded, size: 10, color: _success);
                } else if (status == 'Absent') {
                  cellBg = _dangerSoft;
                  textColor = _danger;
                  badgeWidget = const Icon(Icons.cancel_rounded, size: 10, color: _danger);
                } else if (status == 'Late') {
                  cellBg = _amberSoft;
                  textColor = _amber;
                  badgeWidget = const Icon(Icons.access_time_filled_rounded, size: 10, color: _amber);
                }
              } else if (isHoliday) {
                cellBg = _violetSoft;
                textColor = _violet;
                badgeWidget = const Text(
                  'H',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: _violet,
                  ),
                );
              }

              return InkWell(
                onTap: () => setState(() => _selectedDate = dateObj),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: cellBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _primary : (isHoliday ? _violet.withValues(alpha: 0.3) : _border),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                          color: isSelected ? _primary : textColor,
                        ),
                      ),
                      if (badgeWidget != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: badgeWidget,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 4. Selected Date Detail Card ───────────────────────────────────────
  Widget _buildSelectedDateDetailCard() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formattedTitle = DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate);

    final rec = _recordsByDate[dateStr];
    final hol = _holidaysByDate[dateStr];
    final isWorkingDayException = hol?['type'] == 'working_day';
    final isHoliday = hol != null && !isWorkingDayException;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedTitle,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              if (isHoliday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _violetSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Holiday',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _violet,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (isHoliday) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _violetSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.beach_access_rounded, color: _violet, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${hol['title'] ?? "Holiday"} — School is closed today.',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _violet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (rec != null) ...[
            Row(
              children: [
                Icon(
                  rec['status'] == 'Present'
                      ? Icons.check_circle_rounded
                      : rec['status'] == 'Late'
                          ? Icons.access_time_filled_rounded
                          : Icons.cancel_rounded,
                  color: rec['status'] == 'Present'
                      ? _success
                      : rec['status'] == 'Late'
                          ? _amber
                          : _danger,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Status: ${rec['status']}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: rec['status'] == 'Present'
                        ? _success
                        : rec['status'] == 'Late'
                            ? _amber
                            : _danger,
                  ),
                ),
              ],
            ),
            if (rec['in_time'] != null || rec['out_time'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (rec['in_time'] != null) ...[
                    const Icon(Icons.login_rounded, size: 14, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Check In: ${_formatTimeString(rec['in_time'])}',
                      style: const TextStyle(fontSize: 12.5, color: _textDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                  if (rec['in_time'] != null && rec['out_time'] != null)
                    const SizedBox(width: 16),
                  if (rec['out_time'] != null) ...[
                    const Icon(Icons.logout_rounded, size: 14, color: _textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Check Out: ${_formatTimeString(rec['out_time'])}',
                      style: const TextStyle(fontSize: 12.5, color: _textDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ],
          ] else ...[
            const Text(
              'No attendance record marked for this date.',
              style: TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  // ── 5. Attendance Log List ─────────────────────────────────────────────
  Widget _buildAttendanceLogList() {
    if (_attendanceRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No attendance records found yet.',
            style: TextStyle(color: _textMuted, fontSize: 13.5),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final rec = _attendanceRecords[index];
        final date = rec['date'] ?? '';
        final status = rec['status'] ?? '';
        final isPresent = status == 'Present';
        final isLate = status == 'Late';

        final color = isPresent ? _success : (isLate ? _amber : _danger);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPresent
                    ? Icons.check_circle_rounded
                    : isLate
                        ? Icons.access_time_filled_rounded
                        : Icons.cancel_rounded,
                color: color,
                size: 20,
              ),
            ),
            title: Text(
              date,
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
            subtitle: Text(
              'Status: $status',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
