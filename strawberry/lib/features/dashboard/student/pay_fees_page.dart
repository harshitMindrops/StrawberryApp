import 'package:flutter/material.dart';
import 'package:strawberry/features/auth/auth_service.dart';
import 'package:strawberry/features/payments/payment_service.dart';
import 'package:strawberry/features/dashboard/student/payment_history_page.dart';

class PayFeesPage extends StatefulWidget {
  final AuthService authService;
  final Map<String, dynamic> profile;

  const PayFeesPage({
    super.key,
    required this.authService,
    required this.profile,
  });

  @override
  State<PayFeesPage> createState() => _PayFeesPageState();
}

class _PayFeesPageState extends State<PayFeesPage> {
  final _paymentService = PaymentService();
  final _amountController = TextEditingController();

  static const Color _bg = Color(0xFFF6F6FB);
  static const Color _surface = Colors.white;
  static const Color _primary = Color(0xFFE94464);
  static const Color _primarySoft = Color(0xFFFFE7EC);
  static const Color _textDark = Color(0xFF1E1B24);
  static const Color _textMuted = Color(0xFF8A8794);
  static const Color _border = Color(0xFFEDEDF4);
  static const Color _success = Color(0xFF22B07D);
  static const Color _danger = Color(0xFFEF4949);

  String? _selectedMonth;
  bool _paying = false;

  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatMonthKey(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${_monthNames[m]} ${parts[0]}';
  }

  List<String> get _paidMonths =>
      List<String>.from((widget.profile['fees_paid_months'] as List?) ?? []);

  List<String> get _unpaidMonths {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final d = DateTime(now.year, now.month - (11 - i), 1);
      return '${d.year}-${d.month.toString().padLeft(2, '0')}';
    });
    return months.where((m) => !_paidMonths.contains(m)).toList();
  }

  double get _monthlyFee => (widget.profile['fees'] as num?)?.toDouble() ?? 0;

  @override
  void initState() {
    super.initState();
    final unpaid = _unpaidMonths;
    _selectedMonth = unpaid.isNotEmpty ? unpaid.first : null;
    _amountController.text =
        _monthlyFee > 0 ? _monthlyFee.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  Future<void> _startPayment() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      _snack('Please enter a valid amount', danger: true);
      return;
    }
    if (_selectedMonth == null) {
      _snack('Please select a month', danger: true);
      return;
    }

    setState(() => _paying = true);
    final result = await _paymentService.payViaUpi(
      amount: amount,
      monthKey: _selectedMonth!,
      studentId: widget.profile['id'],
      studentName: widget.profile['name'] ?? '',
      authService: widget.authService,
    );
    if (!mounted) return;
    setState(() => _paying = false);

    if (!result.launched) {
      _snack(
        'Could not open a UPI app. Please install Google Pay, PhonePe or Paytm.',
        danger: true,
      );
      return;
    }

    switch (result.autoStatus) {
      case 'success':
        _snack('Payment successful! Fees marked as paid. 🎉', danger: false);
        setState(() {}); // refresh unpaid-months list
        return;
      case 'failed':
        final reason = result.failureReason;
        _snack(
          reason == null
              ? 'Payment failed. Please try again.'
              : 'Payment failed ($reason)',
          danger: true,
        );
        return;
      case 'cancelled':
        _snack('Payment was cancelled.', danger: true);
        return;
      default:
        // Ambiguous outcome — fall back to asking the student, same as before.
        _showFollowUpDialog(result.rowId);
    }
  }

  void _showFollowUpDialog(String rowId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.hourglass_top_rounded, color: Color(0xFFF5A623)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Complete the Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'We opened your UPI app with the school\'s UPI ID and amount pre-filled. '
          'Once you finish it there, come back and let us know below — the school will '
          'confirm it shortly after.',
          style: TextStyle(color: _textMuted),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedFailed(rowId);
              _snack('Marked as not completed', danger: true);
            },
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text(
              'Didn\'t complete it',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _paymentService.markSelfReportedPaid(rowId);
              if (!mounted) return;
              _snack('Thanks! We\'ll confirm it shortly.', danger: false);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'I\'ve Paid',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool danger = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: danger ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unpaid = _unpaidMonths;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Pay Fees',
          style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
        ),
        actions: [
          IconButton(
            tooltip: 'Payment History',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PaymentHistoryPage(studentId: widget.profile['id']),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _primary,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monthly Fees',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _textMuted,
                        ),
                      ),
                      Text(
                        '₹${_monthlyFee.toStringAsFixed(0)}/month',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (unpaid.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.celebration_rounded, color: _success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All fees for the last 12 months are paid. 🎉',
                      style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Text(
              'Select Month',
              style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedMonth,
              dropdownColor: _surface,
              style: const TextStyle(color: _textDark),
              decoration: InputDecoration(
                filled: true,
                fillColor: _surface,
                prefixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  color: _primary,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 1.6),
                ),
              ),
              items: unpaid
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(_formatMonthKey(m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedMonth = v),
            ),
            const SizedBox(height: 20),
            const Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.w800, color: _textDark),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: _textDark,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                filled: true,
                fillColor: _surface,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _primary, width: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _paying ? null : _startPayment,
                icon: _paying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.bolt_rounded),
                label: Text(_paying ? 'Opening UPI app…' : 'Pay Now via UPI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Opens Google Pay / PhonePe / Paytm with the school\'s UPI ID and amount pre-filled. No extra charges.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _textMuted),
            ),
          ],
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    PaymentHistoryPage(studentId: widget.profile['id']),
              ),
            ),
            icon: const Icon(Icons.receipt_long_rounded, color: _primary),
            label: const Text('View Payment History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              side: const BorderSide(color: _primary),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}