import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/auth/auth_service.dart';

/// Admin-facing attendance history for a single student.
/// Shows overall stats (present/absent/late/percentage) + a GitHub-style
/// calendar heatmap the admin can page through month by month.
class StudentAttendanceHistoryPage extends StatefulWidget {
  final Map<String, dynamic> student;
  final AuthService authService;

  const StudentAttendanceHistoryPage({
    super.key,
    required this.student,
    required this.authService,
  });

  @override
  State<StudentAttendanceHistoryPage> createState() =>
      _StudentAttendanceHistoryPageState();
}

class _StudentAttendanceHistoryPageState
    extends State<StudentAttendanceHistoryPage> {
  // ── Palette (mirrors rest of admin panel) ──────────────────────────
  static const _primary = Color(0xFFE94464);
  static const _primarySoft = Color(0xFFFFE7EC);
  static const _primaryDark = Color(0xFFD32F52);
  static const _accentPeach = Color(0xFFFF8FA3);
  static const _bg = Color(0xFFF6F6FB);
  static const _surface = Colors.white;
  static const _border = Color(0xFFEDEDF4);
  static const _textDark = Color(0xFF1E1B24);
  static const _textMuted = Color(0xFF8A8794);
  static const _success = Color(0xFF22B07D);
  static const _successSoft = Color(0xFFE4F6E8);
  static const _danger = Color(0xFFEF4949);
  static const _dangerSoft = Color(0xFFFBE7E6);
  static const _amber = Color(0xFFF5A623);
  static const _amberSoft = Color(0xFFFCF0DD);

  bool _loading = true;
  String? _error;

  // date(yyyy-MM-dd) -> status
  Map<String, String> _statusByDate = {};

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final records = await widget.authService
          .getStudentAttendance(widget.student['id'] as String);
      final map = <String, String>{};
      for (final r in records) {
        final date = r['date']?.toString();
        final status = r['status']?.toString();
        if (date != null && status != null) {
          map[date] = status;
        }
      }
      if (!mounted) return;
      setState(() {
        _statusByDate = map;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load attendance history.';
        _loading = false;
      });
    }
  }

  // ── Derived stats (all-time) ─────────────────────────────────────────
  int get _presentCount =>
      _statusByDate.values.where((s) => s == 'Present').length;
  int get _absentCount =>
      _statusByDate.values.where((s) => s == 'Absent').length;
  int get _lateCount => _statusByDate.values.where((s) => s == 'Late').length;
  int get _totalMarked => _statusByDate.length;
  double get _percentage {
    if (_totalMarked == 0) return 0;
    // Present + Late both count as "attended" for the percentage.
    return ((_presentCount + _lateCount) / _totalMarked) * 100;
  }

  // ── Derived stats (for currently visible month) ─────────────────────
  Map<String, int> get _monthStats {
    int p = 0, a = 0, l = 0;
    _statusByDate.forEach((date, status) {
      final d = DateTime.tryParse(date);
      if (d == null) return;
      if (d.year == _visibleMonth.year && d.month == _visibleMonth.month) {
        if (status == 'Present') p++;
        if (status == 'Absent') a++;
        if (status == 'Late') l++;
      }
    });
    return {'present': p, 'absent': a, 'late': l};
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  Color _colorFor(String? status) {
    switch (status) {
      case 'Present':
        return _success;
      case 'Absent':
        return _danger;
      case 'Late':
        return _amber;
      default:
        return _border;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Student';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: _border, width: 1)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Attendance History',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _textDark)),
            Text(name,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w500, color: _textMuted)),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _primary),
            )
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 22),
                      _buildPercentageRing(),
                      const SizedBox(height: 26),
                      _buildCalendarHeader(),
                      const SizedBox(height: 12),
                      _buildCalendarGrid(),
                      const SizedBox(height: 16),
                      _buildLegend(),
                    ],
                  ),
                ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Present',
            value: '$_presentCount',
            color: _success,
            bg: _successSoft,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Absent',
            value: '$_absentCount',
            color: _danger,
            bg: _dangerSoft,
            icon: Icons.cancel_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Late',
            value: '$_lateCount',
            color: _amber,
            bg: _amberSoft,
            icon: Icons.schedule_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageRing() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _accentPeach],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _totalMarked == 0 ? 0 : (_percentage / 100).clamp(0, 1),
                  strokeWidth: 7,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Text(
                  '${_percentage.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Attendance',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  _totalMarked == 0
                      ? 'No attendance marked yet'
                      : 'Present + Late out of $_totalMarked marked day${_totalMarked == 1 ? '' : 's'}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonth);
    final stats = _monthStats;
    final now = DateTime.now();
    final isCurrentOrFuture =
        _visibleMonth.year > now.year ||
            (_visibleMonth.year == now.year && _visibleMonth.month >= now.month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Calendar', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: _textDark)),
            Row(
              children: [
                _RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _changeMonth(-1),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 118,
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700, color: _textDark),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundIconButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: isCurrentOrFuture ? null : () => _changeMonth(1),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('${stats['present']} present',
                style: const TextStyle(
                    color: _success, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('${stats['absent']} absent',
                style: const TextStyle(
                    color: _danger, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Text('${stats['late']} late',
                style: const TextStyle(
                    color: _amber, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // Weekday: Monday=1 ... Sunday=7. Convert so grid starts on Monday.
    final leadingBlanks = firstDayOfMonth.weekday - 1;

    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _textMuted)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) return const SizedBox.shrink();
              final day = index - leadingBlanks + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final dateKey = DateFormat('yyyy-MM-dd').format(date);
              final status = _statusByDate[dateKey];
              final isFuture = date.isAfter(DateTime.now());
              final color = isFuture
                  ? Colors.transparent
                  : _colorFor(status).withOpacity(status == null ? 0.5 : 0.18);
              final dotColor = _colorFor(status);
              final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

              return Tooltip(
                message: status ?? (isFuture ? '' : 'No record'),
                child: Container(
                  decoration: BoxDecoration(
                    color: isFuture ? Colors.transparent : color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday ? _primary : Colors.transparent,
                      width: 1.4,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isFuture ? _textMuted.withOpacity(0.4) : _textDark,
                        ),
                      ),
                      if (!isFuture && status != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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

  Widget _buildLegend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: _textMuted, fontWeight: FontWeight.w600)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        dot(_success, 'Present'),
        dot(_danger, 'Absent'),
        dot(_amber, 'Late'),
        dot(_border, 'No record'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.85))),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: disabled
              ? _StudentAttendanceHistoryPageState._bg
              : _StudentAttendanceHistoryPageState._primarySoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 18,
          color: disabled
              ? _StudentAttendanceHistoryPageState._textMuted.withOpacity(0.4)
              : _StudentAttendanceHistoryPageState._primaryDark,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: _StudentAttendanceHistoryPageState._danger),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _StudentAttendanceHistoryPageState._textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _StudentAttendanceHistoryPageState._primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
