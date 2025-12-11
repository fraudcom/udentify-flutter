package com.example.ocr_flutter

import androidx.annotation.NonNull
import android.app.Activity
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class OcrFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  companion object {
    private const val TAG = "OcrFlutterPlugin"
    private var storedFrontSideImage: String? = null
    private var storedBackSideImage: String? = null
  }
  
  private lateinit var channel : MethodChannel
  private var activity: Activity? = null
  private lateinit var permissionManager: PermissionManager

  private lateinit var simpleResourceManager: SimpleResourceManager
  private lateinit var uiConfigManager: UIConfigurationManager
  private lateinit var ocrCameraManager: OcrCameraManager
  private lateinit var ocrProcessor: OcrProcessor
  private lateinit var documentLivenessManager: DocumentLivenessManager
  private lateinit var hologramManager: HologramManager
  
  fun storeDocumentScanImages(frontImage: String?, backImage: String?) {
    Log.d(TAG, "OcrFlutterPlugin - Storing document scan images")
    if (frontImage?.isNotEmpty() == true) {
      storedFrontSideImage = frontImage
      Log.d(TAG, "OcrFlutterPlugin - Front image stored: ${frontImage.length} chars")
    }
    if (backImage?.isNotEmpty() == true) {
      storedBackSideImage = backImage
      Log.d(TAG, "OcrFlutterPlugin - Back image stored: ${backImage.length} chars")
    }
  }
  
  fun getStoredFrontImage(): String? = storedFrontSideImage
  fun getStoredBackImage(): String? = storedBackSideImage
  
  fun clearStoredImages() {
    Log.d(TAG, "OcrFlutterPlugin - Clearing stored images")
    storedFrontSideImage = null
    storedBackSideImage = null
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "ocr_flutter")
    channel.setMethodCallHandler(this)
    permissionManager = PermissionManager()
    simpleResourceManager = SimpleResourceManager()
    uiConfigManager = UIConfigurationManager(simpleResourceManager)
    ocrCameraManager = OcrCameraManager(channel, uiConfigManager)
    ocrProcessor = OcrProcessor(ocrCameraManager)
    documentLivenessManager = DocumentLivenessManager(ocrCameraManager)
    hologramManager = HologramManager(channel)
    
    // Wire up plugin instance for image storage
    ocrCameraManager.setPluginInstance(this)
    ocrProcessor.setPluginInstance(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    Log.i(TAG, "🔍 Android: Method call received: ${call.method}")
    when (call.method) {
      "checkPermissions" -> permissionManager.checkPermissions(activity, result)
      "requestPermissions" -> permissionManager.requestPermissions(activity, result)
      "startOCRCamera" -> {
        // Set activity reference before starting OCR camera
        ocrCameraManager.setActivity(activity)
        ocrCameraManager.startOCRCamera(call, result, activity)
      }
      "cancelOCRCamera" -> ocrCameraManager.cancelOCRCamera(result, activity)
      "dismissOCRCamera" -> ocrCameraManager.cancelOCRCamera(result, activity)
      "dismissHologramCamera" -> hologramManager.dismissHologramCamera(result, activity)
      "performOCR" -> ocrProcessor.performOCR(call, result, activity)
      "startHologramCamera" -> hologramManager.startHologramCamera(call, result, activity)
      "uploadHologramVideo" -> hologramManager.uploadHologramVideo(call, result)
      "performDocumentLiveness" -> documentLivenessManager.performDocumentLiveness(call, result, activity)
      "performOCRAndDocumentLiveness" -> documentLivenessManager.performOCRAndDocumentLiveness(call, result, activity)
      "setOCRUIConfig" -> uiConfigManager.setOCRUIConfig(call.arguments as? Map<String, Any>, result)
      "scanCard" -> ocrCameraManager.scanCard(call, result, activity)
      "scanCardFromImages" -> ocrProcessor.scanCardFromImages(call, result, activity)
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}