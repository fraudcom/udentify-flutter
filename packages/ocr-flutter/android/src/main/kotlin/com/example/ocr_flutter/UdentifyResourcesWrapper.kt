package com.example.ocr_flutter

import android.content.res.Resources
import android.util.Log

/**
 * Custom Resources wrapper that intercepts resource loading to apply color overrides
 * This wrapper allows us to override specific color resources that the SDK uses
 */
class UdentifyResourcesWrapper(
    private val baseResources: Resources,
    private val colorOverrides: Map<String, Int>
) : Resources(baseResources.assets, baseResources.displayMetrics, baseResources.configuration) {
    
    companion object {
        private const val TAG = "UdentifyResourcesWrapper"
    }
    
    init {
        Log.w(TAG, "🎯 UdentifyResourcesWrapper INITIALIZED with ${colorOverrides.size} color overrides")
        Log.w(TAG, "🎯 This wrapper will intercept ALL resource requests!")
        colorOverrides.forEach { (name, color) ->
            Log.d(TAG, "  - Override: $name = ${String.format("#%08X", color)}")
        }
    }
    
    override fun getColor(id: Int): Int {
        return getColor(id, null)
    }
    
    override fun getColor(id: Int, theme: Theme?): Int {
        Log.v(TAG, "📋 getColor() called - ID=$id")
        
        // Check if we have a global override for this resource ID
        SimpleResourceManager.getColorOverrideById(id)?.let { overrideColor ->
            Log.d(TAG, "🎨 Applying color override for resource ID $id: ${String.format("#%08X", overrideColor)}")
            return overrideColor
        }
        
        // Check by resource name if we can determine it
        try {
            val resourceName = baseResources.getResourceEntryName(id)
            
            // Log ALL resource requests for debugging
            Log.v(TAG, "🔍 Resource request: ID=$id, name=$resourceName")
            
            SimpleResourceManager.getColorOverride(resourceName)?.let { overrideColor ->
                Log.d(TAG, "🎨 Applying color override for resource name $resourceName: ${String.format("#%08X", overrideColor)}")
                return overrideColor
            }
            
            // Special handling for critical CardMaskView colors
            if (resourceName.contains("card_mask_view") || resourceName.contains("mask_layer")) {
                Log.w(TAG, "🚨 CRITICAL: CardMaskView color $resourceName requested but no override found!")
            }
            
        } catch (e: Exception) {
            // Resource name not found, log for debugging
            Log.v(TAG, "🔍 Resource request: ID=$id, name=UNKNOWN")
        }
        
        // Return the original color if no override exists
        val originalColor = super.getColor(id, theme)
        
        // CRITICAL: Aggressively detect and override the purple CardMaskView color
        if (originalColor == 0xFF844EE3.toInt() || // Standard purple
            originalColor == -8036893 || // Alternative purple representation
            originalColor and 0xFFFFFF == 0x844EE3) { // Ignore alpha channel
            
            Log.w(TAG, "🚨 DETECTED: Default purple color ${String.format("#%08X", originalColor)} for resource ID $id - FORCING CardMaskView override!")
            
            // Try multiple override sources
            val cardMaskColor = SimpleResourceManager.getColorOverride("udentify_ocr_card_mask_view_background_color") 
                ?: SimpleResourceManager.getColorOverride("cardMaskViewBackgroundColor")
                ?: SimpleResourceManager.getCardMaskColors()["cardMaskViewBackgroundColor"]?.let { 
                    try { android.graphics.Color.parseColor(it) } catch (e: Exception) { null }
                }
            
            cardMaskColor?.let { override ->
                Log.w(TAG, "✅ FORCED CardMaskView color override: ${String.format("#%08X", override)} (was ${String.format("#%08X", originalColor)})")
                return override
            }
            
            Log.e(TAG, "❌ Failed to find CardMaskView override color!")
        }
        
        return originalColor
    }
    
    override fun getColorStateList(id: Int): android.content.res.ColorStateList {
        return getColorStateList(id, null)
    }
    
    override fun getColorStateList(id: Int, theme: Theme?): android.content.res.ColorStateList {
        // Check if we have a color override that we should convert to a ColorStateList
        SimpleResourceManager.getColorOverrideById(id)?.let { overrideColor ->
            Log.d(TAG, "🎨 Creating ColorStateList override for resource ID $id: ${String.format("#%08X", overrideColor)}")
            return android.content.res.ColorStateList.valueOf(overrideColor)
        }
        
        // Check by resource name
        try {
            val resourceName = baseResources.getResourceEntryName(id)
            SimpleResourceManager.getColorOverride(resourceName)?.let { overrideColor ->
                Log.d(TAG, "🎨 Creating ColorStateList override for resource name $resourceName: ${String.format("#%08X", overrideColor)}")
                return android.content.res.ColorStateList.valueOf(overrideColor)
            }
        } catch (e: Exception) {
            // Resource name not found, continue with normal lookup
        }
        
        // Return the original ColorStateList if no override exists
        val originalColorStateList = super.getColorStateList(id, theme) ?: android.content.res.ColorStateList.valueOf(0)
        
        // CRITICAL: Check if the ColorStateList contains the purple color and override it
        val defaultColor = originalColorStateList.defaultColor
        if (defaultColor == 0xFF844EE3.toInt() || // Standard purple
            defaultColor == -8036893 || // Alternative purple representation  
            defaultColor and 0xFFFFFF == 0x844EE3) { // Ignore alpha channel
            
            Log.w(TAG, "🚨 DETECTED: ColorStateList with purple default ${String.format("#%08X", defaultColor)} for resource ID $id - FORCING override!")
            
            // Try multiple override sources
            val cardMaskColor = SimpleResourceManager.getColorOverride("udentify_ocr_card_mask_view_background_color") 
                ?: SimpleResourceManager.getColorOverride("cardMaskViewBackgroundColor")
                ?: SimpleResourceManager.getCardMaskColors()["cardMaskViewBackgroundColor"]?.let { 
                    try { android.graphics.Color.parseColor(it) } catch (e: Exception) { null }
                }
            
            cardMaskColor?.let { override ->
                Log.w(TAG, "✅ FORCED ColorStateList override: ${String.format("#%08X", override)} (was ${String.format("#%08X", defaultColor)})")
                return android.content.res.ColorStateList.valueOf(override)
            }
        }
        
        return originalColorStateList
    }
    
    // Override other resource methods as needed
    override fun getString(id: Int): String {
        return super.getString(id)
    }
    
    override fun getDrawable(id: Int): android.graphics.drawable.Drawable? {
        return getDrawable(id, null)
    }
    
    override fun getDrawable(id: Int, theme: Theme?): android.graphics.drawable.Drawable? {
        Log.v(TAG, "📋 getDrawable() called - ID=$id")
        
        try {
            val resourceName = baseResources.getResourceEntryName(id)
            Log.v(TAG, "🖼️ Drawable request: ID=$id, name=$resourceName")
            
            // Check if this is a card-related drawable
            if (resourceName.contains("card", true) || 
                resourceName.contains("mask", true) ||
                resourceName.contains("udentify", true)) {
                Log.w(TAG, "🎯 CARD-RELATED DRAWABLE: $resourceName (ID=$id)")
            }
        } catch (e: Exception) {
            Log.v(TAG, "🖼️ Drawable request: ID=$id, name=UNKNOWN")
        }
        
        val drawable = super.getDrawable(id, theme)
        
        // CRITICAL: Check if this drawable contains purple colors and override them
        drawable?.let { d ->
            if (d is android.graphics.drawable.GradientDrawable) {
                Log.w(TAG, "🟣 Found GradientDrawable - checking for purple colors...")
                
                // Try to modify the gradient drawable if it contains purple
                try {
                    // Check if this drawable might be the CardMaskView background
                    val cardMaskColor = SimpleResourceManager.getColorOverride("udentify_ocr_card_mask_view_background_color")
                    cardMaskColor?.let { overrideColor ->
                        Log.w(TAG, "🚨 FORCING GradientDrawable color override: ${String.format("#%08X", overrideColor)}")
                        d.setColor(overrideColor)
                        return d
                    }
                } catch (e: Exception) {
                    Log.w(TAG, "Could not modify GradientDrawable: ${e.message}")
                }
            }
            
            if (d is android.graphics.drawable.ColorDrawable) {
                val color = d.color
                if (color == 0xFF844EE3.toInt() || 
                    color == -8036893 || 
                    (color and 0xFFFFFF) == 0x844EE3) {
                    
                    Log.w(TAG, "🚨 DETECTED: Purple ColorDrawable ${String.format("#%08X", color)} - FORCING override!")
                    
                    val cardMaskColor = SimpleResourceManager.getColorOverride("udentify_ocr_card_mask_view_background_color")
                    cardMaskColor?.let { overrideColor ->
                        Log.w(TAG, "✅ FORCED ColorDrawable override: ${String.format("#%08X", overrideColor)}")
                        return android.graphics.drawable.ColorDrawable(overrideColor)
                    }
                }
            }
        }
        
        return drawable
    }
    
    // Delegate all other methods to the base resources
    override fun getDimension(id: Int): Float = super.getDimension(id)
    override fun getDimensionPixelSize(id: Int): Int = super.getDimensionPixelSize(id)
    override fun getDimensionPixelOffset(id: Int): Int = super.getDimensionPixelOffset(id)
    override fun getBoolean(id: Int): Boolean = super.getBoolean(id)
    override fun getInteger(id: Int): Int = super.getInteger(id)
    override fun getText(id: Int): CharSequence = super.getText(id)
    override fun getStringArray(id: Int): Array<String> = super.getStringArray(id)
    override fun getIntArray(id: Int): IntArray = super.getIntArray(id)
}
