package com.ocrflutter

import android.util.Log
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.PlaceholderTemplate
import io.flutter.plugin.common.MethodChannel.Result
import kotlin.math.roundToInt

/**
 * Keeps the app's OCR UI configuration and hands it to the SDK's credentials builder.
 */
class UIConfigurationManager {
    companion object {
        private const val TAG = "UIConfigurationManager"

        // The documented default of successDelay; the builder itself leaves it at 0.
        private const val DEFAULT_SUCCESS_DELAY = 0.2f

        /**
         * The SDK takes the crop around the document as a whole percentage (the builder clamps it to 0-100 and
         * defaults to 100); the Dart API takes the 0.0-1.0 ratio iOS uses (iOS defaults to 0.35). Rounded, not
         * truncated: 0.29 * 100 is 28.999999999999996.
         */
        fun cropRatioToPercent(ratio: Double): Int? = if (ratio.isNaN()) null else (ratio * 100).roundToInt()
    }

    private var storedUIConfig: Map<String, Any>? = null

    /**
     * Set OCR UI configuration from Flutter
     */
    fun setOCRUIConfig(config: Map<String, Any>?, result: Result) {
        try {
            if (config != null) {
                storedUIConfig = config
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error configuring UI settings: ${e.message}", e)
            result.error("SET_OCR_UI_CONFIG_ERROR", "Failed to set OCR UI config: ${e.message}", null)
        }
    }

    /**
     * Passes on what the app set. Anything it left out keeps the SDK's own default (hardwareSupport 10,
     * the country-specific placeholder, ...), which is also what iOS does with the same configuration.
     */
    fun applyUIConfigToBuilder(builder: CardRecognizerCredentials.Builder) {
        val config = storedUIConfig

        val successDelay = config.float("successDelay") ?: DEFAULT_SUCCESS_DELAY
        builder.successDelay(successDelay)
        if (config == null) return

        // `detectionAccuracy` is the cross-platform name; `hardwareSupport` is the older Android one.
        (config.int("detectionAccuracy") ?: config.int("hardwareSupport"))?.let { builder.hardwareSupport(it) }
        config.float("blurCoefficient")?.let { builder.blurCoefficient(it) }
        config.bool("manualCapture")?.let { builder.manualCapture(it) }
        config.bool("faceDetection")?.let { builder.faceDetection(it) }
        (config.bool("isDocumentLivenessActive") ?: config.bool("documentLivenessEnabled"))
            ?.let { builder.isDocumentLivenessActive(it) }
        config.bool("reviewScreenEnabled")?.let { builder.reviewScreenEnabled(it) }
        config.bool("footerViewHidden")?.let { builder.footerViewHidden(it) }
        (config.bool("iqaEnabled") ?: config.bool("isIQAServiceEnabled"))?.let { builder.iqaEnabled(it) }
        config.int("iqaSuccessAutoDismissDelay")?.let { builder.iqaSuccessAutoDismissDelay(it) }
        config.int("requestTimeout")?.let { builder.requestTimeout(it) }
        // The call's own rawPhotoCropRatio (OCRCameraParams) is applied after this and wins, as on iOS.
        config.double("rawPhotoCropRatio")?.let { ratio -> cropRatioToPercent(ratio)?.let { builder.rawPhotoCropRatio(it) } }

        (config["placeholderTemplate"] as? String)?.let { name ->
            builder.placeholderTemplate(
                when (name.lowercase()) {
                    "hidden" -> PlaceholderTemplate.hidden
                    "countryspecificstyle", "countryspecific" -> PlaceholderTemplate.countrySpecificStyle
                    else -> PlaceholderTemplate.defaultStyle
                }
            )
        }
    }

    /** Whether the app's configuration turns the SDK's document-liveness check on (either key name). */
    fun documentLivenessConfigured(): Boolean =
        storedUIConfig.let { it.bool("isDocumentLivenessActive") ?: it.bool("documentLivenessEnabled") } == true

    private fun Map<String, Any>?.int(key: String): Int? = (this?.get(key) as? Number)?.toInt()
    private fun Map<String, Any>?.float(key: String): Float? = (this?.get(key) as? Number)?.toFloat()
    private fun Map<String, Any>?.double(key: String): Double? = (this?.get(key) as? Number)?.toDouble()
    private fun Map<String, Any>?.bool(key: String): Boolean? = this?.get(key) as? Boolean

    /**
     * Check if UI configuration is available
     */
    fun hasUIConfig(): Boolean = storedUIConfig != null

    /**
     * Get the stored UI configuration
     */
    fun getStoredUIConfig(): Map<String, Any>? = storedUIConfig
}
