package com.ocrflutter

import java.util.Date
import android.util.Log
import io.udentify.android.ocr.model.CardOCRMessage

/**
 * Utility functions and helper methods for the OCR Flutter plugin
 */
object Utils {
    private const val TAG = "OcrFlutterUtils"

    /**
     * `#RGB`, `#RRGGBB` or `#AARRGGBB` (also without the `#`, or with `0x`), as an Android color int.
     * `null` for anything else, so the caller leaves the SDK's own colour in place instead of getting a
     * color the app never asked for.
     */
    fun parseColorString(colorString: String): Int? {
        var digits = colorString.trim()
        digits = when {
            digits.startsWith("#") -> digits.substring(1)
            digits.startsWith("0x", ignoreCase = true) -> digits.substring(2)
            else -> digits
        }
        if (digits.length == 3) digits = digits.map { "$it$it" }.joinToString("")
        if (digits.length != 6 && digits.length != 8) {
            Log.w(TAG, "Ignoring color '$colorString': expected #RGB, #RRGGBB or #AARRGGBB")
            return null
        }
        return try {
            android.graphics.Color.parseColor("#$digits")
        } catch (e: IllegalArgumentException) {
            Log.w(TAG, "Ignoring color '$colorString': ${e.message}")
            null
        }
    }

    /**
     * The user ID used when the app passes none: a timestamp, as in the hologram flow.
     */
    fun getDefaultUserId(): String = Date().time.toString()

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

private val SDK_ERROR_NAME = Regex("^ERR_[A-Z0-9_]+$")

/**
 * Arguments for a failure event. The SDK reports a failure as a string, and for some failures that
 * string is its own error name (an `ERR_*` string resource whose value is the name). When it is, the
 * name is also sent as `errorCode`, so Dart can type it; any other message is sent as it always was.
 */
internal fun failureArguments(message: String): Map<String, Any?> =
    if (SDK_ERROR_NAME.matches(message)) mapOf("error" to message, "errorCode" to message)
    else mapOf("error" to message)
