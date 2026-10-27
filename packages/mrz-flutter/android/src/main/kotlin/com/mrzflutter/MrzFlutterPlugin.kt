package com.mrzflutter

import androidx.annotation.NonNull
import android.app.Activity
import android.content.pm.PackageManager
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.util.Log
import android.content.Intent

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

import org.json.JSONObject

/** MrzFlutterPlugin */
class MrzFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener,
  PluginRegistry.RequestPermissionsResultListener {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var currentResult: Result? = null
  // Distinct from the other plugins' codes, which share one activity's result callback.
  private val REQUEST_CAMERA_PERMISSION = 4401
  private var pendingPermissionResult: Result? = null
  private val LAUNCH_MRZ_CAMERA_ACTIVITY = 1002

  companion object {
    private const val TAG = "MrzFlutterPlugin"

    // Static reference so MrzCameraActivity can forward scanning progress back to Dart
    // via channel.invokeMethod("onProgress", ...) while the activity is in the foreground.
    var progressChannel: MethodChannel? = null
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mrz_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "checkPermissions" -> checkPermissions(result)
      "requestPermissions" -> requestPermissions(result)
      "startMrzCamera" -> startMrzCamera(call, result)
      "processMrzImage" -> processMrzImage(call, result)
      "cancelMrzScanning" -> cancelMrzScanning(result)
      else -> result.notImplemented()
    }
  }

  private fun checkPermissions(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val hasCameraPermission = ContextCompat.checkSelfPermission(currentActivity,
        Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
      result.success(hasCameraPermission)
    } else {
      result.error("ACTIVITY_ERROR", "Activity is not available", null)
    }
  }

  private fun requestPermissions(result: Result) {
    val currentActivity = activity
    if (currentActivity != null) {
      val hasCameraPermission = ContextCompat.checkSelfPermission(currentActivity,
        Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
      
      if (hasCameraPermission) {
        result.success("granted")
      } else if (pendingPermissionResult != null) {
        result.error("ALREADY_IN_PROGRESS", "A permission request is already in progress", null)
      } else {
        // Answered when the user does: "granted" or "denied".
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(currentActivity,
          arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
      }
    } else {
      result.error("ACTIVITY_ERROR", "Activity is not available", null)
    }
  }

  private fun startMrzCamera(call: MethodCall, result: Result) {
    // The caller's engine is the one that should hear this scan's progress.
    progressChannel = channel
    try {
      Log.i(TAG, "🚀 MRZ camera scanning requested")
      
      val currentActivity = activity ?: run {
        result.error("ACTIVITY_ERROR", "Activity is not available", null)
        return
      }
      
      // Check camera permission
      val hasCameraPermission = ContextCompat.checkSelfPermission(currentActivity,
        Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
      
      if (!hasCameraPermission) {
        result.error("PERMISSION_DENIED", "Camera permission is required for MRZ scanning", null)
        return
      }
      
      // Store the result for later use in callbacks
      currentResult = result
      
      // A live scan has no image; make sure a photo left by an earlier call cannot turn it into a static read.
      MrzCameraActivity.setPendingImage(null)

      // Launch MRZ camera activity using Intent
      val intent = Intent(currentActivity, MrzCameraActivity::class.java)
      currentActivity.startActivityForResult(intent, LAUNCH_MRZ_CAMERA_ACTIVITY)
      
    } catch (e: Exception) {
      Log.e(TAG, "Error starting MRZ camera", e)
      result.error("START_MRZ_CAMERA_ERROR", "Failed to start MRZ camera: ${e.message}", null)
    }
  }

  private fun processMrzImage(call: MethodCall, result: Result) {
    try {
      Log.i(TAG, "🖼️ MRZ image processing requested")

      val currentActivity = activity ?: run {
        result.error("ACTIVITY_ERROR", "Activity is not available", null)
        return
      }

      val imageBase64 = call.argument<String>("imageBase64")
      if (imageBase64.isNullOrEmpty()) {
        result.error("INVALID_ARGUMENTS", "imageBase64 is required", null)
        return
      }
      val mode = call.argument<String>("mode") ?: "accurate"

      // Store the result for later use in callbacks (same pattern as startMrzCamera)
      currentResult = result

      // Reuse MrzCameraActivity's recognizer (umrz MRZ reader via readMRZ()) in its
      // single-image mode instead of the live camera preview - see MrzCameraActivity's
      // isStaticImageMode/processStaticImage(). The result comes back through
      // onActivityResult() below, exactly like startMrzCamera.
      // The photo travels in-process, not as an Intent extra (see MrzCameraActivity.setPendingImage).
      MrzCameraActivity.setPendingImage(imageBase64)
      val intent = Intent(currentActivity, MrzCameraActivity::class.java).apply {
        putExtra(MrzCameraActivity.EXTRA_MRZ_MODE, mode)
      }
      currentActivity.startActivityForResult(intent, LAUNCH_MRZ_CAMERA_ACTIVITY)

    } catch (e: Exception) {
      Log.e(TAG, "Error processing MRZ image", e)
      MrzCameraActivity.setPendingImage(null)
      result.error("PROCESS_MRZ_IMAGE_ERROR", "Failed to process MRZ image: ${e.message}", null)
    }
  }

  private fun cancelMrzScanning(result: Result) {
    try {
      Log.i(TAG, "🛑 User cancelled MRZ scanning")
      
      // Cancel any ongoing result
      currentResult?.error("CANCELLED", "MRZ scanning was cancelled", null)
      currentResult = null

      // Close the scanning screen too; without this the camera stays up after the call is cancelled.
      MrzCameraActivity.finishCurrent()
      
      // Reply to the cancel request
      result.success(null)
    } catch (e: Exception) {
      Log.e(TAG, "Error cancelling MRZ scanning", e)
      result.error("CANCEL_MRZ_ERROR", "Failed to cancel MRZ scanning: ${e.message}", null)
    }
  }

  // ActivityResultListener implementation
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
    
    if (requestCode == LAUNCH_MRZ_CAMERA_ACTIVITY) {
      if (resultCode == Activity.RESULT_OK && data != null) {
        val mrzDataJson = data.getStringExtra(MrzCameraActivity.RESULT_MRZ_DATA)

        if (mrzDataJson != null) {
          try {
            // The Android MRZ SDK reports three fields (doc_no, date_of_birth, date_of_expire); the rest of
            // MrzData stays empty here and is filled on iOS.
            val jsonObject = JSONObject(mrzDataJson)
            val docNo = jsonObject.optString("doc_no", "")
            val birthDate = jsonObject.optString("date_of_birth", "")
            val expDate = jsonObject.optString("date_of_expire", "")

            val mrzData = mutableMapOf<String, Any>().apply {
              put("documentType", "")
              put("issuingCountry", "")
              put("documentNumber", docNo)
              put("optionalData1", "")
              put("dateOfBirth", birthDate)
              put("gender", "")
              put("dateOfExpiration", expDate)
              put("nationality", "")
              put("optionalData2", "")
              put("surname", "")
              put("givenNames", "")
            }

            val resultMap = mutableMapOf<String, Any>().apply {
              put("success", true)
              put("mrzData", mrzData)

              // Add legacy fields for backward compatibility
              put("documentNumber", docNo)
              put("dateOfBirth", birthDate)
              put("dateOfExpiration", expDate)
            }

            currentResult?.success(resultMap)
            currentResult = null
            
          } catch (e: Exception) {
            Log.e(TAG, "Error parsing MRZ result", e)
            currentResult?.error("PARSE_ERROR", "Failed to parse MRZ result: ${e.message}", null)
            currentResult = null
          }
        } else {
          currentResult?.error("NO_DATA", "No MRZ data received", null)
          currentResult = null
        }
      } else {
        // The SDK could not read a static image (it names the error), or the user cancelled.
        val sdkError = data?.getStringExtra(MrzCameraActivity.RESULT_ERROR)
        if (!sdkError.isNullOrEmpty()) {
          currentResult?.error(sdkError, "The MRZ could not be read: $sdkError", null)
        } else {
          currentResult?.error("USER_CANCELLED", "MRZ scanning was cancelled", null)
        }
        currentResult = null
      }
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    // Only let go of it if it is this engine's: a headless engine going away must not cut off the
    // engine that is running the scan.
    if (progressChannel === channel) progressChannel = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    // The engine with an activity is the interactive one (headless engines never get one), so it is the one
    // whose Dart side should hear the scan's progress. The scan start claims it again for the caller.
    progressChannel = channel
    binding.addActivityResultListener(this)
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
    if (requestCode != REQUEST_CAMERA_PERMISSION) return false
    val result = pendingPermissionResult ?: return true
    pendingPermissionResult = null
    // An empty result means the request was cancelled, which is a refusal.
    result.success(if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) "granted" else "denied")
    return true
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}