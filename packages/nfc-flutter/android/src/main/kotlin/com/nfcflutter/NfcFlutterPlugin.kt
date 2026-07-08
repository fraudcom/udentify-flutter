package com.nfcflutter

import androidx.annotation.NonNull
import android.app.Activity
import android.app.PendingIntent
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
import io.udentify.android.nfc.CardData
import io.udentify.android.nfc.reader.NFCState
import io.udentify.android.nfc.reader.NFCLocation
import io.udentify.android.nfc.reader.NfcLocationListener
import io.udentify.android.nfc.reader.DGResponse
import io.udentify.android.nfc.reader.NFCReader
import io.udentify.android.nfc.reader.NFCReaderObject

/** NfcFlutterPlugin */
class NfcFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  
  // Simple NFC Location variable
  private var nfcLocation: NFCLocation? = null
  
  // Inner class that extends NfcLocationListener as per documentation
  inner class LocationFinder : NfcLocationListener {
    private var result: Result? = null
    private var timeoutHandler: Handler? = null
    
    fun findLocation(activity: Activity, serverURL: String, methodResult: Result) {
      this.result = methodResult
      
      // Check network connectivity
      val connectivityManager = activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
      val network = connectivityManager.activeNetwork
      val networkCapabilities = connectivityManager.getNetworkCapabilities(network)
      val hasInternet = networkCapabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
      
      if (!hasInternet) {
        result?.error("NETWORK_ERROR", "No internet connectivity. NFC location detection requires network access.", null)
        return
      }
      
      // Set up a timeout mechanism (30 seconds)
      timeoutHandler = Handler(Looper.getMainLooper())
      timeoutHandler?.postDelayed({
        if (result != null) {
          result?.error("TIMEOUT_ERROR", "NFC location detection timed out after 30 seconds. This might indicate a network issue or invalid server URL.", null)
          result = null
        }
      }, 30000) // 30 seconds timeout
      
      try {
        val nfcLocation = NFCLocation(this, "$serverURL/nfc/nfcLocation")
        nfcLocation.getNfcLocation()
      } catch (e: Exception) {
        Log.e("NfcFlutterPlugin", "Failed to initialize NFC location finder", e)
        timeoutHandler?.removeCallbacksAndMessages(null)
        result?.error("SDK_ERROR", "Failed to initialize NFC location finder: ${e.message}", null)
        result = null
      }
    }
    
    override fun onSuccess(location: Int) {
      timeoutHandler?.removeCallbacksAndMessages(null) // Cancel timeout
      Handler(Looper.getMainLooper()).post {
        val locationString = when (location) {
          0 -> "unknown"
          4 -> "rearTop"
          5 -> "rearCenter"
          6 -> "rearBottom"
          else -> "unknown"
        }
        result?.success(locationString)
        result = null
      }
    }

    override fun onFailed(errorMessage: String) {
      timeoutHandler?.removeCallbacksAndMessages(null) // Cancel timeout
      Handler(Looper.getMainLooper()).post {
        result?.error("LOCATION_ERROR", errorMessage, null)
        result = null
      }
    }
  }
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var nfcAdapter: NfcAdapter? = null
  private var nfcReaderObject: NFCReaderObject? = null
  private val REQUEST_PHONE_STATE_PERMISSION = 1001
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

      if (!hasPhoneStatePermission) {
        ActivityCompat.requestPermissions(currentActivity, 
            arrayOf(Manifest.permission.READ_PHONE_STATE), REQUEST_PHONE_STATE_PERMISSION)
        result.success("requested")
      } else {
        result.success("granted")
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
      val isActiveAuthEnabled = (arguments?.get("isActiveAuthenticationEnabled") as? Boolean) ?: true
      val isPassiveAuthEnabled = (arguments?.get("isPassiveAuthenticationEnabled") as? Boolean) ?: true

      // Create ApiCredentials using the official Udentify SDK builder pattern (from documentation)
      val apiCredentials = ApiCredentials.Builder()
          .mrzDocNo(documentNumber)
          .mrzBirthDate(dateOfBirth) // Format: "YYMMDD"
          .mrzExpireDate(expiryDate) // Format: "YYMMDD"
          .serverUrl(serverURL) // Url of the Udentify server
          .transactionID(transactionID) // TransactionID: From server to API Key
          .enableAutoTriggering(true)
          .isActiveAuthenticationEnabled(isActiveAuthEnabled)
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
                it.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, stream)
                android.util.Base64.encodeToString(stream.toByteArray(), android.util.Base64.DEFAULT) 
              } ?: ""),
              "passedPA" to when (cardData.passiveAuthInfo) {
                DGResponse.True -> "true"
                DGResponse.False -> "false"
                DGResponse.Disabled -> "disabled"
                DGResponse.NotSupported -> "notSupported"
                else -> "disabled"
              },
              "passedAA" to when (cardData.activeAuthInfo) {
                DGResponse.True -> "true"
                DGResponse.False -> "false"
                DGResponse.Disabled -> "disabled"
                DGResponse.NotSupported -> "notSupported"
                else -> "disabled"
              }
            )
            sendResultSafely(result, success = passportData)
          }
        }

        override fun onFailure(throwable: Throwable) {
          Log.d("NfcFlutterPlugin", "onFailure called: ${throwable.message}")
          Handler(Looper.getMainLooper()).post {
            sendResultSafely(result, errorCode = "NFC_READ_ERROR", errorMessage = throwable.message ?: "Unknown error")
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
      nfcReaderObject = NFCReaderObject(nfcReader)
      nfcReaderObject?.onResume()
      
      // Enable foreground dispatch to capture NFC intents
      if (nfcAdapter != null && currentActivity != null) {
        Log.d("NfcFlutterPlugin", "Enabling foreground NFC dispatch")
        val intent = Intent(currentActivity, currentActivity.javaClass).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val pendingIntent = PendingIntent.getActivity(currentActivity, 0, intent, PendingIntent.FLAG_MUTABLE)
        nfcAdapter?.enableForegroundDispatch(currentActivity, pendingIntent, null, null)
      }
      
      Log.d("NfcFlutterPlugin", "NFC reading setup completed")

    } catch (e: Exception) {
      sendResultSafely(result, errorCode = "NFC_READ_ERROR", errorMessage = "Failed to read passport: ${e.message}")
    }
  }

  private fun cancelReading(result: Result) {
    try {
      // Stop the NFC reading process
      nfcReaderObject?.onPause()
      nfcReaderObject = null
      
      // Reset result tracking
      synchronized(this) {
        if (currentResult != null && !isResultSent) {
          sendResultSafely(currentResult!!, errorCode = "CANCELLED", errorMessage = "Reading was cancelled")
        }
        currentResult = null
        isResultSent = false
      }
      
      // Disable foreground dispatch
      if (nfcAdapter != null && activity != null) {
        Log.d("NfcFlutterPlugin", "Disabling foreground NFC dispatch")
        nfcAdapter?.disableForegroundDispatch(activity)
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
          
          // Return detailed object like React Native (but as JSON string for Flutter)
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
          
          result.success(jsonResult)
        }

        override fun onFailed(error: String?) {
          result.error("NFC_LOCATION_ERROR", error ?: "Failed to detect NFC location", null)
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
    binding.addOnNewIntentListener { intent ->
      handleNfcIntent(intent)
      false
    }
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
    nfcAdapter = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    nfcAdapter = NfcAdapter.getDefaultAdapter(activity)
  }

  override fun onDetachedFromActivity() {
    activity = null
    nfcAdapter = null
  }
}