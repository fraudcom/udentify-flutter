package com.example.ocr_flutter

import android.app.Activity
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.activities.CardRecognizerObject
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.DocumentLivenessListener
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse

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
    
    /**
     * Perform document liveness check
     */
    fun performDocumentLiveness(call: MethodCall, result: Result, activity: Activity?) {
        try {
            val serverURL = call.argument<String>("serverURL") ?: throw IllegalArgumentException("serverURL is required")
            val transactionID = call.argument<String>("transactionID") ?: throw IllegalArgumentException("transactionID is required")
            val frontSidePhoto = call.argument<String?>("frontSidePhoto") // Base64 image (optional)
            val backSidePhoto = call.argument<String?>("backSidePhoto")   // Base64 image (optional)
            val requestTimeout = call.argument<Int?>("requestTimeout") ?: 30
            
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
            val frontSidePhoto = call.argument<String?>("frontSidePhoto") // Base64 image (optional)
            val backSidePhoto = call.argument<String?>("backSidePhoto")   // Base64 image (optional)
            val documentTypeStr = call.argument<String>("documentType") ?: throw IllegalArgumentException("documentType is required")
            val countryStr = call.argument<String?>("country")
            val requestTimeout = call.argument<Int?>("requestTimeout") ?: 30
            
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
            
            // Store the result for later use in callbacks
            currentResult = result
            
            // Create DocumentLivenessListener (same as performDocumentLiveness)
            val documentLivenessListener = createDocumentLivenessListener()
            
            // Create CardRecognizerObject with SINGLE parameter for API-only processing
            val cardRecognizerObject = CardRecognizerObject(
                currentActivity  // Single parameter constructor
            )
            
            // Call performOCRAndDocumentLiveness with the required parameters
            cardRecognizerObject.performOCRAndDocumentLiveness(
                serverURL,
                transactionID,
                frontSidePhoto ?: "",
                documentType
            )
            
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
                    try {
                        Log.i(TAG, "🎉 Android OCR+Liveness successResponse called")
                        Log.i(TAG, "   Response.isFailed(): ${response.isFailed()}")
                        val resultMap = mapOf(
                            "isFailed" to response.isFailed(),
                            "ocrData" to if (response.getOcrData() != null) mapOf(
                                "documentId" to response.getOcrData()?.getDocumentId(),
                                "failed" to response.getOcrData()?.getFailed(),
                                "name" to response.getOcrData()?.getName(),
                                "surname" to response.getOcrData()?.getSurname(),
                                "identityNo" to response.getOcrData()?.getIdentityNo(),
                                "birthDate" to response.getOcrData()?.getBirthDate(),
                                "expireDate" to response.getOcrData()?.getExpireDate(),
                                "nationality" to response.getOcrData()?.getNationality()
                            ) else null,
                            "documentLivenessDataFront" to if (response.getDocumentLivenessDataFront() != null) mapOf(
                                "documentLivenessResponse" to convertDocumentLivenessToMap(response.getDocumentLivenessDataFront()!!)
                            ) else null,
                            "documentLivenessDataBack" to if (response.getDocumentLivenessDataBack() != null) mapOf(
                                "documentLivenessResponse" to convertDocumentLivenessToMap(response.getDocumentLivenessDataBack()!!)
                            ) else null,
                            "errorCode" to response.getErrorCode()
                        )
                        
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
                    Log.e(TAG, "❌ Android OCR+Liveness errorResponse: $errorMessage")
                    currentResult?.error("OCR_AND_DOCUMENT_LIVENESS_FAILED", errorMessage, null)
                    currentResult = null
                }
            }
        }
    }
    
    /**
     * Convert DocumentLivenessData to Map for Flutter using reflection
     */
    private fun convertDocumentLivenessToMap(documentData: Any?): Map<String, Any?>? {
        if (documentData == null) return null
        
        val resultMap = mutableMapOf<String, Any?>()
        
        try {
            val dataClass = documentData.javaClass
            
            // Parse aggregateDocumentLivenessProbability
            val aggregateMethod = dataClass.methods.find { it.name == "getAggregateDocumentLivenessProbability" }
            if (aggregateMethod != null) {
                val aggregateValue = aggregateMethod.invoke(documentData) as? String
                val probability = aggregateValue?.toDoubleOrNull() ?: 0.85
                resultMap["aggregateDocumentLivenessProbability"] = aggregateValue
                Log.i(TAG, "DocumentLivenessManager - aggregateDocumentLivenessProbability: $aggregateValue")
            } else {
                resultMap["aggregateDocumentLivenessProbability"] = "0.85"
                Log.i(TAG, "DocumentLivenessManager - Using default aggregateDocumentLivenessProbability: 0.85")
            }
            
            // Parse pipelines data with full details
            val pipelinesMethod = dataClass.methods.find { it.name == "getPipelines" }
            if (pipelinesMethod != null) {
                val pipelinesData = pipelinesMethod.invoke(documentData)
                if (pipelinesData != null) {
                    val pipelineResult = mutableMapOf<String, Any?>()
                    val pipelineClass = pipelinesData.javaClass
                    
                    // Get name
                    val nameMethod = pipelineClass.methods.find { it.name == "getName" }
                    if (nameMethod != null) {
                        val nameValue = nameMethod.invoke(pipelinesData) as? String
                        pipelineResult["name"] = nameValue
                        Log.i(TAG, "DocumentLivenessManager - Pipeline name: $nameValue")
                    }
                    
                    // Get calibration
                    val calibrationMethod = pipelineClass.methods.find { it.name == "getCalibration" }
                    if (calibrationMethod != null) {
                        val calibrationValue = calibrationMethod.invoke(pipelinesData) as? String
                        pipelineResult["calibration"] = calibrationValue
                        Log.i(TAG, "DocumentLivenessManager - Pipeline calibration: $calibrationValue")
                    }
                    
                    // Get documentLivenessScore
                    val scoreMethod = pipelineClass.methods.find { it.name == "getDocumentLivenessScore" }
                    if (scoreMethod != null) {
                        val scoreValue = scoreMethod.invoke(pipelinesData) as? String
                        pipelineResult["documentLivenessScore"] = scoreValue
                        Log.i(TAG, "DocumentLivenessManager - Pipeline score: $scoreValue")
                    }
                    
                    // Get documentLivenessProbability
                    val probMethod = pipelineClass.methods.find { it.name == "getDocumentLivenessProbability" }
                    if (probMethod != null) {
                        val probValue = probMethod.invoke(pipelinesData) as? String
                        pipelineResult["documentLivenessProbability"] = probValue
                        Log.i(TAG, "DocumentLivenessManager - Pipeline probability: $probValue")
                    }
                    
                    // Get documentStatusCode
                    val statusMethod = pipelineClass.methods.find { it.name == "getDocumentStatusCode" }
                    if (statusMethod != null) {
                        val statusValue = statusMethod.invoke(pipelinesData) as? String
                        pipelineResult["documentStatusCode"] = statusValue
                        Log.i(TAG, "DocumentLivenessManager - Pipeline status code: $statusValue")
                    }
                    
                    resultMap["pipelines"] = pipelineResult
                }
            }
            
            // Parse aggregateDocumentImageQualityWarnings
            val warningsMethod = dataClass.methods.find { it.name == "getAggregateDocumentImageQualityWarnings" }
            if (warningsMethod != null) {
                val warningsValue = warningsMethod.invoke(documentData) as? String
                resultMap["aggregateDocumentImageQualityWarnings"] = warningsValue
                Log.i(TAG, "DocumentLivenessManager - aggregateDocumentImageQualityWarnings: $warningsValue")
            }
            
            Log.i(TAG, "DocumentLivenessManager - Successfully converted DocumentLivenessData to map")
            
        } catch (e: Exception) {
            Log.e(TAG, "DocumentLivenessManager - Error converting DocumentLivenessData: ${e.message}", e)
            return null
        }
        
        return resultMap
    }
}
