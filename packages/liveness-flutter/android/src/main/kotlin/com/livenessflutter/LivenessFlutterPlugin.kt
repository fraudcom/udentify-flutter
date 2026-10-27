package com.livenessflutter

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.RequestPermissionsResultListener
import io.udentify.android.face.activities.DemographicsEstimationListener
import io.udentify.android.face.activities.FaceListUserListenerHandler
import io.udentify.android.face.activities.FaceService
import io.udentify.android.face.model.DemographicsResult

/** LivenessFlutterPlugin */
class LivenessFlutterPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, RequestPermissionsResultListener {
  private lateinit var channel: MethodChannel
  private var activity: Activity? = null
  private var faceRecognizerImpl: FaceRecognizerImpl? = null
  private var pendingResult: Result? = null
  private var pendingPermissionType: String? = null

  companion object {
    private const val PERMISSION_REQUEST_CODE = 4601
    // Only what the face SDK needs. RECORD_AUDIO is not among them: neither the SDK's manifest nor
    // this plugin's declares it, so gating on it made every camera flow fail with
    // PERMISSIONS_NOT_GRANTED in an app that had not added it itself.
    private val REQUIRED_PERMISSIONS = arrayOf(
      Manifest.permission.CAMERA,
      Manifest.permission.READ_PHONE_STATE,
      Manifest.permission.INTERNET
    )
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "liveness_flutter")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    // Needs no Activity, so it is handled before the Activity check below. Opts this app into
    // in-call LiveKYC repeats (Android only, off by default); null opts back out.
    if (call.method == "setRepeatConfig") {
      try {
        FaceLiveKycRepeat.setConfig(call.arguments as? Map<*, *>)
        result.success(true)
      } catch (e: IllegalArgumentException) {
        result.error("INVALID_REPEAT_CONFIG", e.message, null)
      } catch (e: Throwable) {
        result.error("REPEAT_CONFIG_FAILED", "Failed to configure face repeat: ${e.message}", null)
      }
      return
    }

