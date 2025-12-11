import Flutter
import UIKit
import UdentifyCommons

final class ThreadSafeFlutterResult {
    private var result: FlutterResult?
    private let lock = NSLock()

    init(_ result: @escaping FlutterResult) {
        self.result = result
    }

    func send(_ value: Any?) {
        lock.lock()
        defer { lock.unlock() }
        guard let result = self.result else { return }
        self.result = nil
        DispatchQueue.main.async {
            result(value)
        }
    }
}

// Import UdentifyNFC framework if available
#if canImport(UdentifyNFC)
import UdentifyNFC
#endif

public class NfcFlutterPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    
#if canImport(UdentifyNFC)
    private var nfcReader: NFCReader?
    private var nfcLocator: NFCLocator?
#endif
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "nfc_flutter", binaryMessenger: registrar.messenger())
        let instance = NfcFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "readPassport":
            readPassport(call: call, result: result)
        case "cancelReading":
            cancelReading(result: result)
        case "getNfcLocation":
            getNfcLocation(call: call, result: result)
        case "checkPermissions":
            checkPermissions(result: result)
        case "requestPermissions":
            requestPermissions(result: result)
        default:
            result(FlutterError(code: "UNIMPLEMENTED", message: "Method not implemented", details: nil))
        }
    }
    
    // MARK: - NFC Methods
    
    private func readPassport(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyNFC)
        let threadSafeResult = ThreadSafeFlutterResult(result)
        
        guard let args = call.arguments as? [String: Any] else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        guard let documentNumber = args["documentNumber"] as? String,
              let dateOfBirth = args["dateOfBirth"] as? String,
              let expiryDate = args["expiryDate"] as? String,
              let transactionID = args["transactionID"] as? String,
              let serverURL = args["serverURL"] as? String else {
            threadSafeResult.send(FlutterError(code: "MISSING_PARAMETERS", message: "Missing required parameters", details: nil))
            return
        }
        
        let requestTimeout = args["requestTimeout"] as? Double ?? 10.0
        let isActiveAuthEnabled = args["isActiveAuthenticationEnabled"] as? Bool ?? true
        let isPassiveAuthEnabled = args["isPassiveAuthenticationEnabled"] as? Bool ?? true
        
        // Get the plugin bundle for localization
        let pluginBundle = Bundle(for: NfcFlutterPlugin.self)
        
        // Initialize NFCReader
        self.nfcReader = NFCReader(
            documentNumber: documentNumber,
            dateOfBirth: dateOfBirth,
            expiryDate: expiryDate,
            transactionID: transactionID,
            serverURL: serverURL,
            requestTimeout: requestTimeout,
            isActiveAuthenticationEnabled: isActiveAuthEnabled,
            isPassiveAuthenticationEnabled: isPassiveAuthEnabled,
            bundle: pluginBundle,
            tableName: nil,
            logLevel: .warning
        )
        
        // Set delegate
        self.nfcReader?.sessionDelegate = self
        
        // Start reading
        self.nfcReader?.read { [weak self, threadSafeResult] passport, error, progress in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                if let passport = passport {
                    // Log PA/AA status for debugging
                    print("=== iOS NFC READ SUCCESS ===")
                    print("Raw PA Status: \(passport.passedPA)")
                    print("Raw AA Status: \(passport.passedAA)")
                    print("Converted PA: \(strongSelf.dgResponseToString(passport.passedPA))")
                    print("Converted AA: \(strongSelf.dgResponseToString(passport.passedAA))")
                    print("=============================")
                    
                    // Convert passport to dictionary
                    let passportDict = strongSelf.passportToDictionary(passport)
                    threadSafeResult.send(passportDict)
                    strongSelf.nfcReader = nil
                } else if let progress = progress {
                    // Send progress update as primitive Int (0-100)
                    let progressInt = Int(progress)
                    strongSelf.channel?.invokeMethod("onProgress", arguments: progressInt)
                } else if let error = error {
                    threadSafeResult.send(FlutterError(code: "NFC_ERROR", message: error.localizedDescription, details: nil))
                    strongSelf.nfcReader = nil
                }
            }
        }
