package com.example.dialer_app

import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.media.AudioManager
import android.net.Uri
import android.os.Bundle
import android.provider.CallLog
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL       = "com.example.dialer_app/calls"
    private val EVENT_CHANNEL = "com.example.dialer_app/call_state"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── EventChannel: streams real call state to Flutter ──────────────
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    CallConnection.eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    CallConnection.eventSink = null
                }
            })

        // ── MethodChannel: call controls ──────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "placeCall" -> {
                        val number = call.argument<String>("number") ?: ""
                        placeCall(number)
                        result.success(null)
                    }

                    "endCall" -> {
                        CallConnection.activeCall?.disconnect()
                        result.success(null)
                    }

                    "setMute" -> {
                        val muted = call.argument<Boolean>("muted") ?: false
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audio.isMicrophoneMute = muted
                        result.success(null)
                    }

                    "setSpeaker" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        audio.isSpeakerphoneOn = on
                        result.success(null)
                    }

                    "sendDtmf" -> {
                        val digit = call.argument<String>("digit") ?: ""
                        if (digit.isNotEmpty()) {
                            CallConnection.activeCall?.playDtmfTone(digit[0])
                            CallConnection.activeCall?.stopDtmfTone()
                        }
                        result.success(null)
                    }

                    "setHold" -> {
                        val hold = call.argument<Boolean>("hold") ?: false
                        if (hold) {
                            CallConnection.activeCall?.hold()
                        } else {
                            CallConnection.activeCall?.unhold()
                        }
                        result.success(null)
                    }

                    "requestDefaultDialer" -> {
                        requestDefaultDialer()
                        result.success(null)
                    }

                    "isDefaultDialer" -> {
                        result.success(isDefaultDialer())
                    }

                    "getCallLog" -> {
                        result.success(getCallLog())
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun placeCall(number: String) {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val uri = Uri.fromParts("tel", number, null)
        telecomManager.placeCall(uri, Bundle())
    }

    private fun requestDefaultDialer() {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        if (telecomManager.defaultDialerPackage != packageName) {
            val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER)
                .putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, packageName)
            startActivity(intent)
        }
    }

    private fun isDefaultDialer(): Boolean {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        return telecomManager.defaultDialerPackage == packageName
    }

    private fun getCallLog(): List<Map<String, Any?>> {
        val entries = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            CallLog.Calls.CACHED_NAME,
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION
        )
        val cursor: Cursor? = contentResolver.query(
            CallLog.Calls.CONTENT_URI, projection, null, null,
            "${CallLog.Calls.DATE} DESC"
        )
        cursor?.use {
            val nameIdx     = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
            val numberIdx   = it.getColumnIndex(CallLog.Calls.NUMBER)
            val typeIdx     = it.getColumnIndex(CallLog.Calls.TYPE)
            val dateIdx     = it.getColumnIndex(CallLog.Calls.DATE)
            val durationIdx = it.getColumnIndex(CallLog.Calls.DURATION)
            while (it.moveToNext()) {
                val typeStr = when (it.getInt(typeIdx)) {
                    CallLog.Calls.INCOMING_TYPE -> "incoming"
                    CallLog.Calls.OUTGOING_TYPE -> "outgoing"
                    CallLog.Calls.MISSED_TYPE   -> "missed"
                    CallLog.Calls.REJECTED_TYPE -> "rejected"
                    else                        -> "unknown"
                }
                entries.add(mapOf(
                    "name"      to it.getString(nameIdx),
                    "number"    to it.getString(numberIdx),
                    "callType"  to typeStr,
                    "timestamp" to it.getLong(dateIdx),
                    "duration"  to it.getInt(durationIdx)
                ))
                if (entries.size >= 100) break
            }
        }
        return entries
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.action == Intent.ACTION_CALL || intent.action == Intent.ACTION_DIAL) {
            val number = intent.data?.schemeSpecificPart ?: return
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, CHANNEL)
                    .invokeMethod("onIncomingCallIntent", mapOf("number" to number))
            }
        }
    }
}
