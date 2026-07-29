import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:strawberry/core/upi_config.dart';
import 'package:strawberry/features/auth/auth_service.dart';

/// Result of a single "Pay Now" attempt.
class UpiPaymentResult {
  final bool launched;
  final String rowId;

  UpiPaymentResult({required this.launched, required this.rowId});
}

/// Handles UPI fee payments via a plain `upi://pay` deep link, and logs
/// every attempt to the `fee_payments` Supabase table so it shows up in
/// both the student's payment history and the admin's tracking screen.
///
/// Deliberately uses only `url_launcher` (no native UPI plugin). The
/// well-known Flutter UPI plugins (upi_india, flutter_upi_india, upi_pay,
/// etc.) are all effectively unmaintained since ~2021-2023 and fail to
/// build on modern Android Gradle Plugin / Gradle versions (jcenter(),
/// old `kotlin-android` config, etc.). A raw deep link has one trade-off:
/// Android shows the UPI app chooser and completes the transfer, but the
/// UPI app does not report a success/failure result back to this app
/// (that response channel is only available through those native
/// plugins). So:
///   - Every attempt is logged as soon as the link is opened.
///   - The student can mark it "I've completed the payment" from the app,
///     which flips status to `submitted`.
///   - The admin does the final "confirm" (same as the school's existing
///     manual fee-marking flow) after checking the bank statement — this
///     was already the source of truth for this app before UPI existed,
///     so nothing here weakens that.
class PaymentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Generates a short, unique-enough alphanumeric reference for the `tr`
  /// (transaction reference) param — UPI requires this to be <= 35 chars.
  String generateTxnRef(String studentId) {
    final shortId = studentId.length > 6
        ? studentId.substring(0, 6)
        : studentId;
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    final raw = 'SB${DateTime.now().millisecondsSinceEpoch}$shortId$rand'
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return raw.substring(0, min(35, raw.length));
  }

  /// Builds the `upi://pay?...` deep link with the school's UPI ID, payee
  /// name, amount, and a note pre-filled — this is what actually opens
  /// Google Pay / PhonePe / Paytm / any UPI app with the payment form
  /// ready to go.
  String buildUpiUri({
    required double amount,
    required String txnRef,
    required String note,
  }) {
    final params = {
      'pa': UpiConfig.vpa,
      'pn': UpiConfig.payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
      'tr': txnRef,
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  Future<String> _logPayment({
    required String studentId,
    required String studentName,
    required String monthKey,
    required double amount,
    required String txnRef,
    required String status,
  }) async {
    final row = await _client
        .from('fee_payments')
        .insert({
          'student_id': studentId,
          'student_name': studentName,
          'month_key': monthKey,
          'amount': amount,
          'txn_ref': txnRef,
          'upi_app': 'UPI',
          'status': status,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> _updateStatus(String rowId, String status) async {
    await _client
        .from('fee_payments')
        .update({'status': status}).eq('id', rowId);
  }

  /// Opens the UPI app chooser with amount + school UPI ID pre-filled,
  /// and logs the attempt. Returns whether an app actually opened.
  Future<UpiPaymentResult> payViaUpi({
    required double amount,
    required String monthKey,
    required String studentId,
    required String studentName,
  }) async {
    final txnRef = generateTxnRef(studentId);
    final rowId = await _logPayment(
      studentId: studentId,
      studentName: studentName,
      monthKey: monthKey,
      amount: amount,
      txnRef: txnRef,
      status: 'initiated',
    );

    final uri = Uri.parse(
      buildUpiUri(amount: amount, txnRef: txnRef, note: 'Fees for $monthKey'),
    );

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    await _updateStatus(rowId, launched ? 'submitted' : 'cancelled');
    return UpiPaymentResult(launched: launched, rowId: rowId);
  }

  /// Student self-report: "I've completed the payment" — keeps the row
  /// visible as submitted/awaiting confirmation. Does NOT mark fees paid
  /// by itself; the admin still confirms (see class doc above).
  Future<void> markSelfReportedPaid(String rowId) async {
    await _updateStatus(rowId, 'submitted');
  }

  /// Student self-report: payment didn't go through / was cancelled.
  Future<void> markSelfReportedFailed(String rowId) async {
    await _updateStatus(rowId, 'failed');
  }

  /// Payment history for a single student (newest first).
  Future<List<Map<String, dynamic>>> getPaymentsForStudent(
    String studentId,
  ) async {
    final rows = await _client
        .from('fee_payments')
        .select()
        .eq('student_id', studentId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// All payment attempts across every student — for the admin tracking
  /// screen (newest first).
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final rows =
        await _client.from('fee_payments').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Admin: confirm a payment after checking the bank statement, and mark
  /// the month paid on the student's profile (mirrors the existing manual
  /// "mark fees paid" flow).
  Future<void> adminConfirmPayment({
    required String rowId,
    required String studentId,
    required String monthKey,
    required AuthService authService,
  }) async {
    await _updateStatus(rowId, 'success');
    await authService.markFeesPaid(studentId, monthKey);
  }

  /// Admin: mark a payment attempt as failed/invalid.
  Future<void> adminRejectPayment(String rowId) async {
    await _updateStatus(rowId, 'failed');
  }
}