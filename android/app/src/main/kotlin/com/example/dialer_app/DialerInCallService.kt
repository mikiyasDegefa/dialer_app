package com.example.dialer_app

import android.telecom.Call
import android.telecom.InCallService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

object CallConnection {
    var activeCall: Call? = null
    var eventSink: EventChannel.EventSink? = null

    fun sendState(state: String) {
        eventSink?.success(state)
    }
}

class DialerInCallService : InCallService() {

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            val stateName = when (state) {
                Call.STATE_DIALING      -> "dialing"
                Call.STATE_RINGING      -> "ringing"
                Call.STATE_ACTIVE       -> "active"
                Call.STATE_HOLDING      -> "holding"
                Call.STATE_DISCONNECTED -> "disconnected"
                Call.STATE_CONNECTING   -> "connecting"
                else                    -> "unknown"
            }
            CallConnection.sendState(stateName)
        }
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        CallConnection.activeCall = call
        call.registerCallback(callCallback)
        // Send initial state
        val initialState = when (call.state) {
            Call.STATE_DIALING      -> "dialing"
            Call.STATE_RINGING      -> "ringing"
            Call.STATE_ACTIVE       -> "active"
            Call.STATE_CONNECTING   -> "connecting"
            else                    -> "dialing"
        }
        CallConnection.sendState(initialState)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        CallConnection.sendState("disconnected")
        if (CallConnection.activeCall == call) {
            CallConnection.activeCall = null
        }
    }
}
