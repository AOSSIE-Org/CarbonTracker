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
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterFragmentActivity


import kotlinx.coroutines.launch
import org.aossie.carbontracker.channels.WearChannel

class MainActivity : FlutterFragmentActivity() {

    /* Note:
       Errors are not returned in some cases because those outcomes do not
       prevent the user from using the app. The associated operations are
       optional and are only intended to help users connect with compatible
       health applications and services.
    */

    private lateinit var matchmakingChannel: MethodChannel

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
            complete("completed", "matchmaking flow completed successfully.")
        } else {
            complete("cancelled", "matchmaking flow was cancelled by the user.")
        }
    }

    private fun complete(status: String, message: String) {
        pendingResult?.success(mapOf("status" to status, "message" to message))
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



            lifecycleScope.launch {
                try {
                    performMatchmaking()
                } catch (e: Exception) {
                    Log.e("HC", "Matchmaking failed", e)
                    complete("failed", e.message ?: "unknown")
                }
            }


        } else {
            // Handle the case where permissions were not granted.
            complete("permission_denied", "Required permissions were not granted")
        }

    }


    @OptIn(ExperimentalMatchmakingApi::class)
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        matchmakingChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, "org.aossie.carbon_tracker/matchmaking"
        )

        WearChannel.initialize(flutterEngine)
        WearChannel.setMethodHandler(this)
        matchmakingChannel.setMethodCallHandler { call, result ->

            if (call.method != "showMatchmakingModal") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (pendingResult != null) {
                result.success(mapOf("status" to "busy"))
                return@setMethodCallHandler
            }

            pendingResult = result

            val status = HealthConnectClient.getSdkStatus(this)

            Log.d("HC", "SDK Status = $status")

            if (status != HealthConnectClient.SDK_AVAILABLE) {
                complete("not_available", "Health Connect SDK is not available on this device")
                return@setMethodCallHandler
            }




            lifecycleScope.launch {

                try {


                    client = HealthConnectClient.getOrCreate(this@MainActivity)

                    val grantedPermissions = client.permissionController.getGrantedPermissions()

                    if (!grantedPermissions.containsAll(permissions)) {
                        requestPermissionsLauncher.launch(permissions)
                        return@launch
                    } else {


                        performMatchmaking()

                    }
                } catch (e: Exception) {
                    Log.e("HC", "Matchmaking failed", e)
                    complete("failed", e.message ?: "unknown")
                }
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

    @OptIn(ExperimentalMatchmakingApi::class)
    private suspend fun performMatchmaking() {
        val feature = client.features.getFeatureStatus(HealthConnectFeatures.FEATURE_MATCHMAKING)
        Log.d("HC", "Feature status = $feature")
        if (feature != HealthConnectFeatures.FEATURE_STATUS_AVAILABLE) {
            complete("not_available", "Matchmaking is not available on this device")
            return
        }
        val possible = checkMatchmakingPossible()
        Log.d("HC", "isMatchmakingPossible = $possible")
        if (possible) launchMatchmaking()
        else complete("not_possible", "Matchmaking isn't possible on this device")
    }
}
