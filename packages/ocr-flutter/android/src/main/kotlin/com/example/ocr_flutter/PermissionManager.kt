package com.example.ocr_flutter

import android.app.Activity
import android.content.pm.PackageManager
import android.Manifest
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Handles all permission-related functionality for the OCR Flutter plugin
 */
class PermissionManager {
    companion object {
        private const val REQUEST_CAMERA_PERMISSION = 1001
    }

    /**
     * Check if required permissions are granted
     */
    fun checkPermissions(activity: Activity?, result: Result) {
        if (activity != null) {
            val hasCameraPermission = ContextCompat.checkSelfPermission(activity, 
                Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
            val hasPhoneStatePermission = ContextCompat.checkSelfPermission(activity, 
                Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED

            val permissions = mapOf(
                "hasCameraPermission" to hasCameraPermission,
                "hasPhoneStatePermission" to hasPhoneStatePermission
            )
            result.success(permissions)
        } else {
            result.error("NO_ACTIVITY", "Activity not available", null)
        }
    }

    /**
     * Request required permissions from the user
     */
    fun requestPermissions(activity: Activity?, result: Result) {
        if (activity != null) {
            val permissions = mutableListOf<String>()
            
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) 
                != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.CAMERA)
            }
            
            if (ContextCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) 
                != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.READ_PHONE_STATE)
            }

            if (permissions.isNotEmpty()) {
                ActivityCompat.requestPermissions(activity, permissions.toTypedArray(), 
                    REQUEST_CAMERA_PERMISSION)
            }
            result.success(true)
        } else {
            result.error("NO_ACTIVITY", "Activity not available", null)
        }
    }
}
