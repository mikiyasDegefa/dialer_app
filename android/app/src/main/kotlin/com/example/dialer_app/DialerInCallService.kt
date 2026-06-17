package com.example.dialer_app

import android.telecom.Call
import android.telecom.InCallService

object CallConnection {
    var activeCall: Call? = null
}

class DialerInCallService : InCallService() {

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        CallConnection.activeCall = call
        call.registerCallback(callCallback)
    }

    override fun onCallRemoved(call: Call) {
        super.onCallRemoved(call)
        call.unregisterCallback(callCallback)
        if (CallConnection.activeCall == call) {
            CallConnection.activeCall = null
        }
    }

    private val callCallback = object : Call.Callback() {
        override fun onStateChanged(call: Call, state: Int) {
            super.onStateChanged(call, state)
            // State changes can be forwarded to Flutter via EventChannel if needed
        }
    }
}
