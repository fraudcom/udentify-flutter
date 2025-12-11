package com.example.ocr_flutter

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardRecognizerObject
import io.udentify.android.ocr.activities.DocumentType

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
            var frontSideImage = call.argument<String?>("frontSideImage") // Base64 image (optional)
            var backSideImage = call.argument<String?>("backSideImage")   // Base64 image (optional)
            
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
}
