package com.ocrflutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.os.Parcel
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardRecognizer
import io.udentify.android.ocr.activities.CardRecognizerObject
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.DocumentLivenessListener
import io.udentify.android.ocr.model.CardOCRMessage
import io.udentify.android.ocr.model.IQAFeedback
import io.udentify.android.ocr.model.IQAResponse
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse
import io.udentify.android.ocr.model.OCRDirective

/**
 * Handles document liveness functionality for the OCR Flutter plugin
 */
class DocumentLivenessManager(
    private val ocrCameraManager: OcrCameraManager
) {
    companion object {
        private const val TAG = "DocumentLivenessManager"
    }
    
    private var currentResult: Result? = null
    private var pluginInstance: OcrFlutterPlugin? = null

    fun setPluginInstance(plugin: OcrFlutterPlugin) {
        pluginInstance = plugin
    }
    
    /**
     * Perform document liveness check
     */
    fun performDocumentLiveness(call: MethodCall, result: Result, activity: Activity?) {
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            // Base64 images (optional): the camera's captures stand in when none is passed.
            val (frontSidePhoto, backSidePhoto) = resolvePhotos(
                call.argument<String?>("frontSidePhoto"),
                call.argument<String?>("backSidePhoto"),
                pluginInstance?.getStoredFrontImage(),
                pluginInstance?.getStoredBackImage()
            )
            // No request timeout here: the SDK's performDocumentLiveness(...) uses its own fixed 30 seconds (only
            // processOCR() and the zero-argument performOCRAndDocumentLiveness() read it from the credentials).
            // The SDK has no other performDocumentLiveness overload, so this call cannot honour a per-call timeout.
            
            // Check if at least one image is provided
            if (frontSidePhoto.isNullOrEmpty() && backSidePhoto.isNullOrEmpty()) {
                result.error("MISSING_IMAGES", "At least one image (front or back side) is required for document liveness", null)
                return
            }
            
            val currentActivity = activity ?: run {
                result.error("ACTIVITY_ERROR", "Activity is not available", null)
                return
            }
            
            // Store the result for later use in callbacks
            currentResult = result
            
            // Create DocumentLivenessListener
            val documentLivenessListener = createDocumentLivenessListener()
            
            // Create CardRecognizerObject with SINGLE parameter (as per Android docs line 408-410)
            // "With this approach, we assume that the Document Liveness photo/photos are provided to our SDK externally"
            val cardRecognizerObject = CardRecognizerObject(
                currentActivity  // Single parameter constructor for Document Liveness only
            )
            
            // Call performDocumentLiveness with the required parameters
            cardRecognizerObject.performDocumentLiveness(
                serverURL,
                transactionID, 
                frontSidePhoto ?: "",
                backSidePhoto ?: "",
                documentLivenessListener
            )
            
        } catch (e: Exception) {
            result.error("PERFORM_DOCUMENT_LIVENESS_ERROR", "Failed to perform document liveness: ${e.message}", null)
        }
    }
    
    /**
     * Perform OCR and Document Liveness combined
     */
    fun performOCRAndDocumentLiveness(call: MethodCall, result: Result, activity: Activity?) {
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            // Base64 images (optional): the camera's captures stand in when none is passed.
            val (frontSidePhoto, backSidePhoto) = resolvePhotos(
                call.argument<String?>("frontSidePhoto"),
                call.argument<String?>("backSidePhoto"),
                pluginInstance?.getStoredFrontImage(),
                pluginInstance?.getStoredBackImage()
            )
            val documentTypeStr = call.argument<String>("documentType") ?: throw IllegalArgumentException("documentType is required")
            val countryStr = call.argument<String?>("country")
            // Seconds, 30 when unset: the zero-argument performOCRAndDocumentLiveness() used below reads it from the credentials.
            val requestTimeout = call.argument<Int?>("requestTimeout")?.takeIf { it > 0 }

            // Check if at least one image is provided
            if (frontSidePhoto.isNullOrEmpty() && backSidePhoto.isNullOrEmpty()) {
                result.error("MISSING_IMAGES", "At least one image (front or back side) is required for OCR and document liveness", null)
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

            // Store the result for later use in callbacks
            currentResult = result

            // Create DocumentLivenessListener (same as performDocumentLiveness)
            val documentLivenessListener = createDocumentLivenessListener()

            // Unlike performDocumentLiveness(), performOCRAndDocumentLiveness takes no
            // DocumentLivenessListener. It delivers its result through the CardRecognizer passed to
            // CardRecognizerObject's constructor, calling back through
            // didFinishOcrAndDocumentLivenessCheck()/onFailure().
            //
            // The zero-argument overload (ocr-26.3.0928.aar) takes the server URL, transaction, document
            // type, country and request timeout from getCredentials() and the images from the constructor. It always posts to
            // /ocr/ocrAndLiveness, whatever the credentials' isDocumentLivenessActive says. The
            // four-argument overload ignores the credentials' timeout and uses a fixed 30 seconds.
            //
            // Build a minimal CardRecognizer here (rather than reusing ocrCameraManager) so the
            // callback bridges straight into documentLivenessListener - and therefore
            // currentResult - exactly like performDocumentLiveness does, instead of firing the
            // onOCRAndDocumentLivenessResult/Failure channel events used by the live camera flow.
            val credentialsBuilder = CardRecognizerCredentials.Builder()
                .serverURL(serverURL)
                .transactionID(transactionID)
                .docType(documentType)
                .countryCode(mappedCountryCode)
            requestTimeout?.let { credentialsBuilder.requestTimeout(it) }
            val credentials = credentialsBuilder.build()

            val cardRecognizer = object : CardRecognizer {
                override fun frontSideImage(s: String?, croppedFrontSideImage: String?) {}
                override fun backSideImage(s: String?, croppedBackSideImage: String?) {}
                override fun cardScanFinished() {}
                override fun onResult(cardOCRMessage: CardOCRMessage) {}
                override fun onPhotoTaken() {}
                override fun onIqaResult(iqaResponse: IQAResponse, iqaFeedback: IQAFeedback) {}
                override fun onOCRDirectiveChanged(directive: OCRDirective) {}
                override fun getCredentials(): CardRecognizerCredentials = credentials

                override fun onFailure(s: String) {
                    documentLivenessListener.errorResponse(s)
                }

                override fun didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse) {
                    if (response.isFailed()) {
                        documentLivenessListener.errorResponse(
                            response.errorCode ?: "OCR and document liveness check failed"
                        )
                    } else {
                        documentLivenessListener.successResponse(response)
                    }
                }

                override fun writeToParcel(dest: Parcel, flags: Int) {}
                override fun describeContents(): Int = 0
            }

            // The images go in with the constructor, together with the CardRecognizer above so the
            // SDK's callback has somewhere to deliver the result.
            val cardRecognizerObject = CardRecognizerObject(
                cardRecognizer,
                currentActivity,
                frontSidePhoto ?: "",
                backSidePhoto ?: ""
            )

            cardRecognizerObject.performOCRAndDocumentLiveness()

        } catch (e: Exception) {
            result.error("PERFORM_OCR_AND_DOCUMENT_LIVENESS_ERROR", "Failed to perform OCR and document liveness: ${e.message}", null)
        }
    }
    
    /**
     * Create DocumentLivenessListener for handling responses
     */
    private fun createDocumentLivenessListener(): DocumentLivenessListener {
        return object : DocumentLivenessListener {
            override fun successResponse(response: OCRAndDocumentLivenessResponse) {
                Handler(Looper.getMainLooper()).post {
                    // The call is over: the captured photos of a person's document are not kept.
                    pluginInstance?.clearStoredImages()
                    try {
                        Log.i(TAG, "🎉 Android OCR+Liveness successResponse called")
                        Log.i(TAG, "   Response.isFailed(): ${response.isFailed()}")
                        // The same mapping the camera flow uses, built from the SDK's getters.
                        val resultMap = ocrCameraManager.buildLivenessResultMap(response)
                        
                        Log.i(TAG, "📤 Android: Sending OCR+Liveness result to Flutter")
                        Log.i(TAG, "   Result keys: ${resultMap.keys}")
                        currentResult?.success(resultMap)
                        currentResult = null
                    } catch (e: Exception) {
                        Log.e(TAG, "❌ Error converting OCR+Liveness result: ${e.message}")
                        currentResult?.error("OCR_LIVENESS_CONVERSION_ERROR", "Failed to convert result: ${e.message}", null)
                        currentResult = null
                    }
                }
            }
            
            override fun errorResponse(errorMessage: String) {
                Handler(Looper.getMainLooper()).post {
                    pluginInstance?.clearStoredImages()
                    Log.e(TAG, "❌ Android OCR+Liveness errorResponse: $errorMessage")
                    currentResult?.error("OCR_AND_DOCUMENT_LIVENESS_FAILED", errorMessage, null)
                    currentResult = null
                }
            }
        }
    }
}
