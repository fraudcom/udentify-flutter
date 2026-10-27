package com.nfcflutter

import androidx.annotation.NonNull
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// Udentify NFC imports (from the official AAR files)
import io.udentify.android.nfc.reader.NFCReaderActivity
import io.udentify.android.nfc.reader.NFCReaderFragment
import io.udentify.android.nfc.ApiCredentials
import io.udentify.android.nfc.enums.ChipAnticloneMode
import io.udentify.android.nfc.CardData
import io.udentify.android.nfc.reader.NFCState
import io.udentify.android.nfc.reader.NFCLocation
import io.udentify.android.nfc.reader.NfcLocationListener
import io.udentify.android.nfc.reader.DGResponse
import io.udentify.android.nfc.reader.NFCReader
import io.udentify.android.nfc.reader.NFCReaderObject

/**
 * The NFC SDK reports a failure as a string. Some arrive as the SDK's own error name (its `ERR_*`
 * string resources, whose English value is the name itself: `ERR_TAG_LOST`, `ERR_BAC_FAILED`, ...).
 * When one does, that name is the code, so the error reads as the SDK documents it. Anything else
 * keeps the wrapper code it always had.
 */
internal fun sdkErrorCode(message: String?, fallback: String): String {
    if (message == null) return fallback
    if (SDK_ERROR_NAME.matches(message)) return message
    // Two names the SDK builds with the cause appended (`ERR_CARD_READING_FAILED_<text>`,
    // `ERR_READING_DG<n>_FAILED_<text>`): the name is the code, the full text stays the message.
    SDK_ERROR_NAME_WITH_DETAIL.matchEntire(message)?.let { return it.groupValues[1] }
    return fallback
}

private val SDK_ERROR_NAME = Regex("^ERR_[A-Z0-9_]+$")
private val SDK_ERROR_NAME_WITH_DETAIL =
    Regex("^(ERR_CARD_READING_FAILED|ERR_READING_DG[0-9]+_FAILED)_.*$", RegexOption.DOT_MATCHES_ALL)

