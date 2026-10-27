package com.udentifycoreflutter

import android.content.Context
import android.util.Base64
import android.util.Log
import io.udentify.android.commons.model.UdentifySettingsProvider
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

/**
 * SSLPinningManager
 * Manages SSL certificate pinning using UdentifySettingsProvider
 */
class SSLPinningManager(private val context: Context) {
    
    companion object {
        private const val TAG = "SSLPinningManager"
    }
    
    /**
     * Load a certificate from the Android assets folder and set it for SSL pinning
     */
    fun loadCertificateFromAssets(
        certificateName: String,
        extension: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "loadCertificateFromAssets called: $certificateName.$extension")
            
            // Use UdentifySettingsProvider to load the certificate
            val certificate = UdentifySettingsProvider.loadDERCertificateData(
                context,
                certificateName,
                extension
            )
            
            if (certificate == null) {
                val errorMessage = "Failed to load certificate '$certificateName.$extension' from assets. Ensure the certificate file exists in the assets folder and is in DER format."
                Log.e(TAG, "Error: $errorMessage")
                onError(errorMessage)
                return
            }
            
            Log.d(TAG, "Certificate loaded, subject: ${certificate.subjectDN}")
            
            // Set the certificate using UdentifySettingsProvider
            UdentifySettingsProvider.setSSLCertificate(certificate)
            
            Log.d(TAG, "Certificate set successfully")
            onSuccess()
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error occurred")
        }
    }
    
    /**
     * Set SSL certificate using base64 encoded data
     */
    fun setSSLCertificateBase64(
        certificateBase64: String,
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "setSSLCertificateBase64 called")
            
            // Decode base64 string
            val certificateBytes = Base64.decode(certificateBase64, Base64.DEFAULT)
            
            Log.d(TAG, "Certificate data decoded, size: ${certificateBytes.size} bytes")
            
            // Convert bytes to X509Certificate
            val certificateFactory = CertificateFactory.getInstance("X.509")
            val certificate = certificateFactory.generateCertificate(
                certificateBytes.inputStream()
            ) as X509Certificate
            
            Log.d(TAG, "Certificate parsed, subject: ${certificate.subjectDN}")
            
            // Set the certificate using UdentifySettingsProvider
            UdentifySettingsProvider.setSSLCertificate(certificate)
            
            Log.d(TAG, "Certificate set successfully")
            onSuccess()
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error occurred")
        }
    }
    
    /**
     * Remove the currently set SSL certificate
     */
    fun removeSSLCertificate(
        onSuccess: () -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "removeSSLCertificate called")
            
            // Remove certificate using UdentifySettingsProvider
            UdentifySettingsProvider.removeSSLCertificate()
            
            Log.d(TAG, "Certificate removed successfully")
            onSuccess()
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error occurred")
        }
    }
    
    /**
     * Get the currently set SSL certificate as base64 string
     */
    fun getSSLCertificateBase64(
        onSuccess: (String?) -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "getSSLCertificateBase64 called")
            
            // Get certificate using UdentifySettingsProvider
            val certificate = UdentifySettingsProvider.getSSLCertificate()
            
            if (certificate == null) {
                Log.d(TAG, "No certificate is currently set")
                onSuccess(null)
                return
            }
            
            // Convert certificate to base64
            val certificateBytes = certificate.encoded
            val base64String = Base64.encodeToString(certificateBytes, Base64.NO_WRAP)
            
            Log.d(TAG, "Certificate retrieved, size: ${certificateBytes.size} bytes")
            onSuccess(base64String)
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error occurred")
        }
    }
    
    /**
     * Check if SSL pinning is enabled
     */
    fun isSSLPinningEnabled(
        onSuccess: (Boolean) -> Unit,
        onError: (String) -> Unit
    ) {
        try {
            Log.d(TAG, "isSSLPinningEnabled called")
            
            // Check SSL pinning status using UdentifySettingsProvider
            val isEnabled = UdentifySettingsProvider.isSSLPinningEnabled()
            
            Log.d(TAG, "SSL pinning enabled: $isEnabled")
            onSuccess(isEnabled)
            
        } catch (e: Exception) {
            Log.e(TAG, "Exception: ${e.message}", e)
            onError(e.message ?: "Unknown error occurred")
        }
    }
}

