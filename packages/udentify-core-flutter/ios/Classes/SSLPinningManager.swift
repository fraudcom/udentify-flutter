import Foundation
import UdentifyCommons

/**
 * SSLPinningManager
 * Manages SSL certificate pinning using UdentifySettingsProvider
 */
@objc(SSLPinningManager)
public class SSLPinningManager: NSObject {
    
    /**
     * Load a certificate from the app bundle and set it for SSL pinning
     */
    @objc public func loadCertificateFromAssets(
        _ certificateName: String,
        extension fileExtension: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        NSLog("SSLPinningManager - Loading certificate: \(certificateName).\(fileExtension)")
        
        // Load certificate data from bundle using UdentifySettingsProvider
        guard let certificateData = UdentifySettingsProvider.loadDERCertificateData(
            from: Bundle.main,
            certificateName: certificateName,
            certificateExtension: fileExtension
        ) else {
            let error = NSError(
                domain: "com.udentify.sslpinning",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to load certificate '\(certificateName).\(fileExtension)' from bundle. Ensure the certificate file exists in the app bundle and is in DER format."]
            )
            NSLog("SSLPinningManager - Error: \(error.localizedDescription)")
            completion(false, error)
            return
        }
        
        NSLog("SSLPinningManager - Certificate data loaded, size: \(certificateData.count) bytes")
        
        // Set the certificate using UdentifySettingsProvider
        UdentifySettingsProvider.setSSLCertificate(with: certificateData)
        
        NSLog("SSLPinningManager - Certificate set successfully")
        completion(true, nil)
    }
    
    /**
     * Set SSL certificate using base64 encoded data
     */
    @objc public func setSSLCertificateBase64(
        _ certificateBase64: String,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        NSLog("SSLPinningManager - Setting certificate from base64 data")
        
        // Decode base64 string to Data
        guard let certificateData = Data(base64Encoded: certificateBase64) else {
            let error = NSError(
                domain: "com.udentify.sslpinning",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid base64 encoded certificate data"]
            )
            NSLog("SSLPinningManager - Error: \(error.localizedDescription)")
            completion(false, error)
            return
        }
        
        NSLog("SSLPinningManager - Certificate data decoded, size: \(certificateData.count) bytes")
        
        // Set the certificate using UdentifySettingsProvider
        UdentifySettingsProvider.setSSLCertificate(with: certificateData)
        
        NSLog("SSLPinningManager - Certificate set successfully")
        completion(true, nil)
    }
    
    /**
     * Remove the currently set SSL certificate
     */
    @objc public func removeSSLCertificate(
        _ completion: @escaping (Bool, Error?) -> Void
    ) {
        NSLog("SSLPinningManager - Removing SSL certificate")
        
        // Remove certificate using UdentifySettingsProvider
        UdentifySettingsProvider.removeSSLCertificate()
        
        NSLog("SSLPinningManager - Certificate removed successfully")
        completion(true, nil)
    }
    
    /**
     * Get the currently set SSL certificate as base64 string
     */
    @objc public func getSSLCertificateBase64(
        _ completion: @escaping (String?, Error?) -> Void
    ) {
        NSLog("SSLPinningManager - Getting SSL certificate")
        
        // Get certificate data using UdentifySettingsProvider
        guard let certificateData = UdentifySettingsProvider.getSSLCertificate() else {
            NSLog("SSLPinningManager - No certificate is currently set")
            completion(nil, nil)
            return
        }
        
        // Convert to base64 string
        let base64String = certificateData.base64EncodedString()
        NSLog("SSLPinningManager - Certificate retrieved, size: \(certificateData.count) bytes")
        
        completion(base64String, nil)
    }
    
    /**
     * Check if SSL pinning is enabled
     */
    @objc public func isSSLPinningEnabled(
        _ completion: @escaping (Bool, Error?) -> Void
    ) {
        NSLog("SSLPinningManager - Checking SSL pinning status")
        
        // Check status using UdentifySettingsProvider
        let isEnabled = UdentifySettingsProvider.isSSLPinningEnabled
        
        NSLog("SSLPinningManager - SSL pinning enabled: \(isEnabled)")
        completion(isEnabled, nil)
    }
}