#else
        result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyNFC framework or UdentifyCommons dependency not available. Please ensure both frameworks are properly configured.", details: nil))
#endif
    }
    
    private func cancelReading(result: @escaping FlutterResult) {
#if canImport(UdentifyNFC)
        if let nfcReader = self.nfcReader {
            nfcReader.cancelReading { [weak self] in
                DispatchQueue.main.async {
                    result(nil)
                    self?.nfcReader = nil
                }
            }
        } else {
            result(nil)
        }
#else
        result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyNFC framework not available", details: nil))
#endif
    }
    
    private func getNfcLocation(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyNFC)
        let threadSafeResult = ThreadSafeFlutterResult(result)
        
        guard let args = call.arguments as? [String: Any],
              let serverURL = args["serverURL"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        self.nfcLocator = NFCLocator(serverURL: serverURL)
        
        self.nfcLocator?.locateNFC { [weak self, threadSafeResult] location, error in
            DispatchQueue.main.async {
                guard let strongSelf = self else { return }
                
                if let error = error {
                    threadSafeResult.send(FlutterError(code: "LOCATION_ERROR", message: error.localizedDescription, details: nil))
                } else if let location = location {
                    let locationString = strongSelf.nfcLocationToString(location)
                    threadSafeResult.send(locationString)
                } else {
                    threadSafeResult.send("unknown")
                }
                strongSelf.nfcLocator = nil
            }
        }
#else
        result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyNFC framework not available", details: nil))
#endif
    }
    
    private func checkPermissions(result: @escaping FlutterResult) {
        // iOS doesn't require runtime permissions for NFC
        // NFC capability is handled at build time
        let permissions = [
            "hasPhoneStatePermission": true, // Not applicable on iOS
            "hasNfcPermission": true // Handled by NFC capability
        ]
        result(permissions)
    }
    
    private func requestPermissions(result: @escaping FlutterResult) {
        // iOS doesn't require runtime permissions for NFC
        result("granted")
    }
    
    // MARK: - Helper Methods
    
#if canImport(UdentifyNFC)
    private func passportToDictionary(_ passport: Passport) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let image = passport.image {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                let base64Image = imageData.base64EncodedString()
                dict["image"] = base64Image
            }
        }
        
        if let firstName = passport.firstName {
            dict["firstName"] = firstName
        }
        
        if let lastName = passport.lastName {
            dict["lastName"] = lastName
        }
        
        dict["passedPA"] = self.dgResponseToString(passport.passedPA)
        dict["passedAA"] = self.dgResponseToString(passport.passedAA)
        
        return dict
    }
    

    
    private func dgResponseToString(_ response: DGResponse) -> String {
        switch response {
        case .True: return "true"
        case .False: return "false"
        case .Disabled: return "disabled"
        case .NotSupported: return "notSupported"
        @unknown default: return "notSupported"
        }
    }
    
    private func nfcLocationToString(_ location: NFCLocation) -> String {
        switch location {
        case .frontTop: return "frontTop"
        case .frontCenter: return "frontCenter"
        case .frontBottom: return "frontBottom"
        case .rearTop: return "rearTop"
        case .rearCenter: return "rearCenter"
        case .rearBottom: return "rearBottom"
        @unknown default: return "unknown"
        }
    }
#endif
}

// MARK: - NFCReaderSessionDelegate

#if canImport(UdentifyNFC)
extension NfcFlutterPlugin: NFCReaderSessionDelegate {
    public func nfcReaderSessionDidBegin() {
        // Session started - could emit event here if needed
    }
    
    public func nfcReaderSessionDidEnd(with message: String?) {
        // Session ended - could emit event here if needed
    }
}
#endif
