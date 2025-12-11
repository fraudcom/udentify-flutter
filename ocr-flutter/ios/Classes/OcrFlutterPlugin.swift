@preconcurrency import Flutter
import UIKit
import UdentifyCommons
import UdentifyOCR

final class ThreadSafeFlutterResult: @unchecked Sendable {
    private var result: FlutterResult?
    private let lock = NSLock()

    init(_ result: @escaping FlutterResult) {
        self.result = result
    }

    func send(_ value: (any Sendable)?) {
        lock.lock()
        defer { lock.unlock() }
        guard let result = self.result else { return }
        self.result = nil
        DispatchQueue.main.async {
            result(value)
        }
    }
}

public class OcrFlutterPlugin: NSObject, FlutterPlugin, @unchecked Sendable {
    
    private var ocrCameraController: OCRCameraViewController?
    private var hologramCameraController: HologramCameraViewController?
    
    private var channel: FlutterMethodChannel?
    
    private var lastCapturedFrontImage: UIImage?
    private var lastCapturedBackImage: UIImage?
    
    private var lastCapturedFrontImagePath: String?
    private var lastCapturedBackImagePath: String?
    
    // Store UI configuration
    private var uiConfiguration: [String: any Sendable]?
    
    public override init() {
        super.init()
        setupOCRSettingsDirectly()
    }
    
    private func setupOCRSettingsDirectly() {
        let bundle = Bundle(for: OcrFlutterPlugin.self)
        let customSettings = CustomOCRSettings(localizationBundle: bundle, uiConfig: uiConfiguration)
        OCRSettingsProvider.getInstance().currentSettings = customSettings
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ocr_flutter", binaryMessenger: registrar.messenger())
        let instance = OcrFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startOCRCamera":
            handleStartOCRCamera(call, result: result)
        case "performOCR":
            handlePerformOCR(call, result: result)
        case "startHologramCamera":
            handleStartHologramCamera(call, result: result)
        case "uploadHologramVideo":
            handleUploadHologramVideo(call, result: result)
        case "performDocumentLiveness":
            handlePerformDocumentLiveness(call, result: result)
        case "performOCRAndDocumentLiveness":
            handlePerformOCRAndDocumentLiveness(call, result: result)
        case "setOCRUIConfig":
            handleSetOCRUIConfig(call, result: result)
        case "dismissOCRCamera":
            handleDismissOCRCamera(result)
        case "dismissHologramCamera":
            handleDismissHologramCamera(result)
        default:
            result(FlutterError(code: "UNIMPLEMENTED", 
                               message: "Method not implemented: \(call.method)", 
                               details: nil))
        }
    }
    
    // MARK: - OCR Methods
    
    private func handleStartOCRCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String,
              let documentTypeString = args["documentType"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        let countryString = args["country"] as? String
        let documentSideString = args["documentSide"] as? String ?? "bothSides"
        let manualCapture = args["manualCapture"] as? Bool ?? false
        
        let documentType: OCRDocumentType
        switch documentTypeString {
        case "ID_CARD":
            documentType = OCRDocumentType.ID_CARD
        case "PASSPORT":
            documentType = OCRDocumentType.PASSPORT
        case "DRIVER_LICENSE":
            documentType = OCRDocumentType.DRIVE_LICENCE
        default:
            threadSafeResult.send(FlutterError(code: "INVALID_DOCUMENT_TYPE", message: "Invalid document type", details: nil))
            return
        }

        var country: Country? = nil
        if let countryString = countryString {
            country = CountryCodeMapper.toCountry(countryString)
        }

        let documentSide: OCRDocumentSide
        switch documentSideString {
        case "frontSide":
            documentSide = OCRDocumentSide.frontSide
        case "backSide":
            documentSide = OCRDocumentSide.backSide
        default:
            documentSide = OCRDocumentSide.bothSides
        }

        let capturedCountry = country
        
        DispatchQueue.main.async { [weak self, capturedCountry, threadSafeResult] in
            guard let strongSelf = self else {
                threadSafeResult.send(FlutterError(code: "PLUGIN_DEALLOCATED", message: "Plugin was deallocated", details: nil))
                return
            }
            
            strongSelf.ocrCameraController = OCRCameraViewController.instantiate(
                withApiCallDisabled: strongSelf,
                serverURL: serverURL,
                transactionID: transactionID,
                documentType: documentType,
                country: capturedCountry,
                documentSide: documentSide,
                manualCapture: manualCapture
            )
            
            if let controller = strongSelf.ocrCameraController {
                controller.modalPresentationStyle = .fullScreen
                
                if let viewController = UIApplication.shared.windows.first?.rootViewController {
                    viewController.present(controller, animated: true) {
                        threadSafeResult.send(true)
                    }
                } else {
                    threadSafeResult.send(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
                }
            } else {
                threadSafeResult.send(FlutterError(code: "INSTANTIATION_FAILED", message: "Failed to instantiate OCR camera controller", details: nil))
            }
        }
    }
    
    private func handlePerformOCR(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String,
              let documentTypeString = args["documentType"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        let countryString = args["country"] as? String
        
        debugPrint("OcrFlutterPlugin - performOCR called")
        debugPrint("OcrFlutterPlugin - Stored front path: \(lastCapturedFrontImagePath != nil)")
        debugPrint("OcrFlutterPlugin - Stored back path: \(lastCapturedBackImagePath != nil)")
        debugPrint("OcrFlutterPlugin - Stored front image: \(lastCapturedFrontImage != nil)")
        debugPrint("OcrFlutterPlugin - Stored back image: \(lastCapturedBackImage != nil)")
        
        let documentType: OCRDocumentType
        switch documentTypeString {
        case "ID_CARD":
            documentType = OCRDocumentType.ID_CARD
        case "PASSPORT":
            documentType = OCRDocumentType.PASSPORT
        case "DRIVER_LICENSE":
            documentType = OCRDocumentType.DRIVE_LICENCE
        default:
            threadSafeResult.send(FlutterError(code: "INVALID_DOCUMENT_TYPE", message: "Invalid document type", details: nil))
            return
        }
        
        var country: Country? = nil
        if let countryString = countryString {
            country = CountryCodeMapper.toCountry(countryString)
        }
        
        let capturedCountry = country
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let payload: DocumentScanPayload
            if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
                debugPrint("OcrFlutterPlugin - Using stored image paths for performOCR")
                payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
            } else if self.lastCapturedFrontImage != nil || self.lastCapturedBackImage != nil {
                debugPrint("OcrFlutterPlugin - Using stored UIImage objects for performOCR")
                payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
            } else {
                threadSafeResult.send(FlutterError(code: "NO_IMAGES", message: "No images available for OCR", details: nil))
                return
            }

            OCRCameraViewController.performOCR(
                serverURL: serverURL,
                transactionID: transactionID,
                documentPayload: payload,
                country: capturedCountry,
                documentType: documentType
            ) { [weak self] (response, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.clearStoredData()
                    
                    if let error = error {
                        threadSafeResult.send(FlutterError(code: "OCR_FAILED", message: error.localizedDescription, details: nil))
                    } else if let response = response {
                        let responseDict = self.convertOCRResponseToDict(response, transactionID: transactionID)
                        threadSafeResult.send(responseDict)
                    } else {
                        threadSafeResult.send(FlutterError(code: "NO_RESPONSE", message: "No response received", details: nil))
                    }
                }
            }
        }
    }
    
    // MARK: - Hologram Methods
    
    private func handleStartHologramCamera(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        let countryString = args["country"] as? String
        let logLevelString = args["logLevel"] as? String ?? "warning"
        
        var country: Country? = nil
        if let countryString = countryString {
            country = CountryCodeMapper.toCountry(countryString)
        }
        
        let logLevel: LogLevel
        switch logLevelString.lowercased() {
        case "debug":
            logLevel = LogLevel.debug
        case "info":
            logLevel = LogLevel.info
        case "warning":
            logLevel = LogLevel.warning
        case "error":
            logLevel = LogLevel.error
        default:
            logLevel = LogLevel.warning
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else {
                threadSafeResult.send(FlutterError(code: "PLUGIN_DEALLOCATED", message: "Plugin was deallocated", details: nil))
                return
            }
            
            strongSelf.hologramCameraController = HologramCameraViewController.instantiate(
                delegate: strongSelf,
                serverURL: serverURL,
                transactionID: transactionID,
                country: country,
                logLevel: logLevel
            )
            
            if let controller = strongSelf.hologramCameraController {
                controller.modalPresentationStyle = .fullScreen
                
                if let viewController = UIApplication.shared.windows.first?.rootViewController {
                    viewController.present(controller, animated: true) {
                        threadSafeResult.send(true)
                    }
                } else {
                    threadSafeResult.send(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
                }
            } else {
                threadSafeResult.send(FlutterError(code: "INSTANTIATION_FAILED", message: "Failed to instantiate hologram camera controller", details: nil))
            }
        }
    }
    
    private func handleUploadHologramVideo(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String,
              let videoUrlStrings = args["videoUrls"] as? [String] else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        let videoUrls = videoUrlStrings.compactMap { URL(string: $0) }
        
        DispatchQueue.main.async { [weak self] in
            HologramCameraViewController.uploadHologramVideo(
                serverURL: serverURL,
                transactionID: transactionID,
                paths: videoUrls
            ) { [weak self] (response) in
                if let error = response.error {
                    threadSafeResult.send(FlutterError(code: "HOLOGRAM_UPLOAD_FAILED", message: error.localizedDescription, details: nil))
                } else {
                    let responseDict = self?.convertHologramResponseToDict(response, transactionID: transactionID) ?? [:]
                    threadSafeResult.send(responseDict)
                }
            }
        }
    }
    
    // MARK: - Document Liveness Methods
    
    private func handlePerformDocumentLiveness(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        debugPrint("OcrFlutterPlugin - performDocumentLiveness called")
        debugPrint("OcrFlutterPlugin - Stored front path: \(lastCapturedFrontImagePath != nil)")
        debugPrint("OcrFlutterPlugin - Stored back path: \(lastCapturedBackImagePath != nil)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let payload: DocumentScanPayload
            if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
                debugPrint("OcrFlutterPlugin - Using stored image paths for performDocumentLiveness")
                payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
            } else if self.lastCapturedFrontImage != nil || self.lastCapturedBackImage != nil {
                debugPrint("OcrFlutterPlugin - Using stored UIImage objects for performDocumentLiveness")
                payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
            } else {
                threadSafeResult.send(FlutterError(code: "NO_IMAGES", message: "No images available for document liveness", details: nil))
                return
            }
            
            OCRCameraViewController.performDocumentLiveness(
                serverURL: serverURL,
                transactionID: transactionID,
                documentPayload: payload
            ) { [weak self] (response) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.clearStoredData()
                    
                    if response.isFailed {
                        threadSafeResult.send(FlutterError(code: "DOCUMENT_LIVENESS_FAILED", message: "Document liveness check failed", details: nil))
                    } else {
                        let responseDict = self.convertDocumentLivenessResponseToDict(response, transactionID: transactionID)
                        threadSafeResult.send(responseDict)
                    }
                }
            }
        }
    }
    
    private func handlePerformOCRAndDocumentLiveness(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        guard let args = call.arguments as? [String: any Sendable],
              let serverURL = args["serverURL"] as? String,
              let transactionID = args["transactionID"] as? String,
              let documentTypeString = args["documentType"] as? String else {
            threadSafeResult.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required parameters", details: nil))
            return
        }
        
        let countryString = args["country"] as? String
        
        debugPrint("OcrFlutterPlugin - performOCRAndDocumentLiveness called")
        debugPrint("OcrFlutterPlugin - Stored front path: \(lastCapturedFrontImagePath != nil)")
        debugPrint("OcrFlutterPlugin - Stored back path: \(lastCapturedBackImagePath != nil)")
        
        let documentType: OCRDocumentType
        switch documentTypeString {
        case "ID_CARD":
            documentType = OCRDocumentType.ID_CARD
        case "PASSPORT":
            documentType = OCRDocumentType.PASSPORT
        case "DRIVER_LICENSE":
            documentType = OCRDocumentType.DRIVE_LICENCE
        default:
            threadSafeResult.send(FlutterError(code: "INVALID_DOCUMENT_TYPE", message: "Invalid document type", details: nil))
            return
        }
        
        var country: Country? = nil
        if let countryString = countryString {
            country = CountryCodeMapper.toCountry(countryString)
        }
        
        let capturedCountry = country
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let payload: DocumentScanPayload
            if self.lastCapturedFrontImagePath != nil || self.lastCapturedBackImagePath != nil {
                debugPrint("OcrFlutterPlugin - Using stored image paths for performOCRAndDocumentLiveness")
                payload = .imagePaths(front: self.lastCapturedFrontImagePath, back: self.lastCapturedBackImagePath)
            } else if self.lastCapturedFrontImage != nil || self.lastCapturedBackImage != nil {
                debugPrint("OcrFlutterPlugin - Using stored UIImage objects for performOCRAndDocumentLiveness")
                payload = .images(front: self.lastCapturedFrontImage, back: self.lastCapturedBackImage)
            } else {
                threadSafeResult.send(FlutterError(code: "NO_IMAGES", message: "No images available for OCR and document liveness", details: nil))
                return
            }
            
            OCRCameraViewController.performOCRAndDocumentLiveness(
                serverURL: serverURL,
                transactionID: transactionID,
                documentPayload: payload,
                country: capturedCountry,
                documentType: documentType
            ) { [weak self] (response) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    self.clearStoredData()
                    
                    if response.isFailed {
                        threadSafeResult.send(FlutterError(code: "OCR_AND_DOCUMENT_LIVENESS_FAILED", message: "OCR and document liveness check failed", details: nil))
                    } else {
                        let responseDict = self.convertDocumentLivenessResponseToDict(response, transactionID: transactionID)
                        threadSafeResult.send(responseDict)
                    }
                }
            }
        }
    }

    // MARK: - UI Configuration
    
    private func handleSetOCRUIConfig(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let configDict = call.arguments as? [String: any Sendable] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid configuration arguments", details: nil))
            return
        }
        
        uiConfiguration = configDict
        
        let bundle = Bundle(for: OcrFlutterPlugin.self)
        let customSettings = CustomOCRSettings(localizationBundle: bundle, uiConfig: configDict)
        OCRSettingsProvider.getInstance().currentSettings = customSettings
        
        result(nil)
    }
    
    // MARK: - Helper Methods
    
    private func clearStoredData() {
        self.lastCapturedFrontImage = nil
        self.lastCapturedBackImage = nil
        self.lastCapturedFrontImagePath = nil
        self.lastCapturedBackImagePath = nil
    }
    
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        
        var topController = window.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
    
    // MARK: - Response Conversion
    
    private func convertOCRResponseToDict(_ response: OCRResponse, transactionID: String) -> [String: any Sendable] {
        var resultDict: [String: any Sendable] = [:]
        resultDict["success"] = true
        resultDict["transactionID"] = transactionID
        resultDict["timestamp"] = Date().timeIntervalSince1970
        
        switch response {
        case .idCard(let idCardResponse):
            resultDict["responseType"] = "idCard"
            resultDict["documentType"] = "ID_CARD"
            
            var extractedData: [String: any Sendable] = [:]
            extractedData["firstName"] = idCardResponse.firstName ?? ""
            extractedData["lastName"] = idCardResponse.lastName ?? ""
            extractedData["documentNumber"] = idCardResponse.documentID ?? ""
            extractedData["identityNo"] = idCardResponse.identityNo ?? ""
            extractedData["expiryDate"] = idCardResponse.expiryDate ?? ""
            extractedData["birthDate"] = idCardResponse.birthDate ?? ""
            extractedData["nationality"] = idCardResponse.nationality ?? ""
            extractedData["gender"] = idCardResponse.gender ?? ""
            extractedData["countryCode"] = idCardResponse.countryCode ?? ""
            extractedData["documentIssuer"] = idCardResponse.documentIssuer ?? ""
            extractedData["motherName"] = idCardResponse.motherName ?? ""
            extractedData["fatherName"] = idCardResponse.fatherName ?? ""
            extractedData["isDocumentExpired"] = idCardResponse.isOCRDocumentExpired ?? false
            extractedData["isIDValid"] = idCardResponse.isOCRIDValid ?? false
            extractedData["hasPhoto"] = idCardResponse.hasOCRPhoto ?? false
            extractedData["hasSignature"] = idCardResponse.hasOCRSignature ?? false
            
            if let faceImage = idCardResponse.faceImage {
                let imageData = faceImage.jpegData(compressionQuality: 0.8)
                extractedData["faceImage"] = imageData?.base64EncodedString() ?? ""
            }
            
            resultDict["extractedData"] = extractedData
            
            // Build old format for backward compatibility
            var idCardDict: [String: any Sendable] = [:]
            idCardDict["documentType"] = idCardResponse.documentType
            idCardDict["countryCode"] = idCardResponse.countryCode
            idCardDict["documentID"] = idCardResponse.documentID
            idCardDict["firstName"] = idCardResponse.firstName
            idCardDict["lastName"] = idCardResponse.lastName
            idCardDict["identityNo"] = idCardResponse.identityNo
            idCardDict["birthDate"] = idCardResponse.birthDate
            idCardDict["expiryDate"] = idCardResponse.expiryDate
            idCardDict["nationality"] = idCardResponse.nationality
            idCardDict["gender"] = idCardResponse.gender
            idCardDict["documentIssuer"] = idCardResponse.documentIssuer
            idCardDict["motherName"] = idCardResponse.motherName
            idCardDict["fatherName"] = idCardResponse.fatherName
            idCardDict["isOCRDocumentExpired"] = idCardResponse.isOCRDocumentExpired
            idCardDict["isOCRIDValid"] = idCardResponse.isOCRIDValid
            idCardDict["hasOCRPhoto"] = idCardResponse.hasOCRPhoto
            idCardDict["hasOCRSignature"] = idCardResponse.hasOCRSignature
            if let faceImage = idCardResponse.faceImage,
               let imageData = faceImage.jpegData(compressionQuality: 0.8) {
                idCardDict["faceImage"] = imageData.base64EncodedString()
            }
            resultDict["idCardResponse"] = idCardDict
            
        case .driverLicense(let driverLicenseResponse):
            resultDict["responseType"] = "driverLicense"
            resultDict["documentType"] = "DRIVER_LICENSE"
            
            var extractedData: [String: any Sendable] = [:]
            extractedData["firstName"] = driverLicenseResponse.firstName ?? ""
            extractedData["lastName"] = driverLicenseResponse.lastName ?? ""
            extractedData["documentNumber"] = driverLicenseResponse.documentID ?? ""
            extractedData["identityNo"] = driverLicenseResponse.identityNo ?? ""
            extractedData["expiryDate"] = driverLicenseResponse.expiryDate ?? ""
            extractedData["birthDate"] = driverLicenseResponse.birthDate ?? ""
            extractedData["countryCode"] = driverLicenseResponse.countryCode ?? ""
            extractedData["issueDate"] = driverLicenseResponse.issueDate ?? ""
            extractedData["licenseType"] = driverLicenseResponse.ocrLicenceType ?? ""
            extractedData["city"] = driverLicenseResponse.city ?? ""
            extractedData["district"] = driverLicenseResponse.district ?? ""
            extractedData["isDocumentExpired"] = driverLicenseResponse.isOCRDocumentExpired ?? false
            extractedData["isIDValid"] = driverLicenseResponse.isOCRIDValid ?? false
            
            if let faceImage = driverLicenseResponse.faceImage {
                let imageData = faceImage.jpegData(compressionQuality: 0.8)
                extractedData["faceImage"] = imageData?.base64EncodedString() ?? ""
            }
            
            resultDict["extractedData"] = extractedData
            
            // Build old format for backward compatibility
            var driverLicenseDict: [String: any Sendable] = [:]
            driverLicenseDict["documentType"] = driverLicenseResponse.documentType
            driverLicenseDict["countryCode"] = driverLicenseResponse.countryCode
            driverLicenseDict["documentID"] = driverLicenseResponse.documentID
            driverLicenseDict["firstName"] = driverLicenseResponse.firstName
            driverLicenseDict["lastName"] = driverLicenseResponse.lastName
            driverLicenseDict["identityNo"] = driverLicenseResponse.identityNo
            driverLicenseDict["birthDate"] = driverLicenseResponse.birthDate
            driverLicenseDict["expiryDate"] = driverLicenseResponse.expiryDate
            driverLicenseDict["issueDate"] = driverLicenseResponse.issueDate
            driverLicenseDict["ocrLicenceType"] = driverLicenseResponse.ocrLicenceType
            driverLicenseDict["ocrQRLicenceID"] = driverLicenseResponse.ocrQRLicenceID
            driverLicenseDict["city"] = driverLicenseResponse.city
            driverLicenseDict["district"] = driverLicenseResponse.district
            driverLicenseDict["isOCRDocumentExpired"] = driverLicenseResponse.isOCRDocumentExpired
            driverLicenseDict["isOCRIDValid"] = driverLicenseResponse.isOCRIDValid
            if let faceImage = driverLicenseResponse.faceImage,
               let imageData = faceImage.jpegData(compressionQuality: 0.8) {
                driverLicenseDict["faceImage"] = imageData.base64EncodedString()
            }
            resultDict["driverLicenseResponse"] = driverLicenseDict
            
        case .passport(_):
            resultDict["responseType"] = "passport"
            resultDict["documentType"] = "PASSPORT"
        @unknown default:
            fatalError("")
        }
        
        return resultDict
    }
    
    private func convertDocumentLivenessResponseToDict(_ response: OCRAndDocumentLivenessResponse, transactionID: String) -> [String: any Sendable] {
        var resultDict: [String: any Sendable] = [:]
        resultDict["success"] = !response.isFailed
        resultDict["transactionID"] = transactionID
        resultDict["timestamp"] = Date().timeIntervalSince1970
        resultDict["isFailed"] = response.isFailed
        
        // Add front side liveness data
        if let frontData = response.documentLivenessDataFront?.documentLivenessResponse {
            let frontProbabilityString = frontData.aggregateDocumentLivenessProbability ?? "0"
            resultDict["frontSideProbability"] = Double(frontProbabilityString) ?? 0.0
            
            var frontSideResults: [[String: any Sendable]] = []
            if let pipelineResults = frontData.pipelineResults {
                for result in pipelineResults {
                    var resultDict: [String: any Sendable] = [:]
                    resultDict["name"] = result.name ?? ""
                    let probabilityString = result.documentLivenessProbability ?? "0"
                    resultDict["probability"] = Double(probabilityString) ?? 0.0
                    resultDict["calibration"] = result.calibration ?? ""
                    frontSideResults.append(resultDict)
                }
            }
            resultDict["frontSideResults"] = frontSideResults
        }
        
        // Add back side liveness data
        if let backData = response.documentLivenessDataBack?.documentLivenessResponse {
            let backProbabilityString = backData.aggregateDocumentLivenessProbability ?? "0"
            resultDict["backSideProbability"] = Double(backProbabilityString) ?? 0.0
            
            var backSideResults: [[String: any Sendable]] = []
            if let pipelineResults = backData.pipelineResults {
                for result in pipelineResults {
                    var resultDict: [String: any Sendable] = [:]
                    resultDict["name"] = result.name ?? ""
                    let probabilityString = result.documentLivenessProbability ?? "0"
                    resultDict["probability"] = Double(probabilityString) ?? 0.0
                    resultDict["calibration"] = result.calibration ?? ""
                    backSideResults.append(resultDict)
                }
            }
            resultDict["backSideResults"] = backSideResults
        }
        
        // Add OCR data if available
        if let ocrData = response.ocrData {
            var ocrDict: [String: any Sendable] = [:]
            if let ocrResponse = ocrData.ocrResponse {
                ocrDict["ocrResponse"] = convertOCRResponseToDict(ocrResponse, transactionID: transactionID)
            }
            if let error = ocrData.error {
                ocrDict["error"] = error
            }
            resultDict["ocrData"] = ocrDict
        }
        
        // Add document liveness data for compatibility
        if let frontData = response.documentLivenessDataFront {
            var frontDict: [String: any Sendable] = [:]
            if let frontResponse = frontData.documentLivenessResponse {
                var frontLivenessDict: [String: any Sendable] = [:]
                frontLivenessDict["aggregateDocumentLivenessProbability"] = frontResponse.aggregateDocumentLivenessProbability
                frontLivenessDict["aggregateDocumentImageQualityWarnings"] = frontResponse.aggregateDocumentImageQualityWarnings
                
                if let pipelineResults = frontResponse.pipelineResults {
                    var pipelineArray: [[String: any Sendable]] = []
                    for result in pipelineResults {
                        var pipelineDict: [String: any Sendable] = [:]
                        pipelineDict["name"] = result.name
                        pipelineDict["calibration"] = result.calibration
                        pipelineDict["documentLivenessScore"] = result.documentLivenessScore
                        pipelineDict["documentLivenessProbability"] = result.documentLivenessProbability
                        pipelineDict["documentStatusCode"] = result.documentStatusCode
                        pipelineArray.append(pipelineDict)
                    }
                    frontLivenessDict["pipelineResults"] = pipelineArray
                }
                frontDict["documentLivenessResponse"] = frontLivenessDict
            }
            if let error = frontData.error {
                frontDict["error"] = error
            }
            resultDict["documentLivenessDataFront"] = frontDict
        }
        
        if let backData = response.documentLivenessDataBack {
            var backDict: [String: any Sendable] = [:]
            if let backResponse = backData.documentLivenessResponse {
                var backLivenessDict: [String: any Sendable] = [:]
                backLivenessDict["aggregateDocumentLivenessProbability"] = backResponse.aggregateDocumentLivenessProbability
                backLivenessDict["aggregateDocumentImageQualityWarnings"] = backResponse.aggregateDocumentImageQualityWarnings
                
                if let pipelineResults = backResponse.pipelineResults {
                    var pipelineArray: [[String: any Sendable]] = []
                    for result in pipelineResults {
                        var pipelineDict: [String: any Sendable] = [:]
                        pipelineDict["name"] = result.name
                        pipelineDict["calibration"] = result.calibration
                        pipelineDict["documentLivenessScore"] = result.documentLivenessScore
                        pipelineDict["documentLivenessProbability"] = result.documentLivenessProbability
                        pipelineDict["documentStatusCode"] = result.documentStatusCode
                        pipelineArray.append(pipelineDict)
                    }
                    backLivenessDict["pipelineResults"] = pipelineArray
                }
                backDict["documentLivenessResponse"] = backLivenessDict
            }
            if let error = backData.error {
                backDict["error"] = error
            }
            resultDict["documentLivenessDataBack"] = backDict
        }
        
        return resultDict
    }
    
    private func convertHologramResponseToDict(_ response: HologramResponse, transactionID: String) -> [String: any Sendable] {
        var resultDict: [String: any Sendable] = [:]
        resultDict["success"] = response.error == nil
        resultDict["transactionID"] = transactionID
        resultDict["timestamp"] = Date().timeIntervalSince1970
        
        resultDict["idNumber"] = response.idNumber ?? ""
        resultDict["hologramExists"] = response.hologramExists ?? false
        resultDict["ocrIdAndHologramIdMatch"] = response.ocrIdAndHologramIdMatch ?? false
        resultDict["ocrFaceAndHologramFaceMatch"] = response.ocrFaceAndHologramFaceMatch ?? false
        
        if let hologramImage = response.hologramFaceImage,
           let imageData = hologramImage.jpegData(compressionQuality: 0.8) {
            resultDict["hologramFaceImage"] = imageData.base64EncodedString()
        }
        
        if let error = response.error {
            resultDict["error"] = error.localizedDescription
        }
        
        return resultDict
    }
    
    private func handleDismissOCRCamera(_ result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self, let controller = strongSelf.ocrCameraController {
                controller.dismissOrPopViewController()
            }
            threadSafeResult.send(nil)
        }
    }
    
    private func handleDismissHologramCamera(_ result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)
        DispatchQueue.main.async { [weak self] in
            if let strongSelf = self, let controller = strongSelf.hologramCameraController {
                controller.dismissController()
            }
            threadSafeResult.send(nil)
        }
    }
}

