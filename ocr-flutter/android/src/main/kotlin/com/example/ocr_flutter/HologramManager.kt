package com.example.ocr_flutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Parcel
import android.util.Log
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.HologramFragment
import io.udentify.android.ocr.activities.HologramStages
import io.udentify.android.ocr.model.HologramResponse

/**
 * Handles hologram operations and implements the HologramStages interface
 */
class HologramManager(
    private val channel: MethodChannel
) : HologramStages {
    
    companion object {
        private const val TAG = "HologramManager"
    }
    
    private var cardRecognizerCredentials: CardRecognizerCredentials? = null
    private var currentResult: Result? = null
    
    // Activity reference for dismissing fragments
    private var currentActivity: Activity? = null
    
    // Store hologram response for upload method
    private var storedHologramResponse: HologramResponse? = null
    private var uploadResult: Result? = null
    
    /**
     * Start hologram camera
     */
    fun startHologramCamera(call: MethodCall, result: Result, activity: Activity?) {
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            
            val currentActivity = activity ?: run {
                result.error("ACTIVITY_ERROR", "Activity is not available", null)
                return
            }
            
            if (currentActivity !is FragmentActivity) {
                result.error("ACTIVITY_ERROR", "Activity must be a FragmentActivity to support hologram camera", null)
                return
            }
            
            // Create credentials for hologram
            cardRecognizerCredentials = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .build()
            
            // Store the result and activity for later use in callbacks
            currentResult = result
            this.currentActivity = currentActivity
            
            // Create and show hologram fragment
            val hologramFragment = HologramFragment.newInstance(false, this) // false = not manual mode, this = HologramStages interface
            
            currentActivity.supportFragmentManager
                .beginTransaction()
                .replace(android.R.id.content, hologramFragment)
                .addToBackStack("hologram_camera")
                .commit()
            
            // Return success immediately - the actual hologram results will come through callbacks
            result.success(true)
            
        } catch (e: Exception) {
            result.error("START_HOLOGRAM_CAMERA_ERROR", "Failed to start hologram camera: ${e.message}", null)
        }
    }
    
    /**
     * Dismiss hologram camera
     */
    fun dismissHologramCamera(result: Result, activity: Activity?) {
        try {
            Utils.dismissCameraFragment(activity as? FragmentActivity)
            currentResult = null // Clear any pending result
            result.success("cancelled")
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", "Failed to dismiss hologram camera: ${e.message}", null)
        }
    }
    
    /**
     * Upload hologram video - returns stored response from hologram processing
     */
    fun uploadHologramVideo(call: MethodCall, result: Result) {
        try {
            Log.i(TAG, "uploadHologramVideo called")
            
            // Store the result for when hologram processing completes
            uploadResult = result
            
            // Check if we already have a stored response
            val response = storedHologramResponse
            if (response != null) {
                Log.i(TAG, "Returning stored hologram response")
                returnHologramResponse(response)
            } else {
                Log.i(TAG, "Waiting for hologram processing to complete...")
                // Result will be returned when hologramResult/hologramFail is called
            }
        } catch (e: Exception) {
            result.error("HOLOGRAM_UPLOAD_ERROR", "Failed to upload hologram video: ${e.message}", null)
        }
    }
    
    // MARK: - HologramStages Interface Implementation
    
    override fun hologramStarted() {
        // Called when hologram recording starts
        Handler(Looper.getMainLooper()).post {
            Log.i(TAG, "Hologram recording started")
            channel.invokeMethod("onHologramStarted", null)
        }
    }

    override fun hologramFinished() {
        // Called when hologram recording finishes
        Handler(Looper.getMainLooper()).post {
            Log.i(TAG, "Hologram recording finished")
            
            // Send video recorded callback with proper format expected by Flutter
            channel.invokeMethod("onHologramVideoRecorded", mapOf(
                "videoUrls" to listOf("hologram_video_url") // Placeholder URL wrapped in expected format
            ))
            
            // Also send the finished event for compatibility
            channel.invokeMethod("onHologramFinished", null)
        }
    }

    override fun hologramResult(hologramResponse: HologramResponse) {
        // Called when hologram processing succeeds
        Handler(Looper.getMainLooper()).post {
            Log.i(TAG, "Hologram processing succeeded")
            
            // Log raw hologram response data for debugging
            try {
                Log.d(TAG, "🎬 RAW HOLOGRAM SUCCESS RESPONSE:")
                Log.d(TAG, "  Message: ${hologramResponse.getMessage()}")
                Log.d(TAG, "  HologramDocumentId: ${hologramResponse.getHologramDocumentId()}")
                Log.d(TAG, "  OcrHologramCheck: ${hologramResponse.getOcrHologramCheck()}")
                Log.d(TAG, "  OcrHoloIdMatch: ${hologramResponse.getOcrHoloIdMatch()}")
                Log.d(TAG, "  OcrHoloFaceMatch: ${hologramResponse.getOcrHoloFaceMatch()}")
                Log.d(TAG, "  HologramResponse toString: ${hologramResponse.toString()}")
                
                // Try to get any additional data through reflection if available
                try {
                    val responseClass = hologramResponse::class.java
                    val methods = responseClass.methods.filter { it.name.startsWith("get") }
                    Log.d(TAG, "  Available getter methods: ${methods.map { it.name }}")
                } catch (e: Exception) {
                    Log.d(TAG, "  Could not inspect response methods: ${e.message}")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error logging raw hologram success response: ${e.message}")
            }
            
            // Store the response for upload method
            storedHologramResponse = hologramResponse
            
            // Dismiss the camera fragment
            Utils.dismissCameraFragment(currentActivity as? FragmentActivity)
            
            // If uploadHologramVideo is waiting for response, return it now
            if (uploadResult != null) {
                Log.i(TAG, "Returning hologram response to waiting upload method")
                returnHologramResponse(hologramResponse)
            }
            
            currentResult = null
        }
    }

    override fun hologramFail(hologramResponse: HologramResponse) {
        // Called when hologram processing fails
        Handler(Looper.getMainLooper()).post {
            Log.e(TAG, "Hologram processing failed: ${hologramResponse.getMessage()}")
            
            // Log raw hologram failure response data for debugging
            try {
                Log.d(TAG, "💥 RAW HOLOGRAM FAILURE RESPONSE:")
                Log.d(TAG, "  Message: ${hologramResponse.getMessage()}")
                Log.d(TAG, "  HologramDocumentId: ${hologramResponse.getHologramDocumentId()}")
                Log.d(TAG, "  OcrHologramCheck: ${hologramResponse.getOcrHologramCheck()}")
                Log.d(TAG, "  OcrHoloIdMatch: ${hologramResponse.getOcrHoloIdMatch()}")
                Log.d(TAG, "  OcrHoloFaceMatch: ${hologramResponse.getOcrHoloFaceMatch()}")
                Log.d(TAG, "  HologramResponse toString: ${hologramResponse.toString()}")
                
                // Try to get any additional data through reflection if available
                try {
                    val responseClass = hologramResponse::class.java
                    val methods = responseClass.methods.filter { it.name.startsWith("get") }
                    Log.d(TAG, "  Available getter methods: ${methods.map { it.name }}")
                    
                    // Try to get raw server response if available
                    val rawResponseMethods = methods.filter { 
                        it.name.contains("Raw", true) || 
                        it.name.contains("Response", true) ||
                        it.name.contains("Json", true) ||
                        it.name.contains("Data", true)
                    }
                    Log.d(TAG, "  Potential raw response methods: ${rawResponseMethods.map { it.name }}")
                    
                    // Try to invoke some common raw response methods
                    for (method in rawResponseMethods) {
                        try {
                            if (method.parameterCount == 0) {
                                val value = method.invoke(hologramResponse)
                                Log.d(TAG, "  ${method.name}: $value")
                            }
                        } catch (e: Exception) {
                            Log.d(TAG, "  Could not invoke ${method.name}: ${e.message}")
                        }
                    }
                } catch (e: Exception) {
                    Log.d(TAG, "  Could not inspect response methods: ${e.message}")
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "Error logging raw hologram failure response: ${e.message}")
            }
            
            val errorMessage = hologramResponse.getMessage() ?: "Unknown hologram error"
            
            // Dismiss the camera fragment
            Utils.dismissCameraFragment(currentActivity as? FragmentActivity)
            
            // Send failure via method channel
            channel.invokeMethod("onHologramFailure", mapOf("error" to errorMessage))
            
            // If uploadHologramVideo is waiting for response, return error
            if (uploadResult != null) {
                Log.i(TAG, "Returning hologram error to waiting upload method")
                uploadResult!!.error("HOLOGRAM_PROCESSING_FAILED", errorMessage, null)
                uploadResult = null
            }
            
            currentResult = null
        }
    }
    
    // MARK: - Helper Methods
    
    private fun returnHologramResponse(hologramResponse: HologramResponse) {
        try {
            // Map Android response fields to Flutter HologramResponse model
            val responseMap = mapOf(
                "transactionID" to hologramResponse.getHologramDocumentId(), // Map document ID to transaction ID
                "idNumber" to hologramResponse.getHologramDocumentId(), // Use document ID as ID number
                "hologramExists" to (hologramResponse.getOcrHologramCheck()?.toString() == "true"),
                "ocrIdAndHologramIdMatch" to (hologramResponse.getOcrHoloIdMatch()?.toString() == "true"),
                "ocrFaceAndHologramFaceMatch" to (hologramResponse.getOcrHoloFaceMatch()?.toString() == "true"),
                "error" to null // No error for success case
                // Note: hologramFaceImage would need Bitmap to Base64 conversion if needed
            )
            
            Log.d(TAG, "Returning hologram response: $responseMap")
            uploadResult?.success(responseMap)
            uploadResult = null
            
        } catch (e: Exception) {
            Log.e(TAG, "Error returning hologram response: ${e.message}")
            uploadResult?.error("RESPONSE_MAPPING_ERROR", "Failed to map hologram response: ${e.message}", null)
            uploadResult = null
        }
    }
    
    // MARK: - HologramStages Interface Implementation (continued)
    
    override fun getCredentials(): CardRecognizerCredentials {
        return cardRecognizerCredentials ?: throw IllegalStateException("Credentials not initialized")
    }
    
    // MARK: - Parcelable Implementation (required by HologramStages interface)
    
    override fun writeToParcel(dest: Parcel, flags: Int) {
        // Implementation for Parcelable
    }

    override fun describeContents(): Int {
        return 0
    }
}