/** NfcFlutterPlugin */
class NfcFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware,
  io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener {
  
  // Simple NFC Location variable
  private var nfcLocation: NFCLocation? = null
  
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var nfcAdapter: NfcAdapter? = null
  private var nfcReaderObject: NFCReaderObject? = null
  // Distinct from the other plugins' codes, which share one activity's result callback.
  private val REQUEST_PHONE_STATE_PERMISSION = 4301
  private var pendingPermissionResult: Result? = null
  private var currentResult: Result? = null
  private var isResultSent = false

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "nfc_flutter")
    channel.setMethodCallHandler(this)
  }

  private fun sendResultSafely(result: Result, success: Any? = null, errorCode: String? = null, errorMessage: String? = null, errorDetails: Any? = null) {
    synchronized(this) {
      if (!isResultSent && currentResult == result) {
        isResultSent = true
        if (errorCode != null) {
          result.error(errorCode, errorMessage, errorDetails)
        } else {
          result.success(success)
        }
        currentResult = null
      }
    }
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "setRepeatConfig" -> {
        // Opts this app into in-call LiveKYC repeats (Android only, off by default). null opts back out.
        try {
          NfcLiveKycRepeat.setConfig(call.arguments as? Map<*, *>)
          result.success(true)
        } catch (e: IllegalArgumentException) {
          result.error("INVALID_REPEAT_CONFIG", e.message, null)
        } catch (e: Throwable) {
          result.error("REPEAT_CONFIG_FAILED", "Failed to configure NFC repeat: ${e.message}", null)
        }
      }
      "checkPermissions" -> checkPermissions(result)
      "requestPermissions" -> requestPermissions(result)
      "isNfcAvailable" -> isNfcAvailable(result)
      "isNfcEnabled" -> isNfcEnabled(result)
      "readPassport" -> readPassport(call, result)
      "cancelReading" -> cancelReading(result)
      "getNfcLocation" -> getNfcLocation(call, result)
      else -> result.notImplemented()
    }
  }

  private fun checkPermissions(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val hasPhoneStatePermission = ContextCompat.checkSelfPermission(currentActivity, 
          Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
      
      // NFC permission is not a runtime permission, check if NFC hardware is available
      val hasNfcHardware = currentActivity.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC)

      val permissions = mapOf(
        "hasPhoneStatePermission" to hasPhoneStatePermission,
        "hasNfcPermission" to hasNfcHardware
      )
      result.success(permissions)
    } else {
      result.error("NO_ACTIVITY", "Activity not available", null)
    }
  }

  private fun requestPermissions(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val hasPhoneStatePermission = ContextCompat.checkSelfPermission(currentActivity, 
          Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED

      if (hasPhoneStatePermission) {
        result.success("granted")
      } else if (pendingPermissionResult != null) {
        result.error("ALREADY_IN_PROGRESS", "A permission request is already in progress", null)
      } else {
        // Answered when the user does: "granted" or "denied".
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(currentActivity, 
            arrayOf(Manifest.permission.READ_PHONE_STATE), REQUEST_PHONE_STATE_PERMISSION)
      }
    } else {
      result.error("NO_ACTIVITY", "Activity not available", null)
    }
  }

  private fun isNfcAvailable(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val hasNfc = currentActivity.packageManager.hasSystemFeature(PackageManager.FEATURE_NFC)
      result.success(hasNfc)
    } else {
      result.error("NO_ACTIVITY", "Activity not available", null)
    }
  }

  private fun isNfcEnabled(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val nfcAdapter = NfcAdapter.getDefaultAdapter(currentActivity)
      val isEnabled = nfcAdapter?.isEnabled ?: false
      result.success(isEnabled)
    } else {
      result.error("NO_ACTIVITY", "Activity not available", null)
    }
  }

  private fun readPassport(call: MethodCall, result: Result) {
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    // Initialize result tracking for this method call
    synchronized(this) {
      currentResult = result
      isResultSent = false
    }

    try {
      val arguments = call.arguments as? Map<String, Any>
      val documentNumber = arguments?.get("documentNumber") as? String ?: ""
      val dateOfBirth = arguments?.get("dateOfBirth") as? String ?: ""
      val expiryDate = arguments?.get("expiryDate") as? String ?: ""
      val serverURL = arguments?.get("serverURL") as? String ?: ""
      val transactionID = arguments?.get("transactionID") as? String ?: ""
      val isPassiveAuthEnabled = (arguments?.get("isPassiveAuthenticationEnabled") as? Boolean) ?: true
      val chipAnticloneModeStr = arguments?.get("chipAnticloneMode") as? String
      val chipAnticloneMode = ChipAnticloneMode.valueOf(chipAnticloneModeStr ?: "auto")

      // Create ApiCredentials using the official Udentify SDK builder pattern (from documentation)
      val apiCredentials = ApiCredentials.Builder()
          .mrzDocNo(documentNumber)
          .mrzBirthDate(dateOfBirth) // Format: "YYMMDD"
          .mrzExpireDate(expiryDate) // Format: "YYMMDD"
          .serverUrl(serverURL) // Url of the Udentify server
          .transactionID(transactionID) // TransactionID: From server to API Key
          .enableAutoTriggering(true)
          .chipAnticloneMode(chipAnticloneMode)
          .isPassiveAuthenticationEnabled(isPassiveAuthEnabled)
          .build()

      // Create NFCReader implementation
      val nfcReader = object : NFCReader {
        override fun getApiCredentials(): ApiCredentials {
          return apiCredentials
        }

        override fun getCallerActivity(): Activity {
          return currentActivity
        }

        override fun onSuccess(cardData: CardData) {
          Log.d("NfcFlutterPlugin", "onSuccess called with cardData")
          
          // Log PA/AA status for debugging
          Log.d("NfcFlutterPlugin", "=== Android NFC READ SUCCESS ===")
          Log.d("NfcFlutterPlugin", "Raw PA Status: ${cardData.passiveAuthInfo}")
          Log.d("NfcFlutterPlugin", "Raw AA Status: ${cardData.activeAuthInfo}")
          Log.d("NfcFlutterPlugin", "Converted PA: ${when (cardData.passiveAuthInfo) {
            DGResponse.True -> "true"
            DGResponse.False -> "false"
            DGResponse.Disabled -> "disabled"
            DGResponse.NotSupported -> "notSupported"
            else -> "disabled"
          }}")
          Log.d("NfcFlutterPlugin", "Converted AA: ${when (cardData.activeAuthInfo) {
            DGResponse.True -> "true"
            DGResponse.False -> "false"
            DGResponse.Disabled -> "disabled"
            DGResponse.NotSupported -> "notSupported"
            else -> "disabled"
          }}")
          Log.d("NfcFlutterPlugin", "=============================")
          
          Handler(Looper.getMainLooper()).post {
            val passportData = mapOf(
              "firstName" to (cardData.firstName ?: ""),
              "lastName" to (cardData.lastName ?: ""),
              "documentNumber" to (cardData.documentNumber ?: ""),
              "nationality" to (cardData.nationality ?: ""),
              "dateOfBirth" to (cardData.birthDate ?: ""),
              "expiryDate" to (cardData.expireDate ?: ""),
              "gender" to (cardData.gender ?: ""),
              "issuer" to (cardData.documentType ?: ""),
              "personalNumber" to (cardData.identityNo ?: ""),
              "placeOfBirth" to (cardData.birthPlace ?: ""),
              "address" to (cardData.address ?: ""),
              "image" to (cardData.rawPhoto?.let { 
                val stream = java.io.ByteArrayOutputStream()
                // JPEG, base64 without line wraps: the same encoding iOS sends, and Dart's base64
                // decoder rejects the newlines Base64.DEFAULT inserts.
                it.compress(android.graphics.Bitmap.CompressFormat.JPEG, 80, stream)
                android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.NO_WRAP) 
              } ?: ""),
              "passedPA" to dgResponseName(cardData.passiveAuthInfo),
              "passedAA" to dgResponseName(cardData.activeAuthInfo),
              "passedCA" to dgResponseName(cardData.chipAuthInfo),
              "phoneNumber" to (cardData.phoneNumber ?: ""),
              "documentCode" to (cardData.documentCode ?: ""),
              "issuingAuthority" to (cardData.issuingAuthority ?: ""),
              "dateOfIssue" to (cardData.dateOfIssue ?: ""),
              "accessControlProtocol" to (cardData.accessControlProtocol?.name?.lowercase() ?: "")
            )
            sendResultSafely(result, success = passportData)
            releaseReader()
          }
        }

        override fun onFailure(throwable: Throwable) {
          Log.d("NfcFlutterPlugin", "onFailure called: ${throwable.message}")
          Handler(Looper.getMainLooper()).post {
            sendResultSafely(result, errorCode = sdkErrorCode(throwable.message, "NFC_READ_ERROR"), errorMessage = throwable.message ?: "Unknown error")
            releaseReader()
          }
        }

        override fun onState(nfcState: NFCState) {
          Log.d("NfcFlutterPlugin", "onState called: $nfcState")
          // Handle NFC state changes
          when (nfcState) {
            NFCState.ENABLED -> {
              // NFC is enabled
            }
            NFCState.DISABLED -> {
              Handler(Looper.getMainLooper()).post {
                sendResultSafely(result, errorCode = "NFC_DISABLED", errorMessage = "NFC is disabled")
                releaseReader()
              }
            }
            NFCState.ENABLING -> {
              // NFC is enabling
            }
            NFCState.DISABLING -> {
              // NFC is disabling
            }
          }
        }

        override fun onProgress(progress: Int) {
          // Send progress updates to Flutter
          Handler(Looper.getMainLooper()).post {
            Log.d("NfcFlutterPlugin", "Sending progress: $progress")
            channel.invokeMethod("onProgress", progress)
          }
        }
      }

      // Create NFCReaderObject and start NFC reading
      Log.d("NfcFlutterPlugin", "Creating NFCReaderObject and starting NFC reading")
      // A read that is still active (the app did not wait for it) is replaced, not stacked on.
      if (nfcReaderObject != null) releaseReader()
      nfcReaderObject = NFCReaderObject(nfcReader)
      // onResume() registers foreground dispatch for the reader's activity itself, restricted to IsoDep tags, and
      // tags reach the reader through the activity's onNewIntent (handleNfcIntent). The plugin must not register a
      // second time: the NFC service holds a single foreground-dispatch registration (the call carries no per-caller
      // key), so a later call, here one with no tech list, replaces the SDK's.
      nfcReaderObject?.onResume()

      Log.d("NfcFlutterPlugin", "NFC reading setup completed")

    } catch (e: Exception) {
      sendResultSafely(result, errorCode = "NFC_READ_ERROR", errorMessage = "Failed to read passport: ${e.message}")
    }
  }

  /** The wire spelling of a Passive / Active / Chip Authentication verdict. */
  private fun dgResponseName(response: DGResponse?): String = when (response) {
    DGResponse.True -> "true"
    DGResponse.False -> "false"
    DGResponse.Disabled -> "disabled"
    DGResponse.NotSupported -> "notSupported"
    else -> "disabled"
  }

  /**
   * Stops the reader and gives foreground dispatch back. Called whenever a read ends, however it ends: until
   * then the registration the reader made keeps delivering tags to the app and the plugin forwards them to the
   * reader of a read that is already over. The reader's own onPause() disables dispatch too; the call here covers
   * a pause that throws. Must run on the main thread.
   */
  private fun releaseReader() {
    try {
      nfcReaderObject?.onPause()
    } catch (e: Exception) {
      Log.w("NfcFlutterPlugin", "Failed to pause the NFC reader: ${e.message}")
    }
    nfcReaderObject = null

    val currentActivity = activity
    if (nfcAdapter != null && currentActivity != null) {
      Log.d("NfcFlutterPlugin", "Disabling foreground NFC dispatch")
      try {
        nfcAdapter?.disableForegroundDispatch(currentActivity)
      } catch (e: Exception) {
        // IllegalStateException when the activity is not in the foreground; nothing is left to disable then.
        Log.w("NfcFlutterPlugin", "Failed to disable foreground NFC dispatch: ${e.message}")
      }
    }
  }

  private fun cancelReading(result: Result) {
    try {
      // Stop the NFC reading process
      releaseReader()

      // Reset result tracking
      synchronized(this) {
        if (currentResult != null && !isResultSent) {
          sendResultSafely(currentResult!!, errorCode = "CANCELLED", errorMessage = "Reading was cancelled")
        }
        currentResult = null
        isResultSent = false
      }

      result.success("cancelled")
    } catch (e: Exception) {
      result.error("CANCEL_ERROR", "Failed to cancel reading: ${e.message}", null)
    }
  }

  private fun getNfcLocation(call: MethodCall, result: Result) {
    val currentActivity = activity
    if (currentActivity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    try {
      val arguments = call.arguments as? Map<String, Any>
      val serverURL = arguments?.get("serverURL") as? String ?: ""

      // NFC Location detection - implement NfcLocationListener
      val locationListener = object : NfcLocationListener {
        override fun onSuccess(location: Int) {
          val locationString = when (location) {
            0 -> "unknown"
            4 -> "rearTop"
            5 -> "rearCenter"
            6 -> "rearBottom"
            else -> "unknown"
          }
          
          // Return the detailed object (as a JSON string for Flutter)
          val resultMap = mapOf(
            "success" to true,
            "location" to location,
            "locationString" to locationString,
            "message" to "NFC location detected successfully",
            "timestamp" to System.currentTimeMillis().toDouble()
          )
          
          // Convert to JSON string for Flutter
          val jsonResult = resultMap.entries.joinToString(", ", "{", "}") { (key, value) ->
            when (value) {
              is String -> "\"$key\":\"$value\""
              is Boolean -> "\"$key\":$value"
              is Number -> "\"$key\":$value"
              else -> "\"$key\":\"$value\""
            }
          }
          
          // The SDK's network callback may not be on the main thread; Flutter replies must be.
          Handler(Looper.getMainLooper()).post { result.success(jsonResult) }
        }

        override fun onFailed(error: String?) {
          Handler(Looper.getMainLooper()).post {
            result.error(sdkErrorCode(error, "NFC_LOCATION_ERROR"), error ?: "Failed to detect NFC location", null)
          }
        }
      }

      // Create NFCLocation instance with listener and serverURL with correct endpoint
      nfcLocation = NFCLocation(locationListener, "$serverURL/nfc/nfcLocation")

      // Get NFC location
      nfcLocation?.getNfcLocation()

    } catch (e: Exception) {
      result.error("NFC_LOCATION_ERROR", "Error getting NFC location: ${e.message}", null)
    }
  }

  private fun handleNfcIntent(intent: Intent) {
    Log.d("NfcFlutterPlugin", "Received NFC intent: ${intent.action}")
    if (nfcReaderObject != null) {
      Log.d("NfcFlutterPlugin", "Forwarding NFC intent to NFCReaderObject")
      nfcReaderObject?.onNewIntent(intent)
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    registerListeners(binding)
  }

  // Listeners belong to the binding, and Flutter hands over a new one after a configuration change
  // (rotation), so both attach paths register them.
  private fun registerListeners(binding: ActivityPluginBinding) {
    binding.addOnNewIntentListener { intent ->
      handleNfcIntent(intent)
      false
    }
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode != REQUEST_PHONE_STATE_PERMISSION) return false
    val result = pendingPermissionResult ?: return true
    pendingPermissionResult = null
    // An empty result means the request was cancelled, which is a refusal.
    result.success(if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) "granted" else "denied")
    return true
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    nfcAdapter = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
    registerListeners(binding)
  }

  override fun onDetachedFromActivity() {
    // The activity is going away; stop the reader while it can still be paused.
    releaseReader()
    activity = null
    nfcAdapter = null
  }
}