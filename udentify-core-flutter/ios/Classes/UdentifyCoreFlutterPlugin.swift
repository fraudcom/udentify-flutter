import Flutter
import UIKit
import UdentifyCommons

/**
 * UdentifyCoreFlutterPlugin
 * Flutter plugin for SSL certificate pinning using UdentifySettingsProvider
 */
public class UdentifyCoreFlutterPlugin: NSObject, FlutterPlugin {
    private static var sharedSSLPinningManager: SSLPinningManager?
    private static var sharedLocalizationManager: LocalizationManager?
    
    private static func getSharedSSLPinningManager() -> SSLPinningManager {
        if sharedSSLPinningManager == nil {
            sharedSSLPinningManager = SSLPinningManager()
        }
        return sharedSSLPinningManager!
    }
    
    private static func getSharedLocalizationManager() -> LocalizationManager {
        if sharedLocalizationManager == nil {
            sharedLocalizationManager = LocalizationManager()
        }
        return sharedLocalizationManager!
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "udentify_core_flutter", binaryMessenger: registrar.messenger())
        let instance = UdentifyCoreFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "loadCertificateFromAssets":
            loadCertificateFromAssets(call: call, result: result)
        case "setSSLCertificateBase64":
            setSSLCertificateBase64(call: call, result: result)
        case "removeSSLCertificate":
            removeSSLCertificate(result: result)
        case "getSSLCertificateBase64":
            getSSLCertificateBase64(result: result)
        case "isSSLPinningEnabled":
            isSSLPinningEnabled(result: result)
        case "instantiateServerBasedLocalization":
            instantiateServerBasedLocalization(call: call, result: result)
        case "getLocalizationMap":
            getLocalizationMap(result: result)
        case "clearLocalizationCache":
            clearLocalizationCache(call: call, result: result)
        case "mapSystemLanguageToEnum":
            mapSystemLanguageToEnum(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /**
     * Load a certificate from the app bundle and set it for SSL pinning
     */
    private func loadCertificateFromAssets(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let certificateName = args["certificateName"] as? String,
              let fileExtension = args["extension"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Certificate name and extension are required",
                details: nil
            ))
            return
        }
        
        NSLog("UdentifyCoreFlutterPlugin - loadCertificateFromAssets called: \(certificateName).\(fileExtension)")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedSSLPinningManager()
        
        manager.loadCertificateFromAssets(
            certificateName,
            extension: fileExtension
        ) { success, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error loading certificate: \(error.localizedDescription)")
                result(FlutterError(
                    code: "LOAD_CERT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Certificate loaded and set successfully")
                result(success)
            }
        }
    }
    
    /**
     * Set SSL certificate using base64 encoded data
     */
    private func setSSLCertificateBase64(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let certificateBase64 = args["certificateBase64"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Certificate base64 data is required",
                details: nil
            ))
            return
        }
        
        NSLog("UdentifyCoreFlutterPlugin - setSSLCertificateBase64 called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedSSLPinningManager()
        
        manager.setSSLCertificateBase64(certificateBase64) { success, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error setting certificate: \(error.localizedDescription)")
                result(FlutterError(
                    code: "SET_CERT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Certificate set successfully")
                result(success)
            }
        }
    }
    
    /**
     * Remove the currently set SSL certificate
     */
    private func removeSSLCertificate(result: @escaping FlutterResult) {
        NSLog("UdentifyCoreFlutterPlugin - removeSSLCertificate called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedSSLPinningManager()
        
        manager.removeSSLCertificate { success, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error removing certificate: \(error.localizedDescription)")
                result(FlutterError(
                    code: "REMOVE_CERT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Certificate removed successfully")
                result(success)
            }
        }
    }
    
    /**
     * Get the currently set SSL certificate as base64 string
     */
    private func getSSLCertificateBase64(result: @escaping FlutterResult) {
        NSLog("UdentifyCoreFlutterPlugin - getSSLCertificateBase64 called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedSSLPinningManager()
        
        manager.getSSLCertificateBase64 { certificateBase64, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error getting certificate: \(error.localizedDescription)")
                result(FlutterError(
                    code: "GET_CERT_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Certificate retrieved successfully")
                result(certificateBase64)
            }
        }
    }
    
    /**
     * Check if SSL pinning is enabled
     */
    private func isSSLPinningEnabled(result: @escaping FlutterResult) {
        NSLog("UdentifyCoreFlutterPlugin - isSSLPinningEnabled called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedSSLPinningManager()
        
        manager.isSSLPinningEnabled { enabled, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error checking SSL pinning status: \(error.localizedDescription)")
                result(FlutterError(
                    code: "CHECK_STATUS_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - SSL pinning enabled: \(enabled)")
                result(enabled)
            }
        }
    }
    
    /**
     * Instantiate server-based localization
     */
    private func instantiateServerBasedLocalization(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let language = args["language"] as? String,
              let serverUrl = args["serverUrl"] as? String,
              let transactionId = args["transactionId"] as? String,
              let requestTimeout = args["requestTimeout"] as? Double else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Language, serverUrl, transactionId, and requestTimeout are required",
                details: nil
            ))
            return
        }
        
        NSLog("UdentifyCoreFlutterPlugin - instantiateServerBasedLocalization called for language: \(language)")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedLocalizationManager()
        
        manager.instantiateServerBasedLocalization(
            language: language,
            serverUrl: serverUrl,
            transactionId: transactionId,
            requestTimeout: requestTimeout
        ) { error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "LOCALIZATION_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Localization instantiated successfully")
                result(nil)
            }
        }
    }
    
    /**
     * Get the localization map
     */
    private func getLocalizationMap(result: @escaping FlutterResult) {
        NSLog("UdentifyCoreFlutterPlugin - getLocalizationMap called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedLocalizationManager()
        
        manager.getLocalizationMap { localizationMap, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "GET_MAP_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else if let localizationMap = localizationMap {
                NSLog("UdentifyCoreFlutterPlugin - Localization map retrieved")
                result(localizationMap)
            } else {
                NSLog("UdentifyCoreFlutterPlugin - No localization map available")
                result(nil)
            }
        }
    }
    
    /**
     * Clear localization cache
     */
    private func clearLocalizationCache(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let language = args["language"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Language is required",
                details: nil
            ))
            return
        }
        
        NSLog("UdentifyCoreFlutterPlugin - clearLocalizationCache called for language: \(language)")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedLocalizationManager()
        
        manager.clearLocalizationCache(language: language) { error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "CLEAR_CACHE_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Cache cleared successfully")
                result(nil)
            }
        }
    }
    
    /**
     * Map system language to enum
     */
    private func mapSystemLanguageToEnum(result: @escaping FlutterResult) {
        NSLog("UdentifyCoreFlutterPlugin - mapSystemLanguageToEnum called")
        
        let manager = UdentifyCoreFlutterPlugin.getSharedLocalizationManager()
        
        manager.mapSystemLanguageToEnum { language, error in
            if let error = error {
                NSLog("UdentifyCoreFlutterPlugin - Error: \(error.localizedDescription)")
                result(FlutterError(
                    code: "MAP_LANGUAGE_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            } else if let language = language {
                NSLog("UdentifyCoreFlutterPlugin - System language mapped to: \(language)")
                result(language)
            } else {
                NSLog("UdentifyCoreFlutterPlugin - Could not map system language")
                result(nil)
            }
        }
    }
}