    val activity = this.activity
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    when (call.method) {
      "checkPermissions" -> checkPermissions(result)
      "requestPermissions" -> requestPermissions(result)
      "startFaceRecognitionRegistration" -> startFaceRecognition(call, result, FaceRecognitionMethod.REGISTER)
      "startFaceRecognitionAuthentication" -> startFaceRecognition(call, result, FaceRecognitionMethod.AUTHENTICATION)
      "startActiveLiveness" -> startActiveLiveness(call, result)
      "startHybridLiveness" -> startHybridLiveness(call, result)
      "startSelfieCapture" -> startSelfieCapture(call, result)
      "performFaceRecognitionWithSelfie" -> performFaceRecognitionWithSelfie(call, result)
      "registerUserWithPhoto" -> registerUserWithPhoto(call, result)
      "authenticateUserWithPhoto" -> authenticateUserWithPhoto(call, result)
      "cancelFaceRecognition" -> cancelFaceRecognition(result)
      "isFaceRecognitionInProgress" -> isFaceRecognitionInProgress(result)
      "addUserToList" -> addUserToList(call, result)
      "startFaceRecognitionIdentification" -> startFaceRecognitionIdentification(call, result)
      "deleteUserFromList" -> deleteUserFromList(call, result)
      "estimateDemographics" -> estimateDemographics(call, result)
      "configureUISettings" -> configureUISettings(call, result)
      "setLocalization" -> setLocalization(call, result)
      else -> result.notImplemented()
    }
  }

  private fun estimateDemographics(call: MethodCall, result: Result) {
    try {
      val serverURL = call.argument<String>("serverURL")
        ?: throw IllegalArgumentException("serverURL is required")
      val transactionID = call.argument<String>("transactionID")
        ?: throw IllegalArgumentException("transactionID is required")
      val imageBase64 = call.argument<String>("imageBase64")
        ?: throw IllegalArgumentException("imageBase64 is required")
      val currentActivity = activity ?: run {
        result.error("NO_ACTIVITY", "Activity not available", null)
        return
      }

      val faceService = FaceService(currentActivity)
      faceService.estimateDemographics(serverURL, transactionID, imageBase64,
        object : DemographicsEstimationListener {
          override fun onDemographicsResult(demographicsResult: DemographicsResult) {
            Handler(Looper.getMainLooper()).post {
              result.success(mapOf(
                "estimatedAge" to demographicsResult.estimatedAge,
                "estimatedGender" to demographicsResult.estimatedGender
              ))
            }
          }

          override fun onDemographicsError(errorMessage: String) {
            Handler(Looper.getMainLooper()).post {
              result.error("DEMOGRAPHICS_ERROR", errorMessage, null)
            }
          }
        })
    } catch (e: Exception) {
      result.error("DEMOGRAPHICS_ERROR", "Failed to estimate demographics: ${e.message}", null)
    }
  }

  private fun checkPermissions(result: Result) {
    val activity = this.activity ?: run {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    val permissions = hashMapOf<String, Any?>(
      "camera" to getPermissionStatus(activity, Manifest.permission.CAMERA),
      "readPhoneState" to getPermissionStatus(activity, Manifest.permission.READ_PHONE_STATE),
      "internet" to getPermissionStatus(activity, Manifest.permission.INTERNET),
      "recordAudio" to getPermissionStatus(activity, Manifest.permission.RECORD_AUDIO)
    )

    result.success(permissions)
  }

  private fun requestPermissions(result: Result) {
    val activity = this.activity ?: run {
      result.error("NO_ACTIVITY", "Activity not available", null)
      return
    }

    pendingResult = result
    pendingPermissionType = "request"

    ActivityCompat.requestPermissions(
      activity,
      REQUIRED_PERMISSIONS,
      PERMISSION_REQUEST_CODE
    )
  }

  private fun startFaceRecognition(call: MethodCall, result: Result, method: FaceRecognitionMethod) {
    val activity = this.activity
    if (activity !is FragmentActivity) {
      result.error("INVALID_ACTIVITY", "The host activity must extend FlutterFragmentActivity, not FlutterActivity (see the liveness_flutter README)", null)
      return
    }

    if (!hasRequiredPermissions()) {
      result.error("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
      return
    }

    try {
      val arguments = call.arguments as? Map<String, Any>
      if (arguments == null) {
        result.error("INVALID_ARGUMENTS", "Invalid arguments provided for face recognition", null)
        return
      }
      
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      android.util.Log.i("LivenessPlugin", "🎯 Starting face recognition - Method: $method, User: ${credentials.userID}")
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available: $isSDKAvailable")
      
      // Use real SDK
      val success = faceRecognizerImpl?.startFaceRecognitionWithCamera(activity, method) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Face recognition started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "START_FAILED",
              "message" to "Failed to start face recognition"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("START_FAILED", "Failed to start face recognition: ${e.message}", null)
    }
  }

  private fun startActiveLiveness(call: MethodCall, result: Result) {
    val activity = this.activity
    if (activity !is FragmentActivity) {
      result.error("INVALID_ACTIVITY", "The host activity must extend FlutterFragmentActivity, not FlutterActivity (see the liveness_flutter README)", null)
      return
    }

    if (!hasRequiredPermissions()) {
      result.error("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
      return
    }

    try {
      val arguments = call.arguments as Map<String, Any>
      val credentials = parseFaceRecognizerCredentials(arguments)
      val isAuthentication = arguments["isAuthentication"] as? Boolean ?: false
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available: $isSDKAvailable")
      android.util.Log.i("LivenessPlugin", "Active Liveness isAuthentication: $isAuthentication")
      
      // Use real SDK for active liveness
      val success = faceRecognizerImpl?.startActiveLiveness(activity, isAuthentication) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Active liveness started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "START_FAILED",
              "message" to "Failed to start active liveness"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("START_FAILED", "Failed to start active liveness: ${e.message}", null)
    }
  }

  private fun startHybridLiveness(call: MethodCall, result: Result) {
    val activity = this.activity
    if (activity !is FragmentActivity) {
      result.error("INVALID_ACTIVITY", "The host activity must extend FlutterFragmentActivity, not FlutterActivity (see the liveness_flutter README)", null)
      return
    }

    if (!hasRequiredPermissions()) {
      result.error("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
      return
    }

    try {
      val arguments = call.arguments as Map<String, Any>
      val isAuthentication = arguments["isAuthentication"] as? Boolean ?: false
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.ActiveLivenessFragment")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available for Hybrid Liveness: $isSDKAvailable")
      
      // Use real SDK for hybrid liveness
      val success = faceRecognizerImpl?.startHybridLiveness(activity, isAuthentication) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Hybrid liveness started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "START_FAILED",
              "message" to "Failed to start hybrid liveness"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("START_FAILED", "Failed to start hybrid liveness: ${e.message}", null)
    }
  }

  private fun startFaceRecognitionIdentification(call: MethodCall, result: Result) {
    val activity = this.activity
    if (activity !is FragmentActivity) {
      result.error("INVALID_ACTIVITY", "The host activity must extend FlutterFragmentActivity, not FlutterActivity (see the liveness_flutter README)", null)
      return
    }

    if (!hasRequiredPermissions()) {
      result.error("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
      return
    }

    try {
      val arguments = call.arguments as? Map<String, Any>
      if (arguments == null) {
        result.error("INVALID_ARGUMENTS", "Invalid arguments provided for face identification", null)
        return
      }

      val listName = arguments["listName"] as? String
        ?: throw IllegalArgumentException("listName is required")

      // Reuse the same credential parsing as the other camera flows, then attach
      // the listName the SDK needs to know which list to identify the user against.
      val credentials = parseFaceRecognizerCredentials(arguments).copy(listName = listName)

      android.util.Log.i("LivenessPlugin", "🎯 Starting face recognition identification - List: $listName")

      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)

      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceCameraFragment")
        true
      } catch (e: ClassNotFoundException) {
        false
      }

      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }

      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available: $isSDKAvailable")

      // Use real SDK
      val success = faceRecognizerImpl?.startFaceRecognitionWithCamera(activity, FaceRecognitionMethod.IDENTIFICATION) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Face identification started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "START_FAILED",
              "message" to "Failed to start face identification"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("START_FAILED", "Failed to start face identification: ${e.message}", null)
    }
  }

  private fun registerUserWithPhoto(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val base64Image = arguments["base64Image"] as? String ?: throw IllegalArgumentException("base64Image is required")
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available: $isSDKAvailable")
      
      // Use real SDK
      val success = faceRecognizerImpl?.registerUserWithPhoto(activity!!, base64Image) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "User registration started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "REGISTER_FAILED",
              "message" to "Failed to start user registration"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("REGISTER_FAILED", "Failed to register user: ${e.message}", null)
    }
  }

  private fun authenticateUserWithPhoto(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val base64Image = arguments["base64Image"] as? String ?: throw IllegalArgumentException("base64Image is required")
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available: $isSDKAvailable")
      
      // Use real SDK
      val success = faceRecognizerImpl?.authenticateUserWithPhoto(activity!!, base64Image) ?: false
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "User authentication started"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "AUTHENTICATE_FAILED",
              "message" to "Failed to start user authentication"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("AUTHENTICATE_FAILED", "Failed to authenticate user: ${e.message}", null)
    }
  }

  
  private fun startSelfieCapture(call: MethodCall, result: Result) {
    val activity = this.activity
    if (activity !is FragmentActivity) {
      result.error("INVALID_ACTIVITY", "The host activity must extend FlutterFragmentActivity, not FlutterActivity (see the liveness_flutter README)", null)
      return
    }

    if (!hasRequiredPermissions()) {
      result.error("PERMISSIONS_NOT_GRANTED", "Required permissions not granted", null)
      return
    }

    try {
      val arguments = call.arguments as Map<String, Any>
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      android.util.Log.i("LivenessPlugin", "📸 Starting selfie capture - User: ${credentials.userID}")
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available for selfie capture: $isSDKAvailable")
      
      // Start selfie capture using the implementation (this should trigger onSelfieTaken callback)
      val success = faceRecognizerImpl?.startSelfieCapture(activity) ?: false
      
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Selfie capture started successfully"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "SELFIE_CAPTURE_FAILED",
              "message" to "Failed to start selfie capture"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("SELFIE_CAPTURE_FAILED", "Failed to start selfie capture: ${e.message}", null)
    }
  }

  private fun performFaceRecognitionWithSelfie(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val base64Image = arguments["base64Image"] as? String ?: throw IllegalArgumentException("base64Image is required")
      val isAuthentication = arguments["isAuthentication"] as? Boolean ?: false
      val credentials = parseFaceRecognizerCredentials(arguments)
      
      android.util.Log.i("LivenessPlugin", "🔄 Performing face recognition with selfie (isAuth: $isAuthentication)")
      android.util.Log.i("LivenessPlugin", "✅ Processing selfie with Face Recognition API - User: ${credentials.userID}")
      
      faceRecognizerImpl = FaceRecognizerImpl(credentials, channel)
      
      // Check if Udentify SDK is available
      val isSDKAvailable = try {
        Class.forName("io.udentify.android.face.activities.FaceRecognizerObject")
        true
      } catch (e: ClassNotFoundException) {
        false
      }
      
      if (!isSDKAvailable) {
        result.error("SDK_NOT_AVAILABLE", "Udentify Face SDK is not available. Please ensure the SDK dependencies are properly included.", null)
        return
      }
      
      android.util.Log.i("LivenessPlugin", "Udentify Face SDK available for selfie processing: $isSDKAvailable")
      
      // Perform face recognition with captured selfie
      val success = faceRecognizerImpl?.performFaceRecognitionWithSelfie(activity!!, base64Image, isAuthentication) ?: false
      
      result.success(
        if (success) {
          hashMapOf<String, Any?>(
            "status" to "success",
            "faceIDMessage" to hashMapOf<String, Any?>(
              "success" to true,
              "message" to "Face recognition with selfie started successfully"
            )
          )
        } else {
          hashMapOf<String, Any?>(
            "status" to "failure",
            "error" to hashMapOf<String, Any?>(
              "code" to "FACE_RECOGNITION_SELFIE_FAILED",
              "message" to "Failed to perform face recognition with selfie"
            )
          )
        }
      )
    } catch (e: Exception) {
      result.error("FACE_RECOGNITION_SELFIE_FAILED", "Failed to perform face recognition with selfie: ${e.message}", null)
    }
  }

  private fun cancelFaceRecognition(result: Result) {
    try {
      faceRecognizerImpl?.cancelFaceRecognition()
      result.success(null)
    } catch (e: Exception) {
      result.error("CANCEL_FAILED", "Failed to cancel face recognition: ${e.message}", null)
    }
  }

  private fun isFaceRecognitionInProgress(result: Result) {
    val inProgress = faceRecognizerImpl?.isInProgress() ?: false
    result.success(inProgress)
  }

  private fun addUserToList(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val serverURL = arguments["serverURL"] as? String ?: throw IllegalArgumentException("serverURL is required")
      val transactionId = arguments["transactionId"] as? String ?: throw IllegalArgumentException("transactionId is required")
      val status = arguments["status"] as? String ?: throw IllegalArgumentException("status is required")
      val metadata = arguments["metadata"] as? Map<String, Any>

      val currentActivity = activity ?: run {
        result.error("NO_ACTIVITY", "Activity not available", null)
        return
      }

      android.util.Log.i("LivenessPlugin", "Adding user to list via Udentify Face SDK")

      // Use real SDK to add user to list
      addUserToListWithSDK(currentActivity, serverURL, transactionId, status, metadata, result)
    } catch (e: Exception) {
      result.error("ADD_USER_TO_LIST_FAILED", "Failed to add user to list: ${e.message}", null)
    }
  }

  private fun addUserToListWithSDK(
    activity: Activity,
    serverURL: String,
    transactionId: String,
    status: String,
    metadata: Map<String, Any>?,
    result: Result
  ) {
    try {
      val faceService = FaceService(activity)
      val requestMetadata = java.util.HashMap<String, Any>().apply {
        metadata?.let { putAll(it) }
      }

      val listener = FaceListUserListenerHandler()
        .onAddSuccess { listResponseData ->
          Handler(Looper.getMainLooper()).post {
            result.success(
              hashMapOf<String, Any?>(
                "success" to true,
                "data" to hashMapOf<String, Any?>(
                  "id" to listResponseData.id,
                  "userId" to listResponseData.userId,
                  "customerList" to listResponseData.customerList?.let { customerList ->
                    hashMapOf<String, Any?>(
                      "id" to customerList.id,
                      "name" to customerList.name,
                      "listRole" to customerList.listRole,
                      "description" to customerList.description,
                      "creationDate" to customerList.creationDate
                    )
                  }
                )
              )
            )
          }
        }
        .onAddError { faceError ->
          Handler(Looper.getMainLooper()).post {
            result.success(
              hashMapOf<String, Any?>(
                "success" to false,
                "error" to hashMapOf<String, Any?>(
                  "code" to "ERR_ADD_USER_TO_LIST",
                  "message" to (faceError.message ?: "Failed to add user to list")
                )
              )
            )
          }
        }

      faceService.addUserToList(serverURL, transactionId, status, requestMetadata, listener)
    } catch (e: Exception) {
      android.util.Log.w("LivenessPlugin", "addUserToListWithSDK error", e)
      result.error("ADD_USER_TO_LIST_FAILED", "Failed to add user to list with SDK: ${e.message}", null)
    }
  }

  private fun deleteUserFromList(call: MethodCall, result: Result) {
    try {
      val arguments = call.arguments as Map<String, Any>
      val serverURL = arguments["serverURL"] as? String ?: throw IllegalArgumentException("serverURL is required")
      val transactionId = arguments["transactionID"] as? String ?: throw IllegalArgumentException("transactionID is required")
      val listName = arguments["listName"] as? String ?: throw IllegalArgumentException("listName is required")
      val photoBase64 = arguments["photo"] as? String ?: throw IllegalArgumentException("photo is required")

      val currentActivity = activity ?: run {
        result.error("NO_ACTIVITY", "Activity not available", null)
        return
      }

      android.util.Log.i("LivenessPlugin", "Deleting user from list via Udentify Face SDK")

      val faceService = FaceService(currentActivity)

      val listener = FaceListUserListenerHandler()
        .onDeleteSuccess { listUser ->
          Handler(Looper.getMainLooper()).post {
            result.success(
              hashMapOf<String, Any?>(
                "success" to true,
                "message" to "User deleted from list",
                "data" to hashMapOf<String, Any?>(
                  "userID" to listUser.userID,
                  "transactionID" to listUser.transactionID,
                  "listName" to listUser.listName,
                  "matchScore" to listUser.matchScore,
                  "registrationTransactionID" to listUser.registrationTransactionID
                )
              )
            )
          }
        }
        .onDeleteError { faceError ->
          Handler(Looper.getMainLooper()).post {
            result.success(
              hashMapOf<String, Any?>(
                "success" to false,
                "error" to hashMapOf<String, Any?>(
                  "code" to "ERR_DELETE_USER_FROM_LIST",
                  "message" to (faceError.message ?: "Failed to delete user from list")
                )
              )
            )
          }
        }

      faceService.deleteUserFromList(serverURL, transactionId, listName, photoBase64, listener)
    } catch (e: Exception) {
      result.error("DELETE_USER_FROM_LIST_FAILED", "Failed to delete user from list: ${e.message}", null)
    }
  }



  private fun parseFaceRecognizerCredentials(arguments: Map<String, Any>): FaceRecognizerCredentials {
    android.util.Log.d("LivenessPlugin", "📝 Parsing face recognizer credentials from arguments")
    
    val credentials = FaceRecognizerCredentials(
      serverURL = arguments["serverURL"] as? String ?: "",
      transactionID = arguments["transactionID"] as? String ?: "",
      userID = arguments["userID"] as? String ?: "",
      autoTake = arguments["autoTake"] as? Boolean ?: true,
      errorDelay = (arguments["errorDelay"] as? Number)?.toFloat() ?: 0.10f,
      successDelay = (arguments["successDelay"] as? Number)?.toFloat() ?: 0.75f,
      runInBackground = arguments["runInBackground"] as? Boolean ?: false,
      blinkDetectionEnabled = arguments["blinkDetectionEnabled"] as? Boolean ?: false,
      requestTimeout = (arguments["requestTimeout"] as? Number)?.toInt() ?: 10,
      eyesOpenThreshold = (arguments["eyesOpenThreshold"] as? Number)?.toFloat() ?: 0.75f,
      maskConfidence = (arguments["maskConfidence"] as? Number)?.toDouble() ?: 0.95,
      invertedAnimation = arguments["invertedAnimation"] as? Boolean ?: false,
      activeLivenessAutoNextEnabled = arguments["activeLivenessAutoNextEnabled"] as? Boolean ?: true,
      activeLivenessOpacity = (arguments["activeLivenessOpacity"] as? Number)?.toFloat()
    )
    
    android.util.Log.d("LivenessPlugin", "✅ Credentials parsed - ServerURL: ${credentials.serverURL}, UserID: ${credentials.userID}, MaskConfidence: ${credentials.maskConfidence}")
    
    return credentials
  }

  private fun hasRequiredPermissions(): Boolean {
    val activity = this.activity ?: return false
    return REQUIRED_PERMISSIONS.all { permission ->
      ContextCompat.checkSelfPermission(activity, permission) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun getPermissionStatus(activity: Activity, permission: String): String {
    return when (ContextCompat.checkSelfPermission(activity, permission)) {
      PackageManager.PERMISSION_GRANTED -> "granted"
      PackageManager.PERMISSION_DENIED -> {
        if (ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)) {
          "denied"
        } else {
          "permanentlyDenied"
        }
      }
      else -> "unknown"
    }
  }

  override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
  ): Boolean {
    if (requestCode == PERMISSION_REQUEST_CODE && pendingResult != null) {
      val activity = this.activity ?: return false
      
      val permissionResults = hashMapOf<String, Any?>(
        "camera" to getPermissionStatus(activity, Manifest.permission.CAMERA),
        "readPhoneState" to getPermissionStatus(activity, Manifest.permission.READ_PHONE_STATE),
        "internet" to getPermissionStatus(activity, Manifest.permission.INTERNET),
        "recordAudio" to getPermissionStatus(activity, Manifest.permission.RECORD_AUDIO)
      )
      
      pendingResult?.success(permissionResults)
      pendingResult = null
      pendingPermissionType = null
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
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

  // MARK: - UI Configuration (Android Limitations)

  // The Android face SDK is customised through static XML resources only, so there is nothing to
  // apply at runtime. Reported honestly as not applied, with the instructions for doing it.
  private fun configureUISettings(call: MethodCall, result: Result) {
    android.util.Log.w("LivenessFlutterPlugin", "configureUISettings: the Android face SDK only supports static XML resource customization; nothing was applied")
    val arguments = call.arguments as? Map<String, Any>
    result.success(mapOf(
      "success" to false,
      "platform" to "android",
      "message" to "Android UdentifyFACE customization requires static XML resources and an app rebuild; runtime settings were not applied.",
      "xmlInstructions" to generateXMLInstructions(arguments)
    ))
  }

  private fun setLocalization(call: MethodCall, result: Result) {
    android.util.Log.i("LivenessFlutterPlugin", "🔄 Setting localization for Android")
    
    try {
      val arguments = call.arguments as? Map<String, Any>
      val languageCode = arguments?.get("languageCode") as? String
      val customStrings = (arguments?.get("strings") ?: arguments?.get("customStrings")) as? Map<String, String>
      
      android.util.Log.i("LivenessFlutterPlugin", "📍 Language code: $languageCode")
      android.util.Log.i("LivenessFlutterPlugin", "📝 Custom strings count: ${customStrings?.size ?: 0}")
      
      // Android localization is handled via XML string resources
      android.util.Log.w("LivenessFlutterPlugin", "⚠️ Android localization requires XML string resources in res/values-*/strings.xml")
      android.util.Log.w("LivenessFlutterPlugin", "⚠️ Dynamic string changes are not supported on Android platform")
      
      if (customStrings != null && customStrings.isNotEmpty()) {
        android.util.Log.i("LivenessFlutterPlugin", "📋 Received custom strings for Android:")
        customStrings.forEach { (key, value) ->
          android.util.Log.i("LivenessFlutterPlugin", "   <string name=\"$key\">$value</string>")
        }
      }
      
      result.success(mapOf(
        "success" to false,
        "platform" to "android",
        "message" to "Android localization requires static XML string resources. Dynamic string changes are not supported.",
        "recommendation" to "Update res/values-*/strings.xml files and rebuild the app",
        "stringInstructions" to generateStringXMLInstructions(customStrings)
      ))
      
    } catch (e: Exception) {
      android.util.Log.e("LivenessFlutterPlugin", "❌ Failed to set localization: ${e.message}")
      result.error("LOCALIZATION_ERROR", "Failed to set localization: ${e.message}", null)
    }
  }

  // Helper methods for Android XML generation instructions
  private fun generateXMLInstructions(arguments: Map<String, Any>?): String {
    if (arguments == null) return "No configuration provided"
    
    val instructions = StringBuilder()
    instructions.appendLine("To customize UI on Android, update these XML files:")
    instructions.appendLine()
    
    val colors = arguments["colors"] as? Map<String, Any>
    if (colors != null) {
      instructions.appendLine("📁 android/app/src/main/res/values/colors.xml:")
      colors.forEach { (key, value) ->
        when (key) {
          "buttonColor" -> instructions.appendLine("    <color name=\"udentifyface_btn_color\">$value</color>")
          "backgroundColor" -> instructions.appendLine("    <color name=\"udentifyface_bg_color\">$value</color>")
          "buttonTextColor" -> instructions.appendLine("    <color name=\"udentifyface_btn_text_color\">$value</color>")
        }
      }
      instructions.appendLine()
    }
    
    val dimensions = arguments["dimensions"] as? Map<String, Any>
    if (dimensions != null) {
      instructions.appendLine("📁 android/app/src/main/res/values/dimens.xml:")
      dimensions.forEach { (key, value) ->
        when (key) {
          "buttonHeight" -> instructions.appendLine("    <dimen name=\"udentify_selfie_button_height\">${value}dp</dimen>")
          "buttonCornerRadius" -> instructions.appendLine("    <dimen name=\"udentify_face_selfie_button_corner_radius\">${value}dp</dimen>")
        }
      }
      instructions.appendLine()
    }
    
    instructions.appendLine("Then rebuild: flutter run")
    
    return instructions.toString()
  }

  private fun generateStringXMLInstructions(customStrings: Map<String, String>?): String {
    if (customStrings == null || customStrings.isEmpty()) return "No custom strings provided"
    
    val instructions = StringBuilder()
    instructions.appendLine("To add custom strings on Android, update these XML files:")
    instructions.appendLine()
    instructions.appendLine("📁 android/app/src/main/res/values/strings.xml:")
    
    customStrings.forEach { (key, value) ->
      instructions.appendLine("    <string name=\"$key\">$value</string>")
    }
    
    instructions.appendLine()
    instructions.appendLine("For other languages, create:")
    instructions.appendLine("📁 android/app/src/main/res/values-es/strings.xml (Spanish)")
    instructions.appendLine("📁 android/app/src/main/res/values-fr/strings.xml (French)")
    instructions.appendLine("etc.")
    
    return instructions.toString()
  }
}
