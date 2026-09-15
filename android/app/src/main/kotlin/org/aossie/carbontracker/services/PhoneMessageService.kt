package org.aossie.carbontracker.services

import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.aossie.carbontracker.channels.WearChannel

class PhoneMessageService : WearableListenerService() {

    override fun onCreate() {
        super.onCreate()
        Log.d(
            "PhoneMessageService",
            "SERVICE CREATED"
        )
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {

        Log.d(
            "WearListenerService",
            "MESSAGE RECEIVED: ${messageEvent.path} on node ${messageEvent.sourceNodeId}"
        )

        if (messageEvent.path == "/watchData") {
            WearChannel.sendToFlutter(String(messageEvent.data))
        }
    }
}
