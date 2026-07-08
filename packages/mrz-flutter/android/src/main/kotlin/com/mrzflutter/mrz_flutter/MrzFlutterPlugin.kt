package com.mrzflutter.mrz_flutter

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
class MrzFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private var currentResult: Result? = null
  private val REQUEST_CAMERA_PERMISSION = 1001
  private val LAUNCH_MRZ_CAMERA_ACTIVITY = 1002

  companion object {
    private const val TAG = "MrzFlutterPlugin"
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
      } else {
        ActivityCompat.requestPermissions(currentActivity,
          arrayOf(Manifest.permission.CAMERA), REQUEST_CAMERA_PERMISSION)
        result.success("requested")
      }
    } else {
      result.error("ACTIVITY_ERROR", "Activity is not available", null)
    }
  }

  private fun startMrzCamera(call: MethodCall, result: Result) {
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
      
      // Launch MRZ camera activity using Intent (same pattern as React Native)
      val intent = Intent(currentActivity, MrzCameraActivity::class.java)
      currentActivity.startActivityForResult(intent, LAUNCH_MRZ_CAMERA_ACTIVITY)
      
    } catch (e: Exception) {
      Log.e(TAG, "Error starting MRZ camera", e)
      result.error("START_MRZ_CAMERA_ERROR", "Failed to start MRZ camera: ${e.message}", null)
    }
  }

  private fun processMrzImage(call: MethodCall, result: Result) {
    // Image processing not implemented yet - will be added in future version
    result.error("NOT_IMPLEMENTED", "Image processing feature is not yet implemented", null)
  }

  private fun cancelMrzScanning(result: Result) {
    try {
      Log.i(TAG, "🛑 User cancelled MRZ scanning")
      
      // Cancel any ongoing result
      currentResult?.error("CANCELLED", "MRZ scanning was cancelled", null)
      currentResult = null
      
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
        Log.i(TAG, "🔍 Received MRZ data from activity: $mrzDataJson")
        
        if (mrzDataJson != null) {
          try {
            // Parse the JSON result and create the response
            val jsonObject = JSONObject(mrzDataJson)
            Log.i(TAG, "📋 Available JSON keys in plugin: ${jsonObject.keys().asSequence().toList()}")
            
            // Helper function to get value with multiple possible keys
            fun getValueFromJson(vararg keys: String): String {
              for (key in keys) {
                if (jsonObject.has(key)) {
                  val value = jsonObject.optString(key, "")
                  if (value.isNotEmpty()) {
                    Log.d(TAG, "✅ Found $key = $value")
                    return value
                  }
                }
              }
              Log.w(TAG, "⚠️ None of these keys found: ${keys.joinToString(", ")}")
              return ""
            }
            
            val mrzData = mutableMapOf<String, Any>().apply {
              put("documentType", getValueFromJson("documentType", "docType", "document_type"))
              put("issuingCountry", getValueFromJson("issuingCountry", "issuing_country", "country"))
              put("documentNumber", getValueFromJson("documentNumber", "docNo", "document_number", "doc_no"))
              put("optionalData1", getValueFromJson("optionalData1", "optional_data_1", "optionalData"))
              put("dateOfBirth", getValueFromJson("dateOfBirth", "birthDate", "date_of_birth", "birth_date"))
              put("gender", getValueFromJson("gender", "sex"))
              put("dateOfExpiration", getValueFromJson("date_of_expire", "dateOfExpiration", "expirationDate", "expireDate", "date_of_expiration", "expiration_date"))
              put("nationality", getValueFromJson("nationality", "nat"))
              put("optionalData2", getValueFromJson("optionalData2", "optional_data_2"))
              put("surname", getValueFromJson("surname", "lastName", "last_name"))
              put("givenNames", getValueFromJson("givenNames", "firstName", "first_name", "given_names"))
            }
            
            val resultMap = mutableMapOf<String, Any>().apply {
              put("success", true)
              put("mrzData", mrzData)
              
              // Add legacy fields for backward compatibility  
              val docNum = getValueFromJson("documentNumber", "docNo", "document_number", "doc_no")
              val birthDate = getValueFromJson("dateOfBirth", "birthDate", "date_of_birth", "birth_date")
              val expDate = getValueFromJson("date_of_expire", "dateOfExpiration", "expirationDate", "expireDate", "date_of_expiration", "expiration_date")
              
              put("documentNumber", docNum)
              put("dateOfBirth", birthDate)
              put("dateOfExpiration", expDate)
              
              Log.i(TAG, "📤 Sending to Flutter - success: true")
              Log.i(TAG, "📤 Legacy fields - docNumber: $docNum, birthDate: $birthDate, expDate: $expDate")
            }
            
            Log.i(TAG, "✅ Resolving result with MRZ result")
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
        // User cancelled or error occurred
        currentResult?.error("USER_CANCELLED", "MRZ scanning was cancelled", null)
        currentResult = null
      }
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}