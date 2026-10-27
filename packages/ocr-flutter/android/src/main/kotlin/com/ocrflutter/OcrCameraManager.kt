package com.ocrflutter

import android.app.Activity
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Parcel
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.udentify.android.ocr.activities.CardRecognizer
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.CardFragment
import io.udentify.android.ocr.activities.DocumentType
import io.udentify.android.ocr.activities.Process
import io.udentify.android.ocr.model.CardOCRMessage
import io.udentify.android.ocr.model.DocumentLivenessResponse
import io.udentify.android.ocr.model.IQAFeedback
import io.udentify.android.ocr.model.IQAResponse
import io.udentify.android.ocr.model.OCRAndDocumentLivenessResponse
import io.udentify.android.ocr.model.OCRDirective
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
    // True when the camera only captures and the images are sent by performOCR (see startOCRCamera).
    private var captureOnly = false

    // The orientation the camera screens use (the SDK's cardOrientation: false horizontal, true vertical).
    private var cardOrientationVertical: Boolean = false
    private var isLivenessMode: Boolean = false
    private var cardRecognizerCredentials: CardRecognizerCredentials? = null
    private var currentResult: Result? = null
    private var currentActivity: Activity? = null
    private var pluginInstance: OcrFlutterPlugin? = null

    // The Result for a standalone (non-camera) performOCR call. When set, onResult()/
    // onFailure() resolve it directly instead of firing the onOCRSuccess/onOCRFailure
    // channel events used by the live camera flow - see OcrProcessor.performOCR().
    private var directOcrResult: Result? = null

    fun setPluginInstance(plugin: OcrFlutterPlugin) {
        pluginInstance = plugin
    }

    // Used by the standalone performOCR (provided-photos) path so the SDK's
    // getCredentials() call finds valid credentials even without a prior startOCRCamera.
    fun setCredentials(credentials: CardRecognizerCredentials) {
        cardRecognizerCredentials = credentials
    }

    /**
     * Registers (or clears, when null) the pending [Result] for a standalone performOCR call
     * made through OcrProcessor. CardRecognizerObject.processOCR() delivers its outcome through
     * this class's onResult()/onFailure() (the CardRecognizer callback interface passed into its
     * constructor) - there is no other way to observe completion of a direct call.
     */
    fun setDirectOcrResult(result: Result?) {
        directOcrResult = result
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
            val rawPhotoCropRatio = call.argument<Double>("rawPhotoCropRatio")

            val currentActivity = activity ?: run {
                result.error("ACTIVITY_ERROR", "Activity is not available", null)
                return
            }

            PermissionManager.missingPermission(currentActivity)?.let { (code, message) ->
                result.error(code, message, null)
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

            // The call's own manualCapture flag reaches the SDK too. The UI config may already have turned
            // manual capture on, so only a true here changes anything.
            if (manualCapture) builder.manualCapture(true)

            // livenessMode is the one flag callers use to request the combined OCR+liveness
            // flow, so force the SDK's own liveness flag here too - otherwise callers would
            // also have to separately set documentLivenessEnabled in the UI config, and the
            // SDK's real document-liveness check would never actually run.
            if (livenessMode) {
                builder.isDocumentLivenessActive(true)
            }

            // The camera only captures; the images are sent by performOCR, the flow every platform documents (the
            // iOS camera is created withApiCallDisabled for the same reason). With the SDK's own upload left on,
            // a capture is uploaded here and then again by performOCR, and the two responses race for the same
            // callback. The SDK's document-liveness flow is its own upload, so that one keeps it.
            captureOnly = !livenessMode && !uiConfigManager.documentLivenessConfigured()
            if (captureOnly) builder.apiCallEnabled(false)

            // The call's own value wins over the UI config's (applied above), as on iOS. The SDK takes a
            // percentage, the Dart API a 0.0-1.0 ratio.
            rawPhotoCropRatio?.let { UIConfigurationManager.cropRatioToPercent(it) }?.let { percent ->
                Log.d(TAG, "OcrCameraManager - rawPhotoCropRatio applied to credentials: $percent%")
                builder.rawPhotoCropRatio(percent)
            }

            cardRecognizerCredentials = builder.build()
            currentResult = result
            currentDocumentSide = documentSideStr
            frontSideImagePath = null
            isLivenessMode = livenessMode
            this.currentActivity = currentActivity

            val process = when (documentSideStr) {
                "frontSide" -> Process.frontSide
                "backSide" -> Process.backSide
                "showImage" -> Process.showImage
                "bothSides" -> Process.frontSide 
                else -> Process.frontSide 
            }
            
            // Apply orientation from UI configuration
            val cardOrientation = uiConfigManager.getStoredUIConfig()?.get("orientation") == "vertical"
            cardOrientationVertical = cardOrientation
            Log.d(TAG, "🚀 OcrCameraManager - Applying card orientation: $cardOrientation (${uiConfigManager.getStoredUIConfig()?.get("orientation")})")
            
            val cardFragment = CardFragment.newInstance(process, cardOrientation, this)

            OcrHostActivity.start(currentActivity, cardFragment)

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
            Utils.dismissCameraFragment()
            currentResult = null // Clear any pending result
            currentActivity = null // Clear activity reference
            result.success("cancelled")
        } catch (e: Exception) {
            result.error("CANCEL_ERROR", "Failed to cancel OCR camera: ${e.message}", null)
        }
    }
    
    /**
     * Proceed to back side capture after front side is completed
     */
    private fun proceedToBackSideCapture(activity: Activity?) {
        try {
            val frontImagePath = frontSideImagePath ?: return

            // Colors should already be applied early in the process

            // Create CardFragment for back side, passing the front side image. The third argument is the SDK's
            // cardOrientation (it was given manualCapture before, which turned the screen vertical).
            val backSideFragment = CardFragment.newInstance(Process.backSide, frontImagePath, cardOrientationVertical, this)

            OcrHostActivity.showFragment(backSideFragment)

        } catch (e: Exception) {
            currentResult?.error("OCR_CAMERA_ERROR", "Failed to proceed to back side capture: ${e.message}", null)
        }
    }
    
    // MARK: - CardRecognizer Interface Implementation
    
    override fun frontSideImage(s: String?, croppedFrontSideImage: String?) {
        Handler(Looper.getMainLooper()).post {
            Log.d(TAG, "OcrCameraManager - Front side image captured: ${s?.length} chars")
            
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
                    "frontSidePhoto" to IMAGE_PATH_STORED,
                    "backSidePhoto" to null
                )
                channel.invokeMethod("onDocumentScan", documentScanData)
                // Nothing else follows a single front side, so the screen closes here in every mode. With IQA on the
                // SDK's own front-side path closes nothing (only the back side does), and without an upload no
                // onPhotoTaken closes it either, so the Next button would otherwise do nothing.
                Utils.dismissCameraFragment()
            }
        }
    }

    override fun backSideImage(s: String?, croppedBackSideImage: String?) {
        Handler(Looper.getMainLooper()).post {
            Log.d(TAG, "OcrCameraManager - Back side image captured: ${s?.length} chars")
            
            // Store both images in plugin for later use 
            pluginInstance?.storeDocumentScanImages(frontSideImagePath, s)
            
            // Send placeholder to indicate images are stored 
            Log.d(TAG, "OcrCameraManager - Both sides complete, sending placeholder")
            val documentScanData = mapOf(
                "documentSide" to "bothSides",
                "frontSidePhoto" to IMAGE_PATH_STORED,
                "backSidePhoto" to IMAGE_PATH_STORED
            )
            channel.invokeMethod("onDocumentScan", documentScanData)
            if (captureOnly) Utils.dismissCameraFragment()
        }
    }

    override fun cardScanFinished() {
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onCardScanFinished", null)
            // With the SDK's upload on, onPhotoTaken closes the screen when the upload starts; capture-only
            // never reaches it, so the capture ending is what closes it.
            if (captureOnly) Utils.dismissCameraFragment()
        }
    }

    override fun onResult(cardOCRMessage: CardOCRMessage) {

        Handler(Looper.getMainLooper()).post {
            // A standalone performOCR call (OcrProcessor) has no camera UI and is waiting on
            // this exact callback to resolve its Result - complete it directly instead of
            // firing the onOCRSuccess channel event nothing is listening for in that case. This
            // is checked before isLivenessMode below since a leftover camera-flow flag from an
            // earlier startOCRCamera session must never swallow a standalone call's result.
            val pendingDirectResult = directOcrResult
            if (pendingDirectResult != null) {
                directOcrResult = null
                pluginInstance?.clearStoredImages()
                try {
                    val ocrResponseMap = buildOcrResponseMap(cardOCRMessage).toMutableMap()
                    ocrResponseMap["success"] = true
                    ocrResponseMap["transactionID"] = cardRecognizerCredentials?.transactionID
                    ocrResponseMap["timestamp"] = System.currentTimeMillis().toDouble()
                    ocrResponseMap["documentType"] = cardRecognizerCredentials?.docType?.name
                    pendingDirectResult.success(ocrResponseMap)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Error converting direct OCR result: ${e.message}")
                    pendingDirectResult.error("PERFORM_OCR_ERROR", "Failed to convert OCR result: ${e.message}", null)
                }
                return@post
            }

            if (isLivenessMode) {
                // The combined result arrives via didFinishOcrAndDocumentLivenessCheck() once
                // the SDK's real document-liveness check completes - nothing to do here.
                Log.d(TAG, "OcrCameraManager - onResult in liveness mode, awaiting didFinishOcrAndDocumentLivenessCheck")
                return@post
            }

            Utils.dismissCameraFragment() // Dismiss the camera UI

            try {
                val ocrResult = buildOcrResponseMap(cardOCRMessage)

                // Send result through method channel callback
                channel.invokeMethod("onOCRSuccess", ocrResult)
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error converting OCR result to map: ${e.message}")
                channel.invokeMethod("onOCRFailure", mapOf("error" to "Failed to convert OCR result: ${e.message}"))
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
            // Same bridging as onResult(): a standalone performOCR call needs its Result
            // resolved directly since nothing is listening for the onOCRFailure channel event.
            val pendingDirectResult = directOcrResult
            if (pendingDirectResult != null) {
                directOcrResult = null
                pluginInstance?.clearStoredImages()
                pendingDirectResult.error("PERFORM_OCR_ERROR", s, null)
                return@post
            }

            Utils.dismissCameraFragment() // Dismiss the camera UI

            // Send failure through method channel callback
            channel.invokeMethod("onOCRFailure", failureArguments(s))

            currentResult = null // Clear the result reference
        }
    }

    override fun onPhotoTaken() {
        Handler(Looper.getMainLooper()).post {
            Utils.dismissCameraFragment() // Dismiss camera immediately
            channel.invokeMethod("onPhotoTaken", null)
        }
    }

    override fun didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse) {
        Handler(Looper.getMainLooper()).post {
            Utils.dismissCameraFragment() // Dismiss the camera UI
            pluginInstance?.clearStoredImages()

            try {
                if (response.isFailed()) {
                    channel.invokeMethod(
                        "onOCRAndDocumentLivenessFailure",
                        failureArguments(response.errorCode ?: "Document liveness check failed")
                    )
                } else {
                    channel.invokeMethod("onOCRAndDocumentLivenessResult", buildLivenessResultMap(response))
                }
            } catch (e: Exception) {
                Log.e(TAG, "❌ Error converting OCR+DocumentLiveness result: ${e.message}")
                channel.invokeMethod(
                    "onOCRAndDocumentLivenessFailure",
                    mapOf("error" to "Failed to convert OCR and document liveness result: ${e.message}")
                )
            }

            currentResult = null // Clear the result reference
        }
    }

    override fun onIqaResult(iqaResponse: IQAResponse, iqaFeedback: IQAFeedback) {
        Log.d(TAG, "OcrCameraManager - IQA Result: feedback=${iqaFeedback.name}, side=${iqaResponse.documentSide?.name}")

        Handler(Looper.getMainLooper()).post {
            val iqaData = mapOf(
                "documentSide" to iqaDocumentSideToString(iqaResponse.documentSide),
                "feedback" to iqaFeedbackToString(iqaFeedback),
                "qualified" to (iqaResponse.isQualified ?: false),
                "displayMessage" to (iqaResponse.displayMessage ?: ""),
                "rawMessage" to (iqaResponse.rawMessage ?: ""),
                "checks" to iqaResponse.checks?.entries?.associate { it.key.name to it.value },
                "timestamp" to System.currentTimeMillis().toDouble()
            )
            channel.invokeMethod("onIQAResult", iqaData)
        }
    }

    /**
     * Explicit IQAFeedback -> camelCase string mapping, mirroring iOS's onIqaResult switch
     * (OcrFlutterPlugin.swift). Dart's IQAFeedback enum (iqa_feedback.dart) and IQAResult.fromMap's
     * exact-match firstWhere expect camelCase like "blurDetected"; `iqaFeedback.name.lowercase()`
     * produced "blurdetected" and silently collapsed every non-"success" result to `other`.
     */
    private fun iqaFeedbackToString(feedback: IQAFeedback): String = when (feedback) {
        IQAFeedback.Success -> "success"
        IQAFeedback.BlurDetected -> "blurDetected"
        IQAFeedback.GlareDetected -> "glareDetected"
        IQAFeedback.HologramGlare -> "hologramGlare"
        IQAFeedback.CardNotDetected -> "cardNotDetected"
        IQAFeedback.CardClassificationMismatch -> "cardClassificationMismatch"
        IQAFeedback.CardNotIntact -> "cardNotIntact"
        IQAFeedback.FaceNotDetected -> "faceNotDetected"
        IQAFeedback.MultipleDocumentsDetected -> "multipleDocumentsDetected"
        // The SDK's Android names say "Absent"; the value sent to Dart is the same "...NotDetected"
        // spelling iOS uses, so one Dart enum covers both platforms.
        IQAFeedback.ChipAbsent -> "chipNotDetected"
        IQAFeedback.SignatureAbsent -> "signatureNotDetected"
        IQAFeedback.HiddenPhotoAbsent -> "hiddenPhotoNotDetected"
        IQAFeedback.PhotoCheatDetected -> "photoCheatDetected"
        IQAFeedback.Other -> "other"
    }

    /**
     * The SDK's `Process` enum (`frontSide`/`backSide`/`showImage`) as the same spelling iOS sends
     * (`frontSide` / `backSide` / `bothSides`); `.name.lowercase()` produced "frontside".
     */
    private fun iqaDocumentSideToString(side: Process?): String = when (side) {
        Process.frontSide -> "frontSide"
        Process.backSide -> "backSide"
        Process.showImage -> "bothSides"
        null -> "unknown"
    }

    override fun onOCRDirectiveChanged(directive: OCRDirective) {
        Log.d(TAG, "OcrCameraManager - OCR Directive changed: ${directive.name}")
        Handler(Looper.getMainLooper()).post {
            channel.invokeMethod("onOCRDirectiveChanged", mapOf(
                "directive" to directive.name,
                "timestamp" to System.currentTimeMillis().toDouble()
            ))
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
     * Build the combined OCR+DocumentLiveness result from the SDK's real
     * didFinishOcrAndDocumentLivenessCheck() response. The standalone performDocumentLiveness /
     * performOCRAndDocumentLiveness calls use it too, so every path hands Dart the same shape.
     */
    internal fun buildLivenessResultMap(response: OCRAndDocumentLivenessResponse): Map<String, Any?> {
        return mapOf(
            "isFailed" to response.isFailed(),
            "ocrData" to response.ocrData?.let { mapOf("ocrResponse" to buildOcrResponseMap(it)) },
            "documentLivenessDataFront" to mapDocumentLivenessData(response.documentLivenessDataFront),
            "documentLivenessDataBack" to mapDocumentLivenessData(response.documentLivenessDataBack)
        )
    }

    /**
     * The SDK returns a single pipeline result per side; wrap it in a one-element list to
     * match the Dart side's DocumentLivenessResponse.pipelineResults (List<...>) shape.
     */
    private fun mapDocumentLivenessData(response: DocumentLivenessResponse?): Map<String, Any?>? {
        if (response == null) return null
        val pipeline = response.pipelines
        return mapOf(
            "documentLivenessResponse" to mapOf(
                "aggregateDocumentLivenessProbability" to response.aggregateDocumentLivenessProbability,
                "aggregateDocumentImageQualityWarnings" to response.aggregateDocumentImageQualityWarnings,
                "pipelineResults" to pipeline?.let {
                    listOf(
                        mapOf(
                            "name" to it.pipelineName,
                            "calibration" to it.calibration,
                            "documentLivenessScore" to it.documentLivenessScore,
                            "documentLivenessProbability" to it.documentLivenessProbability,
                            "documentStatusCode" to it.documentStatusCode
                        )
                    )
                }
            ),
            "error" to pipeline?.errorCode
        )
    }

    /**
     * Build the ocrResponse map (shared by plain OCR success and the liveness-combined result).
     */
    private fun buildOcrResponseMap(cardOCRMessage: CardOCRMessage): Map<String, Any?> {
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
                // The licence-specific values (type, city, district, QR checks) are in the SDK's nested response.
                val licence = cardOCRMessage.getDriverLicenceOCRResponse()
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
                    "ocrQRApproved" to licence?.getOcrQrApproval(),
                    "ocrQRLicenceID" to licence?.getOcrQrLicenceId(),
                    "ocrQRIdentityNo" to licence?.getOcrQrIdentityNo(),
                    "ocrQRIdentityNoCheck" to licence?.getOcrQrIdentityNoCheck(),
                    "ocrQRLicenceIDCheck" to licence?.getOcrQrLicenceIdCheck(),
                    "ocrLicenceType" to licence?.getOcrLicenceType(),
                    "city" to licence?.getCity(),
                    "district" to licence?.getDistrict(),
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
            "passport" -> {
                // Dart reads a passport from `extractedData` (as iOS sends it), not from idCardResponse.
                val passport = cardOCRMessage.getPassportOCRResponse()
                ocrResponseMap["documentType"] = "PASSPORT"
                ocrResponseMap["extractedData"] = mapOf(
                    "firstName" to (cardOCRMessage.getName() ?: ""),
                    "lastName" to (cardOCRMessage.getSurname() ?: ""),
                    "documentNumber" to (cardOCRMessage.getDocumentId() ?: ""),
                    "identityNo" to (cardOCRMessage.getIdentityNo() ?: ""),
                    "expiryDate" to (cardOCRMessage.getExpireDate() ?: ""),
                    "birthDate" to (cardOCRMessage.getBirthDate() ?: ""),
                    "nationality" to (cardOCRMessage.getNationality() ?: ""),
                    "gender" to (cardOCRMessage.getGender() ?: ""),
                    "countryCode" to (cardOCRMessage.getDocumentCountry() ?: ""),
                    "isDocumentExpired" to cardOCRMessage.getOcrDocumentExpired(),
                    "isIDValid" to cardOCRMessage.getOcrIdValid(),
                    "nativeFirstName" to (passport?.getNativeFirstName() ?: ""),
                    "nativeLastName" to (passport?.getNativeLastName() ?: ""),
                    "nativeGender" to (passport?.getNativeGender() ?: ""),
                    "faceImage" to (cardOCRMessage.getFcaseImg() ?: "")
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
                    "isFailed" to cardOCRMessage.getFailed(),
                    "nativeFirstName" to cardOCRMessage.getIdCardOCRResponse()?.getNativeFirstName(),
                    "nativeLastName" to cardOCRMessage.getIdCardOCRResponse()?.getNativeLastName(),
                    "nativeGender" to cardOCRMessage.getIdCardOCRResponse()?.getNativeGender()
                )
            }
        }
        
        return ocrResponseMap
    }
    
    /**
     * Set activity for back side processing - needed to address activity access limitation
     */
    fun setActivity(activity: Activity?) {
        this.currentActivity = activity
    }
}
