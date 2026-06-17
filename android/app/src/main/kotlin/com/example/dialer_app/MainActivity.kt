package com.example.dialer_app

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Bundle
import android.telecom.TelecomManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.dialer_app/calls"
    private var activeCall: android.telecom.Call? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

                    else -> result.notImplemented()
                }
            }
    }

    private fun placeCall(number: String) {
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val uri = Uri.fromParts("tel", number, null)
        val extras = Bundle()
        telecomManager.placeCall(uri, extras)
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle incoming call intent when app is already running
        if (intent.action == Intent.ACTION_CALL || intent.action == Intent.ACTION_DIAL) {
            val uri = intent.data
            if (uri != null) {
                val number = uri.schemeSpecificPart
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "onIncomingCallIntent",
                        mapOf("number" to number)
                    )
                }
            }
        }
    }
}
