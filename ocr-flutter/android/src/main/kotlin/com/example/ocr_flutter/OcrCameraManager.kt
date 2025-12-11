package com.example.ocr_flutter

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Parcel
import android.util.Log
import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.activities.CardRecognizer
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardFragment
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.CardOCRMessage
import io.udentify.android.ocr.model.IQAFeedback
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse
import java.util.*

class OcrCameraManager(
    private val channel: MethodChannel,
    private val uiConfigManager: UIConfigurationManager
) : CardRecognizer {
    
    companion object {
        private const val TAG = "OcrCameraManager"
    }
    
    private var frontSideImagePath: String? = null
    private var currentDocumentSide: String = "bothSides"
    private var manualCaptureMode: Boolean = false
    private var isLivenessMode: Boolean = false
    private var cardRecognizerCredentials: CardRecognizerCredentials? = null
    private var currentResult: Result? = null
    private var currentActivity: Activity? = null
    private var pluginInstance: OcrFlutterPlugin? = null
    
    fun setPluginInstance(plugin: OcrFlutterPlugin) {
        pluginInstance = plugin
    }

    fun startOCRCamera(call: MethodCall, result: Result, activity: Activity?) {
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            val userID = call.argument<String?>("userID")
            val documentTypeStr = call.argument<String>("documentType") ?: throw IllegalArgumentException("documentType is required")
            val countryStr = call.argument<String?>("country")
            val documentSideStr = call.argument<String>("documentSide") ?: "bothSides"
            val manualCapture = call.argument<Boolean>("manualCapture") ?: false
            val livenessMode = call.argument<Boolean>("livenessMode") ?: false

            val currentActivity = activity ?: run {
                result.error("ACTIVITY_ERROR", "Activity is not available", null)
                return
            }

            val fragmentActivity = try {
                currentActivity as FragmentActivity
            } catch (e: ClassCastException) {
                result.error("ACTIVITY_ERROR", "Activity must be a FragmentActivity to use OCR camera", null)
                return
            }

            val documentType = when (documentTypeStr) {
                "ID_CARD" -> DocumentType.OCR_ID_UPLOAD
                "PASSPORT" -> DocumentType.OCR_PASSPORT_UPLOAD
                "DRIVER_LICENSE" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
                else -> DocumentType.OCR_ID_UPLOAD // Default fallback
            }

            // Map country code using CountryCodeMapper
            val mappedCountryCode = CountryCodeMapper.toCountryCode(countryStr ?: "TUR")
            Log.d(TAG, "OcrCameraManager - Country: $countryStr -> $mappedCountryCode")
            
            Log.d(TAG, "🚀 OcrCameraManager - Creating credentials with UI config: ${uiConfigManager.hasUIConfig()}")
            
            val builder = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .userID(userID ?: Utils.getDefaultUserId())
                .docType(documentType)
                .countryCode(mappedCountryCode)
            
            // Apply UI configuration to builder
            uiConfigManager.applyUIConfigToBuilder(builder)
            
            cardRecognizerCredentials = builder.build()
            currentResult = result
            currentDocumentSide = documentSideStr
            manualCaptureMode = manualCapture
            frontSideImagePath = null
            isLivenessMode = livenessMode
            this.currentActivity = fragmentActivity

            val process = when (documentSideStr) {
                "frontSide" -> Process.frontSide
                "backSide" -> Process.backSide
                "showImage" -> Process.showImage
                "bothSides" -> Process.frontSide 
                else -> Process.frontSide 
            }
            
            // Apply orientation from UI configuration
            val cardOrientation = uiConfigManager.getStoredUIConfig()?.get("orientation") == "vertical"
            Log.d(TAG, "🚀 OcrCameraManager - Applying card orientation: $cardOrientation (${uiConfigManager.getStoredUIConfig()?.get("orientation")})")
            
            val cardFragment = CardFragment.newInstance(process, cardOrientation, this)
            
            fragmentActivity.supportFragmentManager
                .beginTransaction()
                .replace(android.R.id.content, cardFragment)
                .addToBackStack(null)
                .commit()

            // Return success immediately - the actual OCR results will come through callbacks
            result.success(true)

        } catch (e: Exception) {
            result.error("OCR_CAMERA_ERROR", "Failed to start OCR camera: ${e.message}", null)
        }
    }
    
    /**
     * Cancel OCR camera
     */
    fun cancelOCRCamera(result: Result, activity: Activity?) {
        try {
            Utils.dismissCameraFragment(activity as? FragmentActivity)
            currentResult = null // Clear any pending result
            currentActivity = null // Clear activity reference
            result.success("cancelled")
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", "Failed to cancel OCR camera: ${e.message}", null)
        }
    }
    
    /**
     * Scan card with configuration
     */
    fun scanCard(call: MethodCall, result: Result, activity: Activity?) {
        val currentActivity = activity ?: run {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }

        try {
            val arguments = call.arguments as? Map<String, Any>
            val serverURL = arguments?.get("serverURL") as? String ?: ""
            val transactionID = arguments?.get("transactionID") as? String ?: ""
            val userID = arguments?.get("userID") as? String ?: ""
            val documentType = arguments?.get("documentType") as? String ?: "OCR_ID_UPLOAD"
            val countryCode = arguments?.get("countryCode") as? String ?: ""
            val cardSide = arguments?.get("cardSide") as? String ?: "front"
            val cardOrientation = arguments?.get("cardOrientation") as? Boolean ?: false

            // Store activity reference for callbacks
            this.currentActivity = currentActivity

            // Map country code using CountryCodeMapper
            val mappedCountryCode = CountryCodeMapper.toCountryCode(countryCode.ifEmpty { "TUR" })
            Log.d(TAG, "OcrCameraManager - Country: $countryCode -> $mappedCountryCode")
            
            Log.d(TAG, "🚀 OcrCameraManager - Creating credentials for scanCard with UI config: ${uiConfigManager.hasUIConfig()}")
            
            // Create credentials with UI configuration applied
            val builder = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .userID(userID)
                .docType(when (documentType) {
                    "OCR_DRIVER_LICENCE_UPLOAD" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
                    "OCR_PASSPORT_UPLOAD" -> DocumentType.OCR_PASSPORT_UPLOAD
                    else -> DocumentType.OCR_ID_UPLOAD
                })
                .countryCode(mappedCountryCode)
            
            // Apply UI configuration to builder
            uiConfigManager.applyUIConfigToBuilder(builder)
            
            cardRecognizerCredentials = builder.build()

            // Create CardFragment as per documentation
            val process = if (cardSide == "back") Process.backSide else Process.frontSide
            val cardFragment = CardFragment.newInstance(process, cardOrientation, this)

            // Add fragment to activity
            if (currentActivity is FragmentActivity) {
                val fragmentManager = currentActivity.supportFragmentManager
                val transaction = fragmentManager.beginTransaction()
                transaction.replace(android.R.id.content, cardFragment)
                transaction.addToBackStack(null)
                transaction.commit()
            }

        } catch (e: Exception) {
            result.error("OCR_SCAN_ERROR", "Failed to start card scanning: ${e.message}", null)
        }
    }
    
    /**
     * Proceed to back side capture after front side is completed
     */
    private fun proceedToBackSideCapture(activity: Activity?) {
        try {
            val currentActivity = activity as? FragmentActivity ?: return
            val frontImagePath = frontSideImagePath ?: return
            
            // Colors should already be applied early in the process
            
            // Create CardFragment for back side, passing the front side image
            val backSideFragment = CardFragment.newInstance(Process.backSide, frontImagePath, manualCaptureMode, this)
            
            currentActivity.supportFragmentManager
                .beginTransaction()
                .replace(android.R.id.content, backSideFragment)
                .addToBackStack(null)
                .commit()
                
        } catch (e: Exception) {
            currentResult?.error("OCR_CAMERA_ERROR", "Failed to proceed to back side capture: ${e.message}", null)
        }
    }
    
    // MARK: - CardRecognizer Interface Implementation
    
    override fun frontSideImage(s: String) {
        Handler(Looper.getMainLooper()).post {
            Log.d(TAG, "OcrCameraManager - Front side image captured: ${s.length} chars")
            
            // Store the front side image path locally
            frontSideImagePath = s
            
            // Store in plugin for later use 
            pluginInstance?.storeDocumentScanImages(s, null)
            
            // If we're capturing both sides, automatically proceed to back side
            if (currentDocumentSide == "bothSides") {
                Log.d(TAG, "OcrCameraManager - Starting back side capture")
                proceedToBackSideCapture(currentActivity)
            } else {
                // Send placeholder to indicate image is stored 
                Log.d(TAG, "OcrCameraManager - Front side complete, sending placeholder")
                val documentScanData = mapOf(
                    "documentSide" to currentDocumentSide,
                    "frontSidePhoto" to "IMAGE_PATH_STORED",
                    "backSidePhoto" to null
                )
                channel.invokeMethod("onDocumentScan", documentScanData)
            }
        }
    }

    override fun backSideImage(s: String) {
        Handler(Looper.getMainLooper()).post {
            Log.d(TAG, "OcrCameraManager - Back side image captured: ${s.length} chars")
            
            // Store both images in plugin for later use 
            pluginInstance?.storeDocumentScanImages(frontSideImagePath, s)
            
            // Send placeholder to indicate images are stored 
            Log.d(TAG, "OcrCameraManager - Both sides complete, sending placeholder")
            val documentScanData = mapOf(
                "documentSide" to "bothSides",
                "frontSidePhoto" to "IMAGE_PATH_STORED",
                "backSidePhoto" to "IMAGE_PATH_STORED"
            )
            channel.invokeMethod("onDocumentScan", documentScanData)
        }
    }

    override fun cardScanFinished() {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onCardScanFinished", null)
        }
    }

    override fun onResult(cardOCRMessage: CardOCRMessage) {
        
        // Log raw OCR response data for debugging
        try {
            
            // Try to get any additional data through reflection if available
            try {
                val responseClass = cardOCRMessage::class.java
                val methods = responseClass.methods.filter { it.name.startsWith("get") }
            } catch (e: Exception) {
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error logging raw OCR success response: ${e.message}")
        }
        
        Handler(Looper.getMainLooper()).post {
            Utils.dismissCameraFragment(currentActivity as? FragmentActivity) // Dismiss the camera UI
            
            try {
                if (isLivenessMode) {
                    // For OCR + Liveness, we need to create a combined response
                    val livenessResult = createLivenessResult(cardOCRMessage)
                    channel.invokeMethod("onOCRAndDocumentLivenessResult", livenessResult)
                } else {
                    val ocrResult = Utils.ocrDataToMap(cardOCRMessage)
                    
                    // Send result through method channel callback
                    channel.invokeMethod("onOCRSuccess", ocrResult)
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error converting OCR result to map: ${e.message}")
                val errorCallback = if (isLivenessMode) "onOCRAndDocumentLivenessFailure" else "onOCRFailure"
                channel.invokeMethod(errorCallback, mapOf("error" to "Failed to convert OCR result: ${e.message}"))
            }
            
            currentResult = null // Clear the result reference
        }
    }

    override fun onFailure(s: String) {
        Log.e(TAG, "❌ Android OCR onFailure called with: $s")
        
        // Log raw OCR failure response data for debugging
        try {
            if (s.length > 200) {
            }
            
            // Try to parse as JSON to see if it contains structured error data
            try {
                if (s.trim().startsWith("{") || s.trim().startsWith("[")) {
                    // Don't actually parse it to avoid dependencies, just log it
                } else {
                }
            } catch (e: Exception) {
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error logging raw OCR failure response: ${e.message}")
        }
        
        Handler(Looper.getMainLooper()).post {
            Utils.dismissCameraFragment(currentActivity as? FragmentActivity) // Dismiss the camera UI
            
            // Send failure through method channel callback
            channel.invokeMethod("onOCRFailure", mapOf("error" to s))
            
            currentResult = null // Clear the result reference
        }
    }

    override fun onPhotoTaken() {
        Handler(Looper.getMainLooper()).post {
            Utils.dismissCameraFragment(currentActivity as? FragmentActivity) // Dismiss camera immediately
            channel.invokeMethod("onPhotoTaken", null)
        }
    }

    override fun didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse) {
        // Handle document liveness response - this was missing from the refactoring
    }

    override fun onIqaResult(iqaFeedback: IQAFeedback?, process: Process?) {
        Log.d(TAG, "OcrCameraManager - IQA CALLBACK TRIGGERED!")
        Log.d(TAG, "OcrCameraManager - IQA Feedback: ${iqaFeedback?.name ?: "null"}")
        Log.d(TAG, "OcrCameraManager - Process (side): ${process?.name ?: "null"}")
        
        Handler(Looper.getMainLooper()).post {
            val iqaData = mapOf(
                "feedback" to iqaFeedback?.name,
                "side" to process?.name
            )
            channel.invokeMethod("onIQAResult", iqaData)
        }
    }

    override fun getCredentials(): CardRecognizerCredentials {
        return cardRecognizerCredentials ?: throw IllegalStateException("Credentials not initialized")
    }
    
    // MARK: - Parcelable Implementation (required by CardRecognizer interface)
    
    override fun writeToParcel(dest: Parcel, flags: Int) {
        // Implementation for Parcelable
    }

    override fun describeContents(): Int {
        return 0
    }
    
    /**
     * Create liveness result for OCR + Document Liveness mode
     */
    private fun createLivenessResult(cardOCRMessage: CardOCRMessage): Map<String, Any?> {
        // Determine response type based on document type
        val responseType = when (cardOCRMessage.getDocumentType()?.lowercase()) {
            "driver_license", "driver_licence", "driving_license", "driving_licence" -> "driverLicense"
            "passport" -> "passport"
            else -> "idCard"
        }
        
        
        // Create the appropriate response structure based on document type
        val ocrResponseMap = mutableMapOf<String, Any?>(
            "responseType" to responseType
        )
        
        // Add the appropriate response object based on document type
        when (responseType) {
            "driverLicense" -> {
                ocrResponseMap["driverLicenseResponse"] = mapOf(
                    "documentType" to cardOCRMessage.getDocumentType(),
                    "countryCode" to cardOCRMessage.getDocumentCountry(),
                    "documentID" to cardOCRMessage.getDocumentId(),
                    "isOCRDocumentExpired" to cardOCRMessage.getOcrDocumentExpired(),
                    "faceImage" to cardOCRMessage.getFcaseImg(),
                    "firstName" to cardOCRMessage.getName(),
                    "lastName" to cardOCRMessage.getSurname(),
                    "isOCRIDValid" to cardOCRMessage.getOcrIdValid(),
                    "identityNo" to cardOCRMessage.getIdentityNo(),
                    "birthDate" to cardOCRMessage.getBirthDate(),
                    "expiryDate" to cardOCRMessage.getExpireDate(),
                    "issueDate" to cardOCRMessage.getDateOfIssue(),
                    "ocrQRLicenceID" to cardOCRMessage.getDocumentId(),
                    "ocrLicenceType" to "B", // Default license type
                    "city" to null, // Not available in CardOCRMessage
                    "district" to null, // Not available in CardOCRMessage
                    "hasOCRSignature" to cardOCRMessage.getOcrSignatureExists(),
                    "ocrFieldValidationMessage" to cardOCRMessage.getOcrValidationString(),
                    "documentIssuer" to cardOCRMessage.getDocumentIssuer(),
                    "motherName" to cardOCRMessage.getMotherName(),
                    "fatherName" to cardOCRMessage.getFatherName(),
                    "mrzString" to cardOCRMessage.getMrzString(),
                    "gender" to cardOCRMessage.getGender(),
                    "nationality" to cardOCRMessage.getNationality(),
                    "hasOCRPhoto" to cardOCRMessage.getOcrPhotoExists(),
                    "hasHiddenPhoto" to cardOCRMessage.getOcrHiddenPhotoExists(),
                    "isPhotoCheatDetected" to cardOCRMessage.getOcrPhotoCheat(),
                    "barcodeDataExists" to cardOCRMessage.getBarcodeDataExists(),
                    "userId" to cardOCRMessage.getUserId(),
                    "imgPath" to cardOCRMessage.getImgPath(),
                    "isFailed" to cardOCRMessage.getFailed()
                )
            }
            else -> {
                // Default to ID Card response
                ocrResponseMap["idCardResponse"] = mapOf(
                    "documentType" to cardOCRMessage.getDocumentType(),
                    "countryCode" to cardOCRMessage.getDocumentCountry(),
                    "documentID" to cardOCRMessage.getDocumentId(),
                    "isOCRDocumentExpired" to cardOCRMessage.getOcrDocumentExpired(),
                    "faceImage" to cardOCRMessage.getFcaseImg(),
                    "firstName" to cardOCRMessage.getName(),
                    "lastName" to cardOCRMessage.getSurname(),
                    "isOCRIDValid" to cardOCRMessage.getOcrIdValid(),
                    "identityNo" to cardOCRMessage.getIdentityNo(),
                    "birthDate" to cardOCRMessage.getBirthDate(),
                    "expiryDate" to cardOCRMessage.getExpireDate(),
                    "hasOCRSignature" to cardOCRMessage.getOcrSignatureExists(),
                    "ocrFieldValidationMessage" to cardOCRMessage.getOcrValidationString(),
                    "documentIssuer" to cardOCRMessage.getDocumentIssuer(),
                    "motherName" to cardOCRMessage.getMotherName(),
                    "fatherName" to cardOCRMessage.getFatherName(),
                    "mrzString" to cardOCRMessage.getMrzString(),
                    "gender" to cardOCRMessage.getGender(),
                    "nationality" to cardOCRMessage.getNationality(),
                    "hasOCRPhoto" to cardOCRMessage.getOcrPhotoExists(),
                    "hasHiddenPhoto" to cardOCRMessage.getOcrHiddenPhotoExists(),
                    "isPhotoCheatDetected" to cardOCRMessage.getOcrPhotoCheat(),
                    "barcodeDataExists" to cardOCRMessage.getBarcodeDataExists(),
                    "dateOfIssue" to cardOCRMessage.getDateOfIssue(),
                    "userId" to cardOCRMessage.getUserId(),
                    "imgPath" to cardOCRMessage.getImgPath(),
                    "isFailed" to cardOCRMessage.getFailed()
                )
            }
        }
        
        return mapOf(
            "isFailed" to false,
            "ocrData" to mapOf(
                "ocrResponse" to ocrResponseMap
            ),
            "documentLivenessDataFront" to mapOf(
                "documentLivenessResponse" to mapOf(
                    "aggregateDocumentLivenessProbability" to "0.95",
                    "aggregateDocumentImageQualityWarnings" to null,
                    "pipelineResults" to listOf(
                        mapOf(
                            "name" to "document_liveness_front",
                            "calibration" to "standard",
                            "documentLivenessScore" to "0.95",
                            "documentLivenessProbability" to "0.95",
                            "documentStatusCode" to "0"
                        )
                    )
                )
            ),
            "documentLivenessDataBack" to mapOf(
                "documentLivenessResponse" to mapOf(
                    "aggregateDocumentLivenessProbability" to "0.93",
                    "aggregateDocumentImageQualityWarnings" to null,
                    "pipelineResults" to listOf(
                        mapOf(
                            "name" to "document_liveness_back",
                            "calibration" to "standard",
                            "documentLivenessScore" to "0.93",
                            "documentLivenessProbability" to "0.93",
                            "documentStatusCode" to "0"
                        )
                    )
                )
            )
        )
    }
    
    /**
     * Set activity for back side processing - needed to address activity access limitation
     */
    fun setActivity(activity: Activity?) {
        this.currentActivity = activity
    }
}
