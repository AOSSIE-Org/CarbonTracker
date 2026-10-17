package org.aossie.carbontracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
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
    private lateinit var wearChannel: MethodChannel

    private lateinit var client: HealthConnectClient

    private var pendingResult: MethodChannel.Result? = null
    private var lastGrantedPermissions: List<String> = emptyList()

    // Requested permissions only for records the app actually uses (removed BloodPressureRecord)
    private val permissions = setOf(
        HealthPermission.getReadPermission(StepsRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
        HealthPermission.getReadPermission(HeartRateRecord::class),
        HealthPermission.getReadPermission(FloorsClimbedRecord::class),
    )

    // Launcher for the matchmaking flow. This will be used to start the matchmaking activity and handle its result.
    private val matchmakingLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val mmStatus = if (result.resultCode == Activity.RESULT_OK) "completed" else "cancelled"
        pendingResult?.success(
            mapOf(
                "status" to "granted",
                "message" to "Matchmaking flow $mmStatus.",
                "grantedPermissions" to lastGrantedPermissions,
                "matchmakingStatus" to mmStatus
            )
        )
        pendingResult = null
    }

    // Request permissions for Health Connect.
    @OptIn(ExperimentalMatchmakingApi::class)
    private val requestPermissionsLauncher = registerForActivityResult(
        PermissionController.createRequestPermissionResultContract()
    ) { grantedPermissions ->
        Log.d("HC", "Permission callback fired: $grantedPermissions")

        val grantedList = grantedPermissions.map { it.toString() }
        lastGrantedPermissions = grantedList

        if (grantedPermissions.containsAll(permissions)) {
            // All required permissions were granted, proceed with matchmaking if available.
            Log.d("HC", "Granted all permissions: $grantedPermissions")

            if (client.features.getFeatureStatus(
                    HealthConnectFeatures.FEATURE_MATCHMAKING
                ) == HealthConnectFeatures.FEATURE_STATUS_AVAILABLE
            ) {
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
                        "status" to "granted",
                        "message" to "Matchmaking is not available on this device",
                        "grantedPermissions" to grantedList,
                        "matchmakingStatus" to "not_available"
                    )
                )
                pendingResult = null
            }
        } else if (grantedPermissions.isNotEmpty()) {
            // Partial permissions granted - non fatal!
            Log.d("HC", "Permissions partially granted: $grantedPermissions")
            pendingResult?.success(
                mapOf(
                    "status" to "partial",
                    "message" to "Health permissions partially granted",
                    "grantedPermissions" to grantedList
                )
            )
            pendingResult = null
        } else {
            // All permissions denied - non fatal!
            Log.d("HC", "Permissions denied")
            pendingResult?.success(
                mapOf(
                    "status" to "denied",
                    "message" to "Health permissions denied",
                    "grantedPermissions" to emptyList<String>()
                )
            )
            pendingResult = null
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

            when (call.method) {
                "showMatchmakingModal" -> {
                    pendingResult = result

                    val status = HealthConnectClient.getSdkStatus(this)
                    Log.d("HC", "SDK Status = $status")

                    if (status != HealthConnectClient.SDK_AVAILABLE) {
                        // Return structured unavailable result instead of throwing PlatformException
                        result.success(
                            mapOf(
                                "status" to "unavailable",
                                "message" to "Health Connect is unavailable on this device",
                                "grantedPermissions" to emptyList<String>()
                            )
                        )
                        pendingResult = null
                        return@setMethodCallHandler
                    }

                    client = HealthConnectClient.getOrCreate(this)

                    lifecycleScope.launch {
                        try {
                            val grantedPermissions = client.permissionController.getGrantedPermissions()
                            lastGrantedPermissions = grantedPermissions.map { it.toString() }

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
                        } catch (e: Exception) {
                            pendingResult?.error(
                                "HEALTH_CONNECT_ERROR", e.message, null
                            )
                            pendingResult = null
                        }
                    }
                }
                "getHealthPermissionStatus" -> {
                    val status = HealthConnectClient.getSdkStatus(this)
                    if (status != HealthConnectClient.SDK_AVAILABLE) {
                        result.success(
                            mapOf(
                                "status" to "unavailable",
                                "message" to "Health Connect is unavailable on this device",
                                "grantedPermissions" to emptyList<String>()
                            )
                        )
                        return@setMethodCallHandler
                    }

                    client = HealthConnectClient.getOrCreate(this)
                    lifecycleScope.launch {
                        try {
                            val granted = client.permissionController.getGrantedPermissions()
                            val grantedList = granted.map { it.toString() }
                            lastGrantedPermissions = grantedList
                            val statusStr = when {
                                granted.containsAll(permissions) -> "granted"
                                granted.isNotEmpty() -> "partial"
                                else -> "denied"
                            }
                            result.success(
                                mapOf(
                                    "status" to statusStr,
                                    "message" to "Current health permission status",
                                    "grantedPermissions" to grantedList
                                )
                            )
                        } catch (e: Exception) {
                            result.error("STATUS_CHECK_ERROR", e.message, null)
                        }
                    }
                }
                "requestHealthPermissions" -> {
                    val status = HealthConnectClient.getSdkStatus(this)
                    if (status != HealthConnectClient.SDK_AVAILABLE) {
                        result.success(
                            mapOf(
                                "status" to "unavailable",
                                "message" to "Health Connect is unavailable",
                                "grantedPermissions" to emptyList<String>()
                            )
                        )
                        return@setMethodCallHandler
                    }

                    client = HealthConnectClient.getOrCreate(this)
                    pendingResult = result
                    requestPermissionsLauncher.launch(permissions)
                }
                "openHealthConnectPlayStore" -> {
                    try {
                        val uri = Uri.parse("market://details?id=com.google.android.apps.healthdata&url=healthconnect%3A%2F%2Fonboarding")
                        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                            setPackage("com.android.vending")
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val webIntent = Intent(
                                Intent.ACTION_VIEW,
                                Uri.parse("https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata")
                            )
                            startActivity(webIntent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("PLAY_STORE_ERROR", e2.message, null)
                        }
                    }
                }
                "openHealthConnectSettings" -> {
                    try {
                        val intent = Intent("androidx.health.ACTION_HEALTH_CONNECT_SETTINGS")
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("SETTINGS_ERROR", e2.message, null)
                        }
                    }
                }
                else -> {
                    result.notImplemented()
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
                    "status" to "granted",
                    "message" to "Matchmaking isn't possible on this device.",
                    "grantedPermissions" to lastGrantedPermissions,
                    "matchmakingStatus" to "not_possible"
                )
            )

            pendingResult = null
        }
    }
}
