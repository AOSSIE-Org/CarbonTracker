package org.aossie.carbontracker.channels

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

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

                            val node = nodes.firstOrNull { it.isNearby }

                            if (node == null) {
                                result.error(
                                    "WearChannel",
                                    "No nearby connected nodes found",
                                    null
                                )
                                return@addOnSuccessListener
                            }

                            when (call.method) {
                                "getHeartRate" -> {


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

                                }

                                "getExerciseData" -> {
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

                                            result.success(true)
                                        }
                                        .addOnFailureListener {
                                            Log.e(
                                                "WearChannel",
                                                "Failed to send /requestExerciseData",
                                                it
                                            )

                                            result.error(
                                                "WearChannel",
                                                "Failed to send /requestExerciseData: ${it.message}",
                                                null
                                            )
                                        }
                                }

                                "exerciseDataReceived" -> {

                                    val data = call.argument<List<Map<String, Any>>>("data")

                                    if (data == null) {
                                        result.error(
                                            "WearChannel",
                                            "Missing 'data' argument",
                                            null
                                        )
                                        return@addOnSuccessListener
                                    }

                                    val dataJson = JSONArray(data).toString()

                                    Wearable.getMessageClient(context)
                                        .sendMessage(
                                            node.id,
                                            "/markExercisesAsSynced",
                                            dataJson.toByteArray()
                                        )
                                        .addOnSuccessListener {
                                            Log.d(
                                                "WearChannel",
                                                "Sent /markExercisesAsSynced successfully"
                                            )

                                            result.success(true)
                                        }
                                        .addOnFailureListener {
                                            Log.e(
                                                "WearChannel",
                                                "Failed to send /markExercisesAsSynced",
                                                it
                                            )
                                            result.error(
                                                "WearChannel",
                                                "Failed to send /markExercisesAsSynced: ${it.message}",
                                                null
                                            )
                                        }
                                }

                                else -> {
                                    result.notImplemented()
                                }
                            }

                        }

                        .addOnFailureListener { exception ->
                            result.error(
                                "WearChannel",
                                "Failed to get connected nodes: ${exception.message}",
                                null
                            )
                        }

                }
                .addOnFailureListener { exception ->
                    result.error(
                        "WEAR_API_UNAVAILABLE",
                        "Wearable API is not available: ${exception.message}",
                        null
                    )
                }
        }
    }


    fun sendToFlutter(data: String, path: String) {
        Handler(Looper.getMainLooper()).post {
            methodChannel.invokeMethod(path, data)
        }
    }
}
