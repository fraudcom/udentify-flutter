package com.example.ocr_flutter

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import android.util.Log
import io.udentify.android.ocr.CardRecognizerCredentials
import io.udentify.android.ocr.activities.PlaceholderTemplate
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

/**
 * Handles UI configuration and color overrides for the OCR Flutter plugin
 */
class UIConfigurationManager(private val simpleResourceManager: SimpleResourceManager) {
    companion object {
        private const val TAG = "UIConfigurationManager"
    }
    
    // Storage for UI configuration
    private var storedUIConfig: Map<String, Any>? = null
    
    /**
     * Set OCR UI configuration from Flutter
     */
    fun setOCRUIConfig(config: Map<String, Any>?, result: Result) {
        try {
            Log.d(TAG, "🎨 UIConfigurationManager - setOCRUIConfig called")
            Log.d(TAG, "🎨 UIConfigurationManager - Received config keys: ${config?.keys}")
            
            if (config != null) {
                // Store the configuration for use when creating CardRecognizerCredentials
                storedUIConfig = config
                
                // Apply Android-specific UI configurations if possible
                applyAndroidUIConfiguration(config)
                
                Log.d(TAG, "🎨 UIConfigurationManager - ✅ Final UI Configuration stored: $config")
                Log.d(TAG, "🎨 UIConfigurationManager - ✅ UI Configuration size: ${config.size} parameters")
            }
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "🎨 UIConfigurationManager - ❌ Error configuring UI settings: ${e.message}", e)
            result.error("SET_OCR_UI_CONFIG_ERROR", "Failed to set OCR UI config: ${e.message}", null)
        }
    }
    
    /**
     * Apply stored UI configuration to CardRecognizerCredentials builder
     */
    fun applyUIConfigToBuilder(builder: CardRecognizerCredentials.Builder) {
        storedUIConfig?.let { config ->
            Log.d(TAG, "🔧 UIConfigurationManager - Applying UI configuration with ${config.size} parameters")
            
            // Detection and behavior settings
            config["detectionAccuracy"]?.let { 
                val value = (it as? Number)?.toInt() ?: 7
                builder.hardwareSupport(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied detectionAccuracy (hardwareSupport): $value")
            } ?: run {
                config["hardwareSupport"]?.let {
                    val value = (it as? Number)?.toInt() ?: 7
                    builder.hardwareSupport(value)
                    Log.d(TAG, "🔧 UIConfigurationManager - Applied hardwareSupport: $value")
                } ?: run {
                    builder.hardwareSupport(7)
                    Log.d(TAG, "🔧 UIConfigurationManager - Using default hardwareSupport: 7")
                }
            }
            
            config["blurCoefficient"]?.let { 
                val value = (it as? Number)?.toFloat() ?: 0.0f
                builder.blurCoefficient(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied blurCoefficient: $value")
            } ?: run {
                builder.blurCoefficient(0.0f)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default blurCoefficient: 0.0")
            }
            
            config["manualCapture"]?.let {
                val value = it as? Boolean ?: false
                builder.manualCapture(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied manualCapture: $value")
            } ?: run {
                builder.manualCapture(false)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default manualCapture: false")
            }
            
            config["faceDetection"]?.let {
                val value = it as? Boolean ?: false
                builder.faceDetection(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied faceDetection: $value")
            } ?: run {
                builder.faceDetection(false)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default faceDetection: false")
            }
            
            config["isDocumentLivenessActive"]?.let {
                val value = it as? Boolean ?: false
                builder.isDocumentLivenessActive(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied isDocumentLivenessActive: $value")
            } ?: run {
                config["documentLivenessEnabled"]?.let {
                    val value = it as? Boolean ?: false
                    builder.isDocumentLivenessActive(value)
                    Log.d(TAG, "🔧 UIConfigurationManager - Applied documentLivenessEnabled (as isDocumentLivenessActive): $value")
                } ?: run {
                    builder.isDocumentLivenessActive(false)
                    Log.d(TAG, "🔧 UIConfigurationManager - Using default isDocumentLivenessActive: false")
                }
            }
            
            config["reviewScreenEnabled"]?.let {
                val value = it as? Boolean ?: true
                builder.reviewScreenEnabled(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied reviewScreenEnabled: $value")
            } ?: run {
                builder.reviewScreenEnabled(true)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default reviewScreenEnabled: true")
            }
            
            config["footerViewHidden"]?.let {
                val value = it as? Boolean ?: false
                builder.footerViewHidden(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied footerViewHidden: $value")
            } ?: run {
                builder.footerViewHidden(false)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default footerViewHidden: false")
            }
            
            // Placeholder template setting
            config["placeholderTemplate"]?.let { templateString ->
                val template = when ((templateString as? String)?.lowercase()) {
                    "hidden" -> PlaceholderTemplate.hidden
                    "defaultstyle", "default" -> PlaceholderTemplate.defaultStyle
                    "countryspecificstyle", "countryspecific" -> PlaceholderTemplate.countrySpecificStyle
                    else -> PlaceholderTemplate.defaultStyle
                }
                builder.placeholderTemplate(template)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied placeholderTemplate: $templateString -> $template")
            } ?: run {
                builder.placeholderTemplate(PlaceholderTemplate.defaultStyle)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default placeholderTemplate: defaultStyle")
            }
            
            // Check for both iqaEnabled and isIQAServiceEnabled
            val iqaEnabledValue = config["iqaEnabled"] as? Boolean 
                ?: config["isIQAServiceEnabled"] as? Boolean 
                ?: true
            builder.iqaEnabled(iqaEnabledValue)
            Log.d(TAG, "🔧 UIConfigurationManager - Applied iqaEnabled: $iqaEnabledValue (from ${if (config.containsKey("iqaEnabled")) "iqaEnabled" else if (config.containsKey("isIQAServiceEnabled")) "isIQAServiceEnabled" else "default"})")
            
            config["iqaSuccessAutoDismissDelay"]?.let {
                val value = (it as? Number)?.toInt() ?: -1
                builder.iqaSuccessAutoDismissDelay(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied iqaSuccessAutoDismissDelay: $value")
            } ?: run {
                builder.iqaSuccessAutoDismissDelay(-1)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default iqaSuccessAutoDismissDelay: -1")
            }
            
            config["requestTimeout"]?.let {
                val value = (it as? Number)?.toInt() ?: 30
                builder.requestTimeout(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied requestTimeout: $value")
            } ?: run {
                builder.requestTimeout(30)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default requestTimeout: 30")
            }
            
            // Success delay
            config["successDelay"]?.let {
                val value = (it as? Number)?.toFloat() ?: 0.2f
                builder.successDelay(value)
                Log.d(TAG, "🔧 UIConfigurationManager - Applied successDelay: $value")
            } ?: run {
                builder.successDelay(0.2f)
                Log.d(TAG, "🔧 UIConfigurationManager - Using default successDelay: 0.2f")
            }
            
        } ?: run {
            Log.d(TAG, "🔧 UIConfigurationManager - No UI configuration provided, using all defaults")
            // Apply default values when no UI configuration is provided
            builder.successDelay(0.2f)
                .hardwareSupport(7)
                .faceDetection(false)
                .blurCoefficient(0.0f)
                .manualCapture(false)
                .isDocumentLivenessActive(false)
                .reviewScreenEnabled(true)
                .footerViewHidden(false)
                .placeholderTemplate(PlaceholderTemplate.defaultStyle)
                .iqaEnabled(true)
                .iqaSuccessAutoDismissDelay(-1)
                .requestTimeout(30)
        }
    }
    
    /**
     * Apply Android-specific UI configuration
     */
    private fun applyAndroidUIConfiguration(config: Map<String, Any>) {
        try {
            Log.d(TAG, "🎨 UIConfigurationManager - Applying Android-specific UI configuration")
            
            // Note: Android UI customization is primarily handled through:
            // 1. CardRecognizerCredentials parameters (behavior settings) - handled in applyUIConfigToBuilder
            // 2. Static resource overrides (colors, strings, styles) - requires app-level resources
            // 3. Fragment parameters (orientation) - handled in CardFragment.newInstance
            
            // For colors and visual styling, Android requires resource overrides
            // which can't be applied dynamically. These would need to be set in the app's
            // res/values/colors.xml, res/values/strings.xml, etc.
            
            config["backgroundColor"]?.let { color ->
                Log.d(TAG, "🎨 UIConfigurationManager - Note: backgroundColor '$color' requires app-level resource override")
                Log.d(TAG, "🎨 UIConfigurationManager - Add <color name=\"udentify_ocr_card_mask_view_background_color\">$color</color> to your app's colors.xml")
            }
            
            config["borderColor"]?.let { color ->
                Log.d(TAG, "🎨 UIConfigurationManager - Note: borderColor '$color' requires app-level resource override")
                Log.d(TAG, "🎨 UIConfigurationManager - Add <color name=\"udentify_ocr_card_mask_view_stroke_color\">$color</color> to your app's colors.xml")
            }
            
            config["cornerRadius"]?.let { radius ->
                Log.d(TAG, "🎨 UIConfigurationManager - Note: cornerRadius '$radius' requires app-level resource override")
                Log.d(TAG, "🎨 UIConfigurationManager - Add <dimen name=\"udentify_ocr_footer_btn_border_corner_radius\">${radius}dp</dimen> to your app's dimens.xml")
            }
            
            config["cardMaskViewBackgroundColor"]?.let { color ->
                Log.d(TAG, "🎨 UIConfigurationManager - Note: cardMaskViewBackgroundColor '$color' requires app-level resource override")
                Log.d(TAG, "🎨 UIConfigurationManager - Add <color name=\"udentify_ocr_card_mask_view_background_color\">$color</color> to your app's colors.xml")
            }
            
            Log.d(TAG, "🎨 UIConfigurationManager - ✅ Android UI configuration guidance provided in logs")
            
        } catch (e: Exception) {
            Log.e(TAG, "🎨 UIConfigurationManager - Error applying Android UI configuration: ${e.message}", e)
        }
    }
    
    /**
     * Check if UI configuration is available
     */
    fun hasUIConfig(): Boolean = storedUIConfig != null
    
    /**
     * Get the stored UI configuration
     */
    fun getStoredUIConfig(): Map<String, Any>? = storedUIConfig
}
