package org.aossie.carbontracker.channels

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object WearChannel {

    private lateinit var methodChannel: MethodChannel

    fun initialize(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "org.aossie.carbon_tracker/wear_connection"
        )
    }

    fun setMethodHandler(context: Context) {

        methodChannel.setMethodCallHandler { call, result ->
            val nodeClient = Wearable.getNodeClient(context)

            GoogleApiAvailability.getInstance()
                .checkApiAvailability(nodeClient)
                .addOnSuccessListener {

                    nodeClient.connectedNodes
                        .addOnSuccessListener { nodes ->

                            if (nodes.isNotEmpty()) {

                                val node = nodes.first()

                                if (call.method == "getHeartRate") {


                                    Log.d(
                                        "WearChannel",
                                        "Sending heart rate request to node: ${node.displayName}"
                                    )

                                    Wearable.getMessageClient(context)
                                        .sendMessage(
                                            node.id,
                                            "/requestHeartRate",
                                            ByteArray(0)
                                        )
                                        .addOnSuccessListener {
                                            Log.d(
                                                "WearChannel",
                                                "Sent /requestHeartRate successfully"
                                            )
                                            result.success(true)
                                        }
                                        .addOnFailureListener {
                                            Log.e(
                                                "WearChannel",
                                                "Failed to send /requestHeartRate",
                                                it
                                            )

                                            result.error(
                                                "WearChannel",
                                                "Failed to send /requestHeartRate: ${it.message}",
                                                null
                                            )
                                        }

                                } else if (call.method == "getExerciseData") {
                                    Log.d(
                                        "WearChannel",
                                        "Sending exercise data request to node: ${node.displayName}"
                                    )

                                    Wearable.getMessageClient(context)
                                        .sendMessage(
                                            node.id,
                                            "/requestExerciseData",
                                            ByteArray(0)
                                        )
                                        .addOnSuccessListener {
                                            Log.d(
                                                "WearChannel",
                                                "Sent /requestExerciseData successfully"
                                            )
                                        }
                                        .addOnFailureListener {
                                            Log.e(
                                                "WearChannel",
                                                "Failed to send /requestExerciseData",
                                                it
                                            )
                                        }
                                } else {
                                    result.notImplemented()
                                }
                            } else {
                                result.error(
                                    "WearChannel",
                                    "No connected nodes found",
                                    null
                                )
                            }
                        }


//                                if (call.method == "checkWearConnection") {
//
//
//
//                                }


//                            Log.d(
//                                "WearChannel",
//                                "Connected nodes: ${nodes.map { it.isNearby }}"
//                            )

//                                nodes
//                                    .filter { it.isNearby }
//                                    .forEach { node ->
//
//                                        Log.d(
//                                            "WearChannel",
//                                            "Sending request to node: ${node.displayName}"
//                                        )
//                                        Wearable.getMessageClient(context)
//                                            .sendMessage(
//                                                node.id,
//                                                "/requestWatchData",
//                                                ByteArray(0)
//                                            )
//                                            .addOnSuccessListener {
//                                                Log.d(
//                                                    "WearChannel",
//                                                    "Message sent successfully to ${node.displayName}"
//                                                )
//                                            }
//                                            .addOnFailureListener { exception ->
//                                                Log.e(
//                                                    "WearChannel",
//                                                    "Failed to send message to ${node.displayName}",
//                                                    exception
//                                                )
//
//                                            }

//                                result.success(true)
                }
                .addOnFailureListener { exception ->
                    result.error(
                        "WEAR_API_UNAVAILABLE",
                        "Wearable API is not available: ${exception.message}",
                        null
                    )
                }
        }


//            else if (call.method == "getHeartRate") {
//                val healthServicesManager = HealthServicesManager(context)
//                val heartRate = healthServicesManager.getHeartRate()
//
//                result.success(heartRate)
//            }
//
//            else {
//                result.notImplemented()
//            }
    }


    fun sendToFlutter(data: String, path: String) {
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod(path, data)
        }
    }
}
