package com.ocrflutter

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat

/**
 * The OCR plugin does not ask for permissions (the app does, at the point of use); it only checks
 * them before it opens the SDK's camera, so a missing one comes back as an error code.
 */
object PermissionManager {
    /**
     * The Udentify OCR SDK needs CAMERA and READ_PHONE_STATE at runtime. Returns an error
     * code and message for the first one the host app has not been granted, or null when both are.
     */
    fun missingPermission(activity: Activity): Pair<String, String>? {
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA)
            != PackageManager.PERMISSION_GRANTED) {
            return "ERR_CAMERA_PERMISSION_REQUIRED" to "Camera permission is required"
        }
        if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED) {
            return "ERR_PHONE_STATE_PERMISSION_REQUIRED" to
                "Phone state permission (READ_PHONE_STATE) is required by the Udentify SDK"
        }
        return null
    }
}
