package com.harshit.strawberry

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Launches a `upi://pay` deep link with `startActivityForResult` (instead
/// of a plain `startActivity`) so that when the UPI app (GPay/PhonePe/Paytm/
/// etc.) finishes, its result — success/failure/submitted status plus the
/// bank's transaction id — comes straight back to this method channel.
///
/// This replaces the old `upi_india` plugin (unmaintained, breaks on modern
/// AGP) with the same underlying Android mechanism it used internally, just
/// written directly against the platform APIs so there's no third-party
/// plugin to go stale.
class MainActivity : FlutterActivity() {
    private val channelName = "strawberry/upi"
    private val upiRequestCode = 94810

    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "payWithUpi" -> {
                        val uri = call.argument<String>("uri")
                        if (uri.isNullOrBlank()) {
                            result.error("NO_URI", "Missing UPI uri", null)
                            return@setMethodCallHandler
                        }
                        // Only one payment can be in flight at a time from this screen.
                        pendingResult = result
                        try {
                            val intent = Intent(Intent.ACTION_VIEW).apply {
                                data = Uri.parse(uri)
                            }
                            @Suppress("DEPRECATION")
                            startActivityForResult(intent, upiRequestCode)
                        } catch (e: ActivityNotFoundException) {
                            pendingResult?.success(
                                mapOf(
                                    "resultCode" to -100,
                                    "raw" to null,
                                    "noAppFound" to true,
                                ),
                            )
                            pendingResult = null
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    @Deprecated("Deprecated in Java, still the correct API for capturing a UPI app's result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != upiRequestCode) return

        // UPI apps that follow the NPCI spec put the result in an extra
        // called "response", e.g. "txnId=...&responseCode=...&Status=SUCCESS&..."
        // Some apps use "Response" (capital R) instead, so check both.
        val response = data?.getStringExtra("response") ?: data?.getStringExtra("Response")

        pendingResult?.success(
            mapOf(
                "resultCode" to resultCode,
                "raw" to response,
                "noAppFound" to false,
            ),
        )
        pendingResult = null
    }
}