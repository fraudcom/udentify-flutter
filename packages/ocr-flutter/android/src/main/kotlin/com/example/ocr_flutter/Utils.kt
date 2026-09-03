package com.example.ocr_flutter

import android.util.Log
import io.udentify.android.ocr.model.CardOCRMessage

/**
 * Utility functions and helper methods for the OCR Flutter plugin
 */
object Utils {
    private const val TAG = "OcrFlutterUtils"

    /**
     * Convert CardOCRMessage to Flutter-compatible Map
     */
    fun ocrDataToMap(cardOCRMessage: CardOCRMessage): Map<String, Any?> {
        return mapOf(
            "responseType" to "idCard",
            "idCardResponse" to mapOf(
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
                "ocrPhotoExists" to (cardOCRMessage.getOcrPhotoExists() ?: "false"),
                "ocrSignatureExists" to (cardOCRMessage.getOcrSignatureExists() ?: "false"),
                "ocrDocumentExpired" to (cardOCRMessage.getOcrDocumentExpired() ?: "false"),
                "ocrIdValid" to (cardOCRMessage.getOcrIdValid() ?: "false"),
                "nativeFirstName" to cardOCRMessage.getIdCardOCRResponse()?.getNativeFirstName(),
                "nativeLastName" to cardOCRMessage.getIdCardOCRResponse()?.getNativeLastName(),
                "nativeGender" to cardOCRMessage.getIdCardOCRResponse()?.getNativeGender()
            )
        )
    }

    /**
     * Parse color string (hex) to Android color int
     */
    fun parseColorString(colorString: String): Int {
        try {
            var cleanColor = colorString.trim()
            
            // Handle different color formats
            if (cleanColor.startsWith("#")) {
                return android.graphics.Color.parseColor(cleanColor)
            } else if (cleanColor.startsWith("0x")) {
                cleanColor = "#" + cleanColor.substring(2)
                return android.graphics.Color.parseColor(cleanColor)
            } else if (cleanColor.matches(Regex("^[0-9A-Fa-f]{6}$")) || cleanColor.matches(Regex("^[0-9A-Fa-f]{8}$"))) {
                return android.graphics.Color.parseColor("#$cleanColor")
            } else {
                Log.w(TAG, "Unable to parse color: $colorString, using default purple")
                return android.graphics.Color.parseColor("#844EE3") // Default purple
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing color '$colorString': ${e.message}")
            return android.graphics.Color.parseColor("#844EE3") // Default purple
        }
    }

    /**
     * Get the default user ID used by the plugin
     */
    fun getDefaultUserId(): String = "EcNzFN26S24/uf1tv7d+FXHgAPMzEye8"

    /**
     * Close the SDK camera UI and return to the Flutter UI.
     *
     * The SDK fragments live in OcrHostActivity, so finishing that activity tears the whole
     * SDK screen stack down at once. No-op when no SDK screen is showing.
     */
    fun dismissCameraFragment() {
        try {
            OcrHostActivity.dismiss()
        } catch (e: Exception) {
            // Log error but don't crash the app
            Log.e(TAG, "Failed to dismiss camera fragment: ${e.message}")
        }
    }
}
