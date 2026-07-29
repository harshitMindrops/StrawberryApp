import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:strawberry/features/payments/payment_service.dart';

class PaymentHistoryPage extends StatefulWidget {
  final String studentId;

  const PaymentHistoryPage({super.key, required this.studentId});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final _paymentService = PaymentService();
  bool _loading = true;
  List<Map<String, dynamic>> _payments = [];

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);
  static const Color _success = Color(0xFF22B07D);
  static const Color _danger = Color(0xFFEF4949);
  static const Color _pending = Color(0xFFF5A623);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _paymentService.getPaymentsForStudent(widget.studentId);
      if (!mounted) return;
      setState(() {
        _payments = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final m = int.tryParse(parts[1]) ?? 0;
    return '${months[m]} ${parts[0]}';
  }

  (Color, IconData, String) _statusMeta(String status) {
    switch (status) {
      case 'success':
        return (_success, Icons.check_circle_rounded, 'Paid');
      case 'failed':
        return (_danger, Icons.cancel_rounded, 'Failed');
      case 'cancelled':
        return (_danger, Icons.close_rounded, 'Cancelled');
      case 'submitted':
        return (_pending, Icons.hourglass_top_rounded, 'Processing');
      default:
        return (_pending, Icons.schedule_rounded, 'Initiated');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Payment History',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _payments.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.receipt_long_rounded, size: 56, color: _textMuted),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'No payments yet',
                          style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    itemCount: _payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final p = _payments[i];
                      final (color, icon, label) =
                          _statusMeta(p['status'] as String? ?? 'initiated');
                      final createdAt = DateTime.tryParse(p['created_at'] ?? '');
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatMonthKey(p['month_key'] ?? ''),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${p['upi_app'] ?? 'UPI'} · ${createdAt != null ? DateFormat('d MMM y, h:mm a').format(createdAt) : ''}',
                                    style: const TextStyle(fontSize: 12, color: _textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${(p['amount'] as num?)?.toStringAsFixed(0) ?? '0'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