// MARK: - OCRCameraControllerDelegate

extension OcrFlutterPlugin: OCRCameraControllerDelegate, HologramCameraControllerDelegate {
    
    public func onDocumentScan(for side: UdentifyOCR.OCRDocumentSide, payload: UdentifyOCR.DocumentScanPayload) {
        debugPrint("OcrFlutterPlugin - onDocumentScan called for side: \(side)")
        var scanResult: [String: any Sendable] = [:]
        
        switch side {
        case .frontSide:
            scanResult["documentSide"] = "frontSide"
        case .backSide:
            scanResult["documentSide"] = "backSide"
        case .bothSides:
            scanResult["documentSide"] = "bothSide"
        @unknown default:
            scanResult["documentSide"] = "unknown"
        }
        
        switch payload {
        case .imagePaths(front: let frontPath, back: let backPath):
            // Store paths for later use in performOCR
            self.lastCapturedFrontImagePath = frontPath
            self.lastCapturedBackImagePath = backPath
            
            // SDK paths are internal and cannot be accessed directly
            // Send placeholder to indicate images are stored as paths
            if frontPath != nil {
                scanResult["frontSidePhoto"] = "IMAGE_PATH_STORED"
                debugPrint("OcrFlutterPlugin - Front image path stored for performOCR")
            }
            
            if backPath != nil {
                scanResult["backSidePhoto"] = "IMAGE_PATH_STORED"
                debugPrint("OcrFlutterPlugin - Back image path stored for performOCR")
            }
            
        case .images(front: let frontImage, back: let backImage):
            // Store images for later use
            self.lastCapturedFrontImage = frontImage
            self.lastCapturedBackImage = backImage
            
            // Convert images to base64 for Flutter callback
            if let frontImage = frontImage, let frontData = frontImage.jpegData(compressionQuality: 0.8) {
                scanResult["frontSidePhoto"] = frontData.base64EncodedString()
                debugPrint("OcrFlutterPlugin - Front UIImage converted to base64")
            }
            
            if let backImage = backImage, let backData = backImage.jpegData(compressionQuality: 0.8) {
                scanResult["backSidePhoto"] = backData.base64EncodedString()
                debugPrint("OcrFlutterPlugin - Back UIImage converted to base64")
            }
            
        @unknown default:
            break
        }
        
        scanResult["timestamp"] = Date().timeIntervalSince1970
        
        DispatchQueue.main.async { [weak self] in
            self?.ocrCameraController?.dismissOrPopViewController()
            self?.channel?.invokeMethod("onDocumentScan", arguments: scanResult)
        }
    }
    
