package com.videocallflutter

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

/** VideoCallFlutterPlugin */
class VideoCallFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private var context: Context? = null
  private var activity: Activity? = null
  
  // Video Call related
  private var videoCallOperator: VideoCallOperatorImpl? = null
  private var currentResult: Result? = null
  
  companion object {
    private const val PERMISSION_REQUEST_CODE = 1001
    private val REQUIRED_PERMISSIONS = arrayOf(
      Manifest.permission.CAMERA,
      Manifest.permission.READ_PHONE_STATE,
      Manifest.permission.INTERNET,
      Manifest.permission.RECORD_AUDIO
    )
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "video_call_flutter")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "checkPermissions" -> checkPermissions(result)
      "requestPermissions" -> requestPermissions(result)
      "startVideoCall" -> startVideoCall(call, result)
      "endVideoCall" -> endVideoCall(result)
      "getVideoCallStatus" -> getVideoCallStatus(result)
      "setVideoCallConfig" -> setVideoCallConfig(call, result)
      "toggleCamera" -> toggleCamera(result)
      "switchCamera" -> switchCamera(result)
      "toggleMicrophone" -> toggleMicrophone(result)
      "dismissVideoCall" -> dismissVideoCall(result)
      else -> result.notImplemented()
    }
  }

  private fun checkPermissions(result: Result) {
    val context = this.context ?: run {
      result.error("NO_CONTEXT", "Context not available", null)
      return
    }

    val hasCameraPermission = ContextCompat.checkSelfPermission(
      context, Manifest.permission.CAMERA
    ) == PackageManager.PERMISSION_GRANTED

    val hasPhoneStatePermission = ContextCompat.checkSelfPermission(
      context, Manifest.permission.READ_PHONE_STATE
    ) == PackageManager.PERMISSION_GRANTED

    val hasInternetPermission = ContextCompat.checkSelfPermission(
      context, Manifest.permission.INTERNET
    ) == PackageManager.PERMISSION_GRANTED

    val hasRecordAudioPermission = ContextCompat.checkSelfPermission(
      context, Manifest.permission.RECORD_AUDIO
    ) == PackageManager.PERMISSION_GRANTED

    val permissions = mapOf(
      "hasCameraPermission" to hasCameraPermission,
      "hasPhoneStatePermission" to hasPhoneStatePermission,
      "hasInternetPermission" to hasInternetPermission,
      "hasRecordAudioPermission" to hasRecordAudioPermission
    )

    result.success(permissions)
  }

  private fun requestPermissions(result: Result) {
    val activity = this.activity ?: run {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    currentResult = result
    ActivityCompat.requestPermissions(activity, REQUIRED_PERMISSIONS, PERMISSION_REQUEST_CODE)
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == PERMISSION_REQUEST_CODE) {
      val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
      currentResult?.success(if (allGranted) "granted" else "denied")
      currentResult = null
      return true
    }
    return false
  }

  private fun startVideoCall(call: MethodCall, result: Result) {
    try {
      val activity = this.activity as? FragmentActivity ?: run {
        result.error("NO_ACTIVITY", "FragmentActivity not available", null)
        return
      }

      val serverURL = call.argument<String>("serverURL") ?: run {
        result.error("MISSING_PARAMETER", "serverURL is required", null)
        return
      }

      val wssURL = call.argument<String>("wssURL") ?: run {
        result.error("MISSING_PARAMETER", "wssURL is required", null)
        return
      }

      val userID = call.argument<String>("userID") ?: run {
        result.error("MISSING_PARAMETER", "userID is required", null)
        return
      }

      val transactionID = call.argument<String>("transactionID") ?: run {
        result.error("MISSING_PARAMETER", "transactionID is required", null)
        return
      }

      val clientName = call.argument<String>("clientName") ?: run {
        result.error("MISSING_PARAMETER", "clientName is required", null)
        return
      }

      val idleTimeout = call.argument<String>("idleTimeout") ?: "30"

      // Create video call operator
      videoCallOperator = VideoCallOperatorImpl(
        serverURL = serverURL,
        wssURL = wssURL,
        userID = userID,
        transactionID = transactionID,
        clientName = clientName,
        idleTimeout = idleTimeout,
        channel = channel
      )
      
      // Log SDK availability
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.vc.fragment.VCFragment")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      android.util.Log.i("VideoCallPlugin", "Udentify SDK available: $isSDKAvailable")

      // Start video call
      val success = videoCallOperator?.startVideoCall(activity) ?: false

      val resultMap = mapOf(
        "success" to success,
        "status" to "connecting",
        "transactionID" to transactionID
      )

      result.success(resultMap)

    } catch (e: Exception) {
      result.error("START_VIDEO_CALL_FAILED", "Failed to start video call: ${e.message}", null)
    }
  }

  private fun endVideoCall(result: Result) {
    try {
      val success = videoCallOperator?.endVideoCall() ?: false
      videoCallOperator = null

      val resultMap = mapOf(
        "success" to success,
        "status" to "disconnected"
      )

      result.success(resultMap)
    } catch (e: Exception) {
      result.error("END_VIDEO_CALL_FAILED", "Failed to end video call: ${e.message}", null)
    }
  }

  private fun getVideoCallStatus(result: Result) {
    val status = videoCallOperator?.getStatus() ?: "idle"
    result.success(status)
  }

  private fun setVideoCallConfig(call: MethodCall, result: Result) {
    try {
      // Extract configuration parameters
      val backgroundColor = call.argument<String>("backgroundColor")
      val textColor = call.argument<String>("textColor")
      val pipViewBorderColor = call.argument<String>("pipViewBorderColor")
      val notificationLabelDefault = call.argument<String>("notificationLabelDefault")
      val notificationLabelCountdown = call.argument<String>("notificationLabelCountdown")
      val notificationLabelTokenFetch = call.argument<String>("notificationLabelTokenFetch")

      videoCallOperator?.setConfig(
        backgroundColor = backgroundColor,
        textColor = textColor,
        pipViewBorderColor = pipViewBorderColor,
        notificationLabelDefault = notificationLabelDefault,
        notificationLabelCountdown = notificationLabelCountdown,
        notificationLabelTokenFetch = notificationLabelTokenFetch
      )

      result.success(null)
    } catch (e: Exception) {
      result.error("SET_CONFIG_FAILED", "Failed to set video call config: ${e.message}", null)
    }
  }

  private fun toggleCamera(result: Result) {
    try {
      val isEnabled = videoCallOperator?.toggleCamera() ?: false
      result.success(isEnabled)
    } catch (e: Exception) {
      result.success(false)
    }
  }

  private fun switchCamera(result: Result) {
    try {
      val success = videoCallOperator?.switchCamera() ?: false
      result.success(success)
    } catch (e: Exception) {
      result.success(false)
    }
  }

  private fun toggleMicrophone(result: Result) {
    try {
      val isEnabled = videoCallOperator?.toggleMicrophone() ?: false
      result.success(isEnabled)
    } catch (e: Exception) {
      result.success(false)
    }
  }

  private fun dismissVideoCall(result: Result) {
    try {
      videoCallOperator?.dismissVideoCall()
      result.success(null)
    } catch (e: Exception) {
      result.error("DISMISS_FAILED", "Failed to dismiss video call: ${e.message}", null)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context = null
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addRequestPermissionsResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
