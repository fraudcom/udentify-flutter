package com.example.ocr_flutter

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.provider.MediaStore
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardRecognizerObject
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.IQAListener
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.IQAResponse
import java.io.ByteArrayOutputStream

/**
 * Handles direct OCR processing operations without camera UI
 */
class OcrProcessor(
    private val ocrCameraManager: OcrCameraManager
) {
    companion object {
        private const val TAG = "OcrProcessor"
    }
    
    private var pluginInstance: OcrFlutterPlugin? = null
    
    fun setPluginInstance(plugin: OcrFlutterPlugin) {
        pluginInstance = plugin
    }
    
    /**
     * Perform OCR on provided images
     */
    fun performOCR(call: MethodCall, result: Result, activity: Activity?) {
        Log.i(TAG, "🔍 Android DEBUG: performOCR called")
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            val userID = call.argument<String?>("userID")
            val documentTypeStr = call.argument<String>("documentType") ?: throw IllegalArgumentException("documentType is required")
            val countryStr = call.argument<String?>("country")
            // Dart OCRProcessParams.toMap() sends the keys "frontSidePhoto"/"backSidePhoto".
            // These must match, otherwise externally-provided photos are never read and the
            // code silently falls back to the camera-captured stored images below.
            var frontSideImage = call.argument<String?>("frontSidePhoto") // Base64 image (optional)
            var backSideImage = call.argument<String?>("backSidePhoto")   // Base64 image (optional)

            // The camera-capture flow sends the sentinel "IMAGE_PATH_STORED" to signal that the
            // captured images are held natively. Treat it (and empty) as "no external photo
            // provided" so we fall back to the stored images below, instead of sending the
            // sentinel string to the SDK as if it were image data.
            if (frontSideImage == "IMAGE_PATH_STORED") frontSideImage = null
            if (backSideImage == "IMAGE_PATH_STORED") backSideImage = null

            // Tolerate an optional "data:image/...;base64," data-URI prefix on provided photos.
            frontSideImage = frontSideImage?.let { if (it.contains("base64,")) it.substringAfter("base64,") else it }
            backSideImage = backSideImage?.let { if (it.contains("base64,")) it.substringAfter("base64,") else it }

            // Use stored images if parameters are empty
            if (frontSideImage.isNullOrEmpty() && backSideImage.isNullOrEmpty()) {
                Log.i(TAG, "OcrProcessor - No images in parameters, checking stored images...")
                frontSideImage = pluginInstance?.getStoredFrontImage()
                backSideImage = pluginInstance?.getStoredBackImage()
                Log.i(TAG, "OcrProcessor - Stored front image: ${if (frontSideImage?.isNotEmpty() == true) "${frontSideImage.length} chars" else "empty"}")
                Log.i(TAG, "OcrProcessor - Stored back image: ${if (backSideImage?.isNotEmpty() == true) "${backSideImage.length} chars" else "empty"}")
            }
            
            Log.i(TAG, "   Server URL: $serverURL")
            Log.i(TAG, "   Transaction ID: $transactionID")
            Log.i(TAG, "   Document Type: $documentTypeStr")
            Log.i(TAG, "   Country: $countryStr")
            Log.i(TAG, "   Front Image: ${if (frontSideImage?.isNotEmpty() == true) "✅ Present (${frontSideImage.length} chars)" else "❌ Missing"}")
            Log.i(TAG, "   Back Image: ${if (backSideImage?.isNotEmpty() == true) "✅ Present (${backSideImage.length} chars)" else "❌ Missing"}")
            
            // Check if images are provided or stored
            if (frontSideImage.isNullOrEmpty() && backSideImage.isNullOrEmpty()) {
                result.error("MISSING_IMAGES", "At least one image (front or back side) is required for OCR processing", null)
                return
            }
            
            val currentActivity = activity ?: run {
                result.error("ACTIVITY_ERROR", "Activity is not available", null)
                return
            }

            // Convert document type string to DocumentType enum
            val documentType = when (documentTypeStr) {
                "ID_CARD" -> DocumentType.OCR_ID_UPLOAD
                "PASSPORT" -> DocumentType.OCR_PASSPORT_UPLOAD
                "DRIVER_LICENSE" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
                else -> DocumentType.OCR_ID_UPLOAD // Default fallback
            }

            // Map country code using CountryCodeMapper
            val mappedCountryCode = CountryCodeMapper.toCountryCode(countryStr ?: "TUR")
            Log.i(TAG, "OcrProcessor - Country: $countryStr -> $mappedCountryCode")

            // Create credentials
            val cardRecognizerCredentials = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .userID(userID ?: Utils.getDefaultUserId())
                .docType(documentType)
                .countryCode(mappedCountryCode)
                .build()

            // The SDK reads credentials through the CardRecognizer's getCredentials(). Since
            // CardRecognizerObject is created with ocrCameraManager as the recognizer, make
            // the credentials available there — otherwise a standalone performOCR (without a
            // prior startOCRCamera) fails with "Credentials not initialized".
            ocrCameraManager.setCredentials(cardRecognizerCredentials)

            // Create CardRecognizerObject with provided images (according to documentation)
            // Use empty string if image is null (SDK might handle this better)
            val cardRecognizerObject = CardRecognizerObject(
                ocrCameraManager,                   // CardRecognizer interface
                currentActivity,                    // Activity
                frontSideImage ?: "",              // Front side image in base64
                backSideImage ?: ""                // Back side image in base64
            )

            Log.i(TAG, "🚀 Android: Calling CardRecognizerObject.processOCR() with:")
            Log.i(TAG, "   📤 Front Image: ${if (frontSideImage?.isNotEmpty() == true) "✅ Present" else "❌ Empty"}")
            Log.i(TAG, "   📤 Back Image: ${if (backSideImage?.isNotEmpty() == true) "✅ Present" else "❌ Empty"}")
            Log.i(TAG, "   📤 Document Type: $documentType")
            Log.i(TAG, "   📤 Country: $countryStr")

            // Start OCR processing
            cardRecognizerObject.processOCR()

        } catch (e: Exception) {
            result.error("PERFORM_OCR_ERROR", "Failed to perform OCR: ${e.message}", null)
        }
    }
    
    /**
     * Scan card from provided images
     */
    fun scanCardFromImages(call: MethodCall, result: Result, activity: Activity?) {
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
            val frontSideImage = arguments?.get("frontSideImage") as? String ?: ""
            val backSideImage = arguments?.get("backSideImage") as? String ?: ""

            // Map country code using CountryCodeMapper
            val mappedCountryCode = CountryCodeMapper.toCountryCode(countryCode.ifEmpty { "TUR" })
            Log.i(TAG, "OcrProcessor - Country: $countryCode -> $mappedCountryCode")
            
            // Create credentials
            val cardRecognizerCredentials = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .userID(userID)
                .docType(when (documentType) {
                    "OCR_DRIVER_LICENCE_UPLOAD" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
                    "OCR_PASSPORT_UPLOAD" -> DocumentType.OCR_PASSPORT_UPLOAD
                    else -> DocumentType.OCR_ID_UPLOAD
                })
                .countryCode(mappedCountryCode)
                .build()

            // Create CardRecognizerObject with provided images as per documentation
            val cardRecognizerObject = CardRecognizerObject(
                ocrCameraManager,
                currentActivity,
                frontSideImage,
                backSideImage
            )

            // Process OCR
            cardRecognizerObject.processOCR()

        } catch (e: Exception) {
            result.error("OCR_PROCESS_ERROR", "Failed to process OCR from images: ${e.message}", null)
        }
    }

    fun performIQA(call: MethodCall, result: Result, activity: Activity?) {
        Log.d(TAG, "OcrProcessor - performIQA called")
        try {
            if (activity == null) {
                result.error("IQA_ERROR", "Activity not available", null)
                return
            }

            val serverURL = call.argument<String>("serverURL") ?: ""
            val transactionID = call.argument<String>("transactionID") ?: ""
            val imageBase64 = call.argument<String>("imageBase64") ?: ""
            val documentType = call.argument<String>("documentType") ?: "ID_CARD"
            val documentSide = call.argument<String>("documentSide") ?: "FRONT"
            val country = call.argument<String>("country") ?: "TUR"

            val ocrDocumentType = when (documentType.uppercase()) {
                "ID_CARD" -> DocumentType.OCR_ID_UPLOAD
                "PASSPORT" -> DocumentType.OCR_PASSPORT_UPLOAD
                "DRIVER_LICENSE" -> DocumentType.OCR_DRIVER_LICENCE_UPLOAD
                else -> DocumentType.OCR_ID_UPLOAD
            }

            val ocrDocumentSide = when (documentSide.uppercase()) {
                "FRONT", "FRONTSIDE" -> Process.frontSide
                "BACK", "BACKSIDE" -> Process.backSide
                else -> Process.frontSide
            }

            val cardRecognizerObject = CardRecognizerObject(activity)

            activity.runOnUiThread {
                cardRecognizerObject.performIQA(
                    serverURL,
                    transactionID,
                    imageBase64,
                    country,
                    ocrDocumentType,
                    ocrDocumentSide,
                    object : IQAListener {
                        override fun successResponse(iqaResponse: IQAResponse) {
                            Log.d(TAG, "OcrProcessor - performIQA success: qualified=${iqaResponse.isQualified}")
                            val resultMap = mapOf(
                                "qualified" to iqaResponse.isQualified,
                                "displayMessage" to (iqaResponse.displayMessage ?: ""),
                                "rawMessage" to (iqaResponse.rawMessage ?: ""),
                                "documentSide" to (iqaResponse.documentSide?.name ?: "unknown"),
                                "timestamp" to System.currentTimeMillis().toDouble()
                            )
                            result.success(resultMap)
                        }

                        override fun errorResponse(error: String) {
                            Log.e(TAG, "OcrProcessor - performIQA error: $error")
                            result.error("IQA_ERROR", error, null)
                        }
                    }
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "OcrProcessor - performIQA exception: ${e.message}", e)
            result.error("IQA_EXCEPTION", "Failed to perform IQA: ${e.message}", null)
        }
    }

    fun takePhoto(result: Result, activity: Activity?) {
        Log.d(TAG, "OcrProcessor - takePhoto called")
        try {
            if (activity == null) {
                result.error("TAKE_PHOTO_ERROR", "Activity not available", null)
                return
            }

            val takePictureIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            if (takePictureIntent.resolveActivity(activity.packageManager) != null) {
                activity.startActivityForResult(takePictureIntent, TAKE_PHOTO_REQUEST_CODE)
                // Result will be handled via onActivityResult in the plugin
                pendingTakePhotoResult = result
            } else {
                result.error("TAKE_PHOTO_ERROR", "Camera is not available on this device", null)
            }
        } catch (e: Exception) {
            result.error("TAKE_PHOTO_ERROR", "Failed to open camera: ${e.message}", null)
        }
    }

    fun handleActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != TAKE_PHOTO_REQUEST_CODE) return false

        val result = pendingTakePhotoResult ?: return false
        pendingTakePhotoResult = null

        if (resultCode != Activity.RESULT_OK) {
            result.error("TAKE_PHOTO_ERROR", "Photo capture cancelled", null)
            return true
        }

        try {
            val bitmap = data?.extras?.get("data") as? Bitmap
            if (bitmap != null) {
                val outputStream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 80, outputStream)
                val base64 = Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
                result.success(base64)
            } else {
                result.error("TAKE_PHOTO_ERROR", "Failed to capture image", null)
            }
        } catch (e: Exception) {
            result.error("TAKE_PHOTO_ERROR", "Error processing captured image: ${e.message}", null)
        }
        return true
    }

    private var pendingTakePhotoResult: Result? = null
    private val TAKE_PHOTO_REQUEST_CODE = 9002
}