    public func onIqaResult(for side: UdentifyOCR.OCRDocumentSide, iqaFeedback: UdentifyOCR.IQAFeedback) {
        var iqaResult: [String: any Sendable] = [:]
        
        switch side {
        case .frontSide:
            iqaResult["documentSide"] = "frontSide"
        case .backSide:
            iqaResult["documentSide"] = "backSide"
        case .bothSides:
            iqaResult["documentSide"] = "bothSides"
        @unknown default:
            iqaResult["documentSide"] = "unknown"
        }
        
        switch iqaFeedback {
        case .success:
            iqaResult["feedback"] = "success"
            iqaResult["message"] = "Image quality check passed"
        case .blurDetected:
            iqaResult["feedback"] = "blurDetected"
            iqaResult["message"] = "Image is blurry"
        case .glareDetected:
            iqaResult["feedback"] = "glareDetected"
            iqaResult["message"] = "Glare detected on document"
        case .hologramGlare:
            iqaResult["feedback"] = "hologramGlare"
            iqaResult["message"] = "Hologram glare detected which may occlude text"
        case .cardNotDetected:
            iqaResult["feedback"] = "cardNotDetected"
            iqaResult["message"] = "Document not detected in frame"
        case .cardClassificationMismatch:
            iqaResult["feedback"] = "cardClassificationMismatch"
            iqaResult["message"] = "Wrong document type or side"
        case .cardNotIntact:
            iqaResult["feedback"] = "cardNotIntact"
            iqaResult["message"] = "Forgery detected on document"
        case .other:
            iqaResult["feedback"] = "other"
            iqaResult["message"] = "Other image quality issues detected"
        @unknown default:
            iqaResult["feedback"] = "unknown"
            iqaResult["message"] = "Unknown IQA feedback"
        }
        
        iqaResult["timestamp"] = Date().timeIntervalSince1970
        
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onIQAResult", arguments: iqaResult)
        }
    }
    
    public func willDismiss(controllerType: ControllerType) {
    }
    
    public func didDismiss(controllerType: ControllerType) {
        self.ocrCameraController = nil
        self.hologramCameraController = nil
    }
    
    public func onSuccess(response: OCRResponse) {
        debugPrint("OcrFlutterPlugin - onSuccess called")
        let responseDict = convertOCRResponseToDict(response, transactionID: "")
        DispatchQueue.main.async { [weak self] in
            self?.ocrCameraController?.dismissOrPopViewController()
            self?.channel?.invokeMethod("onOCRSuccess", arguments: responseDict)
        }
    }
    
    public func onFailure(error: Error) {
        debugPrint("OcrFlutterPlugin - onFailure called: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.ocrCameraController?.dismissOrPopViewController()
            self?.hologramCameraController?.dismissOrPopViewController()
            self?.channel?.invokeMethod("onOCRFailure", arguments: ["error": error.localizedDescription])
            self?.channel?.invokeMethod("onHologramFailure", arguments: ["error": error.localizedDescription])
        }
    }
    
    public func onBackButtonPressed(at controllerType: ControllerType) {
        debugPrint("OcrFlutterPlugin - onBackButtonPressed called")
        DispatchQueue.main.async { [weak self] in
            self?.ocrCameraController?.dismissOrPopViewController()
            self?.hologramCameraController?.dismissOrPopViewController()
            self?.channel?.invokeMethod("onBackButtonPressed", arguments: nil)
            self?.channel?.invokeMethod("onHologramBackButtonPressed", arguments: nil)
        }
    }
    
    public func onDestroy(controllerType: ControllerType) {
        DispatchQueue.main.async { [weak self] in
            self?.ocrCameraController = nil
            self?.hologramCameraController = nil
        }
    }
    
    public func didFinishOcrAndDocumentLivenessCheck(response: OCRAndDocumentLivenessResponse) {
        debugPrint("OcrFlutterPlugin - didFinishOcrAndDocumentLivenessCheck called")
        let combinedResponse = convertDocumentLivenessResponseToDict(response, transactionID: "")
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onOCRAndDocumentLivenessResult", arguments: combinedResponse)
        }
    }
    
    public func onVideoRecordFinished(videoUrls: [URL]) {
        debugPrint("OcrFlutterPlugin - onVideoRecordFinished called with \(videoUrls.count) videos")
        let urlStrings = videoUrls.map { $0.absoluteString }
        DispatchQueue.main.async { [weak self] in
            self?.channel?.invokeMethod("onHologramVideoRecorded", arguments: ["videoUrls": urlStrings])
        }
    }
}
