package com.satishkoladiya.tel



import android.content.Context
import android.os.Build
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.TrafficStats
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.os.Handler
import android.os.Looper

import android.content.Intent
import android.content.IntentFilter
import android.telephony.SmsManager


class MainActivity : FlutterActivity() {
    private val CHANNEL = "call_control"

    private val CHANNEL_SMS = "sms_sender"

    private val CHANNEL3 = "data_usage"

    private val SENT_ACTION = "SMS_SENT"
    private val DELIVERED_ACTION = "SMS_DELIVERED"

    private var sentReceiver: BroadcastReceiver? = null
    private var deliveredReceiver: BroadcastReceiver? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "hangUpCall") {
                val success = hangUpCall()
                result.success(success)
            }
            else {
                result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL3).setMethodCallHandler { call, result ->
            if (call.method == "getMobileDataUsage") {
                val receivedBytes = TrafficStats.getMobileRxBytes() // Data received
                val sentBytes = TrafficStats.getMobileTxBytes() // Data sent
                result.success(receivedBytes)
            } else {
                result.notImplemented()
            }
        }



        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL_SMS).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")

                if (phone != null && message != null) {
                    sendSMS(phone, message, result)
                } else {
                    result.error("INVALID_ARGUMENTS", "Phone or message is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendSMS(phoneNumber: String, message: String, result: MethodChannel.Result) {
        val smsManager = SmsManager.getDefault()
        val sentIntent = Intent(SENT_ACTION)
        val deliveredIntent = Intent(DELIVERED_ACTION)

        val sentPendingIntent = PendingIntent.getBroadcast(this, 0, sentIntent, PendingIntent.FLAG_IMMUTABLE)
        val deliveredPendingIntent = PendingIntent.getBroadcast(this, 0, deliveredIntent, PendingIntent.FLAG_IMMUTABLE)

        // Sent Broadcast Receiver
        sentReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val status = when (resultCode) {
                    Activity.RESULT_OK -> "SENT"
                    SmsManager.RESULT_ERROR_GENERIC_FAILURE -> "FAILED"
                    SmsManager.RESULT_ERROR_NO_SERVICE -> "NO_SERVICE"
                    SmsManager.RESULT_ERROR_NULL_PDU -> "NULL_PDU"
                    SmsManager.RESULT_ERROR_RADIO_OFF -> "RADIO_OFF"
                    else -> "UNKNOWN_ERROR"
                }

                // Ensure result is returned safely
                handler.post {
                    try {
                        result.success(status)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
        registerReceiver(sentReceiver, IntentFilter(SENT_ACTION))

        // Delivered Broadcast Receiver
        deliveredReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val status = when (resultCode) {
                    Activity.RESULT_OK -> "DELIVERED"
                    Activity.RESULT_CANCELED -> "NOT_DELIVERED"
                    else -> "UNKNOWN_DELIVERY_STATUS"
                }

                // Ensure result is returned safely
                handler.post {
                    try {
                        result.success(status)
                    } catch (e: Exception) {
                        e.printStackTrace()
                    }
                }
            }
        }
        registerReceiver(deliveredReceiver, IntentFilter(DELIVERED_ACTION))

        // Send SMS
        try {
            smsManager.sendTextMessage(phoneNumber, null, message, sentPendingIntent, deliveredPendingIntent)
        } catch (e: Exception) {
            e.printStackTrace()
            handler.post {
                result.error("SEND_ERROR", "Failed to send SMS: ${e.localizedMessage}", null)
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        // Unregister receivers safely
        sentReceiver?.let { unregisterReceiver(it) }
        deliveredReceiver?.let { unregisterReceiver(it) }
    }

    private fun hangUpCall(): Boolean {
        return try {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                telecomManager.endCall()
                true
            } else {
                false
            }
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
