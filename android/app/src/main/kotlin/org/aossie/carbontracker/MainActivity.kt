package org.aossie.carbontracker

import android.app.Activity
import android.util.Log
import androidx.activity.result.contract.ActivityResultContracts
import androidx.health.connect.client.ExperimentalMatchmakingApi
import androidx.health.connect.client.HealthConnectClient
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.health.connect.client.HealthConnectFeatures
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.matchmaking.MatchmakingRequest
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.*
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterFragmentActivity


import kotlinx.coroutines.launch

class MainActivity : FlutterFragmentActivity() {

    /* Note:
       Errors are not returned in some cases because those outcomes do not
       prevent the user from using the app. The associated operations are
       optional and are only intended to help users connect with compatible
       health applications and services.
    */

    private lateinit var channel: MethodChannel

    private lateinit var client: HealthConnectClient

    private var pendingResult: MethodChannel.Result? = null

    private val permissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
        HealthPermission.getReadPermission(BloodPressureRecord::class),
        HealthPermission.getReadPermission(FloorsClimbedRecord::class),
    )

    // Launcher for the matchmaking flow. This will be used to start the matchmaking activity and handle its result.

    private val matchmakingLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        if (result.resultCode == Activity.RESULT_OK) {

            pendingResult?.success(
                mapOf(
                    "status" to "completed", "message" to "matchmaking flow completed successfully."
                )
            )
        } else {

            pendingResult?.success(
                mapOf(
                    "status" to "cancelled", "message" to "matchmaking flow was canceled."
                )
            )
        }

        pendingResult = null
    }

    // Request permissions for Health Connect.

    @OptIn(ExperimentalMatchmakingApi::class)
    private val requestPermissionsLauncher = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions ->

        Log.d("HC", "Permission callback fired")

        if (grantedPermissions.containsAll(permissions)) {

            // All required permissions were granted, proceed with matchmaking.

            Log.d("HC", "Granted permissions: $grantedPermissions")


            if (client.features.getFeatureStatus(
                    HealthConnectFeatures.FEATURE_MATCHMAKING
                ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            ) {
                // Feature is available

                Log.d("HC", "Granted permissions: $grantedPermissions")

                lifecycleScope.launch {
                    try {
                        performMatchmaking()
                    } catch (e: Exception) {
                        pendingResult?.error(
                            "MATCHMAKING_ERROR", e.message, null
                        )
                        pendingResult = null
                    }
                }

            } else {

                Log.d("HC", "Matchmaking feature is unavailable")

                pendingResult?.success(
                    mapOf(
                        "status" to "not_available",
                        "message" to "Matchmaking is not available on this device"
                    )
                )

                pendingResult = null

            }

        } else {
            // Handle the case where permissions were not granted.
            pendingResult?.error(
                "PERMISSION_DENIED", "Required permissions were not granted", null
            )

            pendingResult = null
        }

    }


    @OptIn(ExperimentalMatchmakingApi::class)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "org.aossie.carbon_tracker/matchmaking"
        )

        channel.setMethodCallHandler { call, result ->

            pendingResult = result

            if (call.method == "showMatchmakingModal") {

                val status = HealthConnectClient.getSdkStatus(this)

                Log.d("HC", "SDK Status = $status")

                if (status != HealthConnectClient.SDK_AVAILABLE) {
                    result.error(
                        "HEALTH_CONNECT_UNAVAILABLE", "Health Connect is unavailable", null
                    )
                    return@setMethodCallHandler
                }

                client = HealthConnectClient.getOrCreate(this)


                lifecycleScope.launch {

                    val grantedPermissions = client.permissionController.getGrantedPermissions()

                    if (!grantedPermissions.containsAll(permissions)) {
                        requestPermissionsLauncher.launch(permissions)
                        return@launch
                    } else {

                        try {
                            performMatchmaking()
                        } catch (e: Exception) {
                            pendingResult?.error(
                                "MATCHMAKING_ERROR", e.message, null
                            )
                            pendingResult = null
                        }

                    }

                }

            } else {
                result.notImplemented()
            }
        }
    }


    // Check if matchmaking is possible by checking if the user has granted any permissions for the specified record types.
    @OptIn(ExperimentalMatchmakingApi::class)
    private suspend fun checkMatchmakingPossible(): Boolean {
        val request = MatchmakingRequest()
        val response = client.checkIfMatchmakingIsPossible(request)

        return response.isMatchmakingPossible
    }

    // Launch the matchmaking flow using the HealthConnectClient.

    @OptIn(ExperimentalMatchmakingApi::class)
    private fun launchMatchmaking() {
        val request = MatchmakingRequest()
        val intent = client.createMatchmakingIntent(request)

        matchmakingLauncher.launch(intent)
    }

    private suspend fun performMatchmaking() {
        if (checkMatchmakingPossible()) {

            Log.d("HC", "Launching matchmaking request")

            launchMatchmaking()
        } else {

            // Matchmaking is not possible on this device.

            Log.d(
                "HC", "Matchmaking isn't possible. User may not have granted permissions."
            )

            pendingResult?.success(
                mapOf(
                    "status" to "not_possible",
                    "message" to "Matchmaking isn't possible on this device."
                )
            )

            pendingResult = null
        }
    }
}
