@preconcurrency import Flutter
import UIKit
import AVFoundation
import udentify_core_flutter

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

// Udentify MRZ SDK imports (conditionally compiled)
#if canImport(UdentifyMRZ)
import UdentifyMRZ
#endif
#if canImport(UdentifyCommons)
import UdentifyCommons
#endif

public class MrzFlutterPlugin: NSObject, FlutterPlugin, @unchecked Sendable {
    private var channel: FlutterMethodChannel?
    private var currentResult: ThreadSafeFlutterResult?
    private var previewView: UIView?
    private var mrzPreviewView: UIView?
    
#if canImport(UdentifyMRZ) && canImport(UdentifyCommons)
    private var mrzCameraController: MRZCameraController?
    private var mrzReader: MRZReader?
#endif
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "mrz_flutter", binaryMessenger: registrar.messenger())
        let instance = MrzFlutterPlugin()
        instance.channel = channel
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let threadSafeResult = ThreadSafeFlutterResult(result)

        switch call.method {
        case "checkPermissions":
            checkPermissions(result: threadSafeResult)
        case "requestPermissions":
            requestPermissions(result: threadSafeResult)
        case "startMrzCamera":
            // Track this as the pending result so cancelMrzScanning()/the camera delegate
            // can complete it later. Only done for the calls that stay pending across an
            // async callback - doing this unconditionally for every call (as before) would
            // let a later call (e.g. cancelMrzScanning itself) clobber this reference before
            // the original caller's Future ever completes.
            currentResult = threadSafeResult
            startMrzCamera(call: call, result: threadSafeResult)
        case "processMrzImage":
            currentResult = threadSafeResult
            processMrzImage(call: call, result: threadSafeResult)
        case "cancelMrzScanning":
            cancelMrzScanning(result: threadSafeResult)
        default:
            threadSafeResult.send(FlutterMethodNotImplemented)
        }
    }
    
    private func checkPermissions(result: ThreadSafeFlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let hasPermission = status == .authorized
        result.send(hasPermission)
    }
    
    private func requestPermissions(result: ThreadSafeFlutterResult) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            result.send("granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                result.send(granted ? "granted" : "denied")
            }
        case .denied, .restricted:
            result.send("denied")
        @unknown default:
            result.send("denied")
        }
    }
    
    /// Appearance passed to the current startMrzCamera call (`MrzUICustomization` on the Dart side).
    private var uiCustomization: [String: Any]?

    private static func color(hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        if value.count == 3 { value = value.map { "\($0)\($0)" }.joined() }  // #RGB
        if value.count == 6 { value = "FF" + value }
        guard value.count == 8, let rgba = UInt64(value, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((rgba & 0x00FF0000) >> 16) / 255,
            green: CGFloat((rgba & 0x0000FF00) >> 8) / 255,
            blue: CGFloat(rgba & 0x000000FF) / 255,
            alpha: CGFloat((rgba & 0xFF000000) >> 24) / 255
        )
    }

    private func startMrzCamera(call: FlutterMethodCall, result: ThreadSafeFlutterResult) {
#if canImport(UdentifyMRZ)
        guard let args = call.arguments as? [String: Any],
              let mode = args["mode"] as? String else {
            result.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        // Check camera permission
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            result.send(FlutterError(code: "PERMISSION_DENIED", message: "Camera permission is required for MRZ scanning", details: nil))
            return
        }
        
        // The MRZ screen is an overlay on the view controller that is on top of the app now (not only the
        // root, which may be underneath a modal another plugin left open).
        guard let viewController = UdentifyPresenter.topViewController() else {
            result.send(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find a view controller to present from", details: nil))
            return
        }
        hostView = viewController.view
        // What was already on the host before the scan: cleanup never touches those views.
        hostSubviewsBeforeScan = Set(viewController.view.subviews.map { ObjectIdentifier($0) })
        
        print("Starting MRZ camera with mode: \(mode)")

        // Optional appearance from Dart; an omitted key keeps the plugin's existing look.
        uiCustomization = args["uiCustomization"] as? [String: Any]
        
        // Create preview views for MRZ camera
        setupPreviewViews(in: viewController.view)
        
        // Start real MRZ camera implementation
        startRealMrzCamera(mode: mode, result: result)
#else
        // SDK not available - return error
        result.send(FlutterError(code: "SDK_NOT_AVAILABLE", 
                          message: "MRZ SDK not available. Please add the Udentify MRZ frameworks to ios/Frameworks/", 
                          details: nil))
#endif
    }
    
    /// The view the overlay was added to, so cleanup removes from the same one.
    private weak var hostView: UIView?

    /// The host view's subviews when the scan started (app views that must survive it).
    private var hostSubviewsBeforeScan: Set<ObjectIdentifier> = []

    /// The labels and buttons the plugin added itself, removed by identity whatever their text was set to.
    private var overlayViews: [UIView] = []

    private func setupPreviewViews(in parentView: UIView) {
        // Create preview view for camera
        previewView = UIView(frame: parentView.bounds)
        previewView?.backgroundColor = UIColor.black
        parentView.addSubview(previewView!)
        
        // Create MRZ preview view (focus area) - NO CUSTOM BORDER
        // Let the SDK handle the focus view completely to avoid double squares
        let mrzFrame = CGRect(
            x: 20,
            y: parentView.bounds.height * 0.6,
            width: parentView.bounds.width - 40,
            height: 100
        )
        mrzPreviewView = UIView(frame: mrzFrame)
        mrzPreviewView?.backgroundColor = UIColor.clear
        // REMOVED: Custom border to prevent double squares
        // The SDK will create its own focus view with proper styling
        parentView.addSubview(mrzPreviewView!)
        
        // Add instruction label
        let instructionLabel = UILabel(frame: CGRect(
            x: 20,
            y: mrzFrame.origin.y - 60,
            width: parentView.bounds.width - 40,
            height: 50
        ))
        instructionLabel.text = uiCustomization?["instructionText"] as? String ?? "Place document MRZ within the frame"
        instructionLabel.textColor = Self.color(hex: uiCustomization?["instructionTextColor"] as? String) ?? UIColor.white
        instructionLabel.textAlignment = .center
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        parentView.addSubview(instructionLabel)
        overlayViews.append(instructionLabel)
        
        // Add cancel button
        let cancelButton = UIButton(frame: CGRect(
            x: parentView.bounds.width - 80,
            y: 50,
            width: 60,
            height: 40
        ))
        cancelButton.setTitle(uiCustomization?["cancelButtonText"] as? String ?? "Cancel", for: .normal)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.backgroundColor = Self.color(hex: uiCustomization?["cancelButtonColor"] as? String)
            ?? UIColor.red.withAlphaComponent(0.7)
        cancelButton.layer.cornerRadius = 8
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        cancelButton.isHidden = !(uiCustomization?["showCancelButton"] as? Bool ?? true)
        parentView.addSubview(cancelButton)
        overlayViews.append(cancelButton)
    }
    
    @objc private func cancelButtonTapped() {
        print("Cancel button tapped - dismissing MRZ screen")
        
        // Return cancellation result to Flutter to properly dismiss the screen
        if let result = currentResult {
            let cancelResult: [String: Any] = [
                "success": false,
                "errorMessage": "USER_CANCELLED",
                "cancelled": true
            ]
            result.send(cancelResult)
            currentResult = nil
        }
        
        // Clean up camera and views - create dummy thread-safe result for cleanup
        let dummyResult = ThreadSafeFlutterResult({ _ in })
        cancelMrzScanning(result: dummyResult)
    }
    
    private func startRealMrzCamera(mode: String, result: ThreadSafeFlutterResult) {
#if canImport(UdentifyMRZ) && canImport(UdentifyCommons)
        // Real SDK implementation when frameworks are available
        print("Starting real MRZ camera with Udentify SDK, mode: \(mode)")
        
        // Initialize MRZCameraController with optimized settings for auto focus
        mrzCameraController = MRZCameraController(
            on: previewView!,
            mrzPreviewView: mrzPreviewView!,
            focusViewBorderColor: Self.color(hex: uiCustomization?["focusViewBorderColor"] as? String) ?? .systemBlue,
            focusViewStrokeWidth: CGFloat((uiCustomization?["focusViewStrokeWidth"] as? NSNumber)?.floatValue ?? 3),
            delegate: self
        )
        
        // Give camera time to initialize auto focus properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.mrzCameraController?.resumeMRZ()
            print("MRZ camera initialized with auto focus enabled")
        }
#else
        // SDK not available - return error immediately
        let mrzResult: [String: Any] = [
            "success": false,
            "errorMessage": "SDK_NOT_AVAILABLE - Please add UdentifyMRZ.xcframework to enable MRZ scanning"
        ]
        result.send(mrzResult)
        cleanupPreviewViews()
#endif
    }
    
    private func processMrzImage(call: FlutterMethodCall, result: ThreadSafeFlutterResult) {
#if canImport(UdentifyMRZ)
        guard let args = call.arguments as? [String: Any],
              let imageBase64 = args["imageBase64"] as? String,
              let mode = args["mode"] as? String else {
            result.send(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
            return
        }
        
        print("Processing MRZ image with mode: \(mode)")
        
        // Decode Base64 image
        guard let imageData = Data(base64Encoded: imageBase64),
              let image = UIImage(data: imageData) else {
            result.send(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode Base64 image", details: nil))
            return
        }
        
        // Use real SDK implementation
        processRealMrzImage(image: image, mode: mode, result: result)
#else
        // SDK not available - return error
        result.send(FlutterError(code: "SDK_NOT_AVAILABLE", 
                          message: "MRZ SDK not available. Please add the Udentify MRZ frameworks to ios/Frameworks/", 
                          details: nil))
#endif
    }
    
    private func processRealMrzImage(image: UIImage, mode: String, result: ThreadSafeFlutterResult) {
#if canImport(UdentifyMRZ) && canImport(UdentifyCommons)
        // Real SDK implementation for image processing
        print("Processing image with real Udentify MRZ SDK, mode: \(mode)")
        
        // Create MRZReader instance
        mrzReader = MRZReader()
        
        // Process the image using real Udentify SDK
        var sourceImage = image
        mrzReader?.processImage(sourceImage: &sourceImage) { (parser, progress) in
            if let parser = parser {
                // Every value comes from the SDK's own MRZField enum.
                let fields = parser.data()
                func field(_ key: MRZField) -> String { fields[key] as? String ?? "" }
                let documentNumber = field(.DocumentNumber)
                let dateOfBirth = field(.DateOfBirth)
                let dateOfExpiration = field(.ExpirationDate)
                let documentType = field(.DocumentType)
                let issuingCountry = field(.CountryCode)
                let gender = field(.Sex)
                let nationality = field(.Nationality)
                let surname = field(.LastName)
                let givenNames = field(.FirstName)
                // The SDK has no optional-data fields; the keys stay for compatibility.
                let optionalData1: String? = nil
                let optionalData2: String? = nil
                
                // Create complete MRZ data structure
                let mrzData: [String: Any] = [
                    "documentType": documentType,
                    "issuingCountry": issuingCountry,
                    "documentNumber": documentNumber,
                    "optionalData1": optionalData1 ?? "",
                    "dateOfBirth": dateOfBirth,
                    "gender": gender,
                    "dateOfExpiration": dateOfExpiration,
                    "nationality": nationality,
                    "optionalData2": optionalData2 ?? "",
                    "surname": surname,
                    "givenNames": givenNames
                ]
                
                let mrzResult: [String: Any] = [
                    "success": true,
                    "mrzData": mrzData,
                    // Legacy fields for backward compatibility
                    "documentNumber": documentNumber,
                    "dateOfBirth": dateOfBirth,
                    "dateOfExpiration": dateOfExpiration
                ]
                result.send(mrzResult)
            } else {
                // Report progress
                DispatchQueue.main.async {
                    self.channel?.invokeMethod("onProgress", arguments: Int(progress))
                }
            }
        }
#else
        // SDK not available - return error immediately
        let mrzResult: [String: Any] = [
            "success": false,
            "errorMessage": "SDK_NOT_AVAILABLE - Please add UdentifyMRZ.xcframework to enable MRZ image processing"
        ]
        result.send(mrzResult)
#endif
    }
    
    private func cancelMrzScanning(result: ThreadSafeFlutterResult) {
        print("Cancelling MRZ scanning and cleaning up resources")
        
#if canImport(UdentifyMRZ) && canImport(UdentifyCommons)
        // Properly stop MRZ processing first
        mrzCameraController?.pauseMRZ()
        mrzCameraController = nil
        mrzReader = nil
#endif
        
        // Clean up preview views
        cleanupPreviewViews()

        // Complete the pending MRZ result (e.g. the startMrzCamera call this cancels) with
        // an error so its Dart Future resolves instead of hanging forever - mirrors
        // Android's cancelMrzScanning(), which calls currentResult?.error("CANCELLED", ...).
        currentResult?.send(FlutterError(code: "CANCELLED", message: "MRZ scanning was cancelled", details: nil))
        currentResult = nil

        result.send(nil)
    }
    
    private func cleanupPreviewViews() {
        print("Cleaning up MRZ preview views and UI elements")
        
        // Ensure all UI operations happen on the main thread
        DispatchQueue.main.async {
            // Pause MRZ processing before cleanup
            #if canImport(UdentifyMRZ) && canImport(UdentifyCommons)
            self.mrzCameraController?.pauseMRZ()
            #endif

            // Remove preview views
            self.previewView?.removeFromSuperview()
            self.mrzPreviewView?.removeFromSuperview()
            self.previewView = nil
            self.mrzPreviewView = nil

            // The plugin's own label and button, found by identity (their text may be the app's)
            self.overlayViews.forEach { $0.removeFromSuperview() }
            self.overlayViews.removeAll()
            
            // Views the SDK added to the host while scanning. Only those: anything that was on the host before
            // the scan started is the app's.
            if let hostView = self.hostView {
                let rootView: UIView? = hostView
                rootView?.subviews.filter { !self.hostSubviewsBeforeScan.contains(ObjectIdentifier($0)) }.forEach { subview in
                    // Remove MRZ camera views, instruction labels, and cancel button
                    if subview.backgroundColor == UIColor.black ||
                       subview.layer.borderColor == UIColor.white.cgColor ||
                       subview.layer.borderColor == UIColor.systemBlue.cgColor ||
                       (subview as? UILabel)?.text?.contains("MRZ") == true ||
                       (subview as? UILabel)?.text?.contains("document") == true ||
                       (subview as? UIButton)?.titleLabel?.text == "Cancel" {
                        print("Removing MRZ UI element: \(type(of: subview))")
                        subview.removeFromSuperview()
                    }
                }
            }
            
            print("MRZ cleanup completed - screen should be dismissed")
        }
    }
}

// MARK: - MRZ Camera Controller Delegate (Real Implementation)
#if canImport(UdentifyMRZ)
extension MrzFlutterPlugin: MRZCameraControllerDelegate {
    
    public func onStart() {
        print("MRZ process is started with auto focus enabled.")
        // Ensure proper focus initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mrzCameraController?.resumeMRZ()
        }
    }
    
    public func onStop() {
        print("MRZ process is stopped.")
    }
    
    public func onPause() {
        print("MRZ process is paused.")
    }
    
    public func onResume() {
        print("Resuming MRZ process with auto focus optimization")
        // Additional focus optimization when resuming
    }
    
    // Required delegate method from MRZCameraControllerDelegate protocol
    public func onDestroy() {
        print("MRZ controller destroyed")
        currentResult = nil
        cleanupPreviewViews()
    }
    
    public func onSuccess(documentNumber: String?, dateOfBirth: String?, dateOfExpiration: String?) {
        // NOTE: UdentifyMRZ's MRZCameraControllerDelegate.onSuccess only ever provides these
        // three parameters (confirmed against UdentifyMRZ.xcframework's public
        // swiftinterface: `func onSuccess(documentNumber: String?, dateOfBirth: String?,
        // dateOfExpiration: String?)`). Unlike processRealMrzImage(), which gets a full
        // MRZParser back from MRZReader.processImage(...) and can read every MRZField, the
        // live-camera MRZCameraController never exposes its parser/frame to this delegate,
        // so documentType/issuingCountry/gender/nationality/surname/givenNames genuinely
        // cannot be populated here - there is no SDK API for it. Left blank intentionally
        // (not a shortcut to "avoid API compatibility issues"); callers who need the full
        // field set should use processMrzImage() instead of the live camera scan.
        let mrzData: [String: Any] = [
            "documentType": "",
            "issuingCountry": "",
            "documentNumber": documentNumber ?? "",
            "optionalData1": "",
            "dateOfBirth": dateOfBirth ?? "",
            "gender": "",
            "dateOfExpiration": dateOfExpiration ?? "",
            "nationality": "",
            "optionalData2": "",
            "surname": "",
            "givenNames": ""
        ]
        
        let mrzResult: [String: Any] = [
            "success": true,
            "mrzData": mrzData,
            // Legacy fields for backward compatibility
            "documentNumber": documentNumber ?? "",
            "dateOfBirth": dateOfBirth ?? "",
            "dateOfExpiration": dateOfExpiration ?? ""
        ]
        
        currentResult?.send(mrzResult)
        currentResult = nil
        
        // Clean up
        mrzCameraController = nil
        cleanupPreviewViews()
    }
    
    public func onProgress(progress: Float) {
        // Send progress updates to Flutter with improved focus feedback
        channel?.invokeMethod("onProgress", arguments: Int(progress))
        if progress > 50 {
            print("MRZ scan progress: \(Int(progress))% - Auto focus active")
        }
    }
    
    public func onFailure(error: Error) {
        let errorMessage: String
        
        if let cameraError = error as? CameraError {
            switch cameraError {
            case .CameraNotFound:
                errorMessage = "CAMERA_NOT_FOUND - Couldn't find the camera"
            case .CameraPermissionRequired:
                errorMessage = "CAMERA_PERMISSION_REQUIRED - Camera permission is required"
            case .FocusViewInvalidSize(let message):
                errorMessage = "FOCUS_VIEW_INVALID_SIZE - MrzPreviewView's size is invalid: \(message)"
            case .SessionPresetNotAvailable:
                errorMessage = "SESSION_PRESET_NOT_AVAILABLE - Min. 720p rear camera is required"
            case .Unknown:
                errorMessage = "UNKNOWN_ERROR - Unknown camera error occurred"
            case .MinIOSRequirementNotSatisfied:
                errorMessage = "MIN_IOS_REQUIREMENT_NOT_SATISFIED - Required iOS version is not supported"
            default:
                errorMessage = "UNKNOWN_CAMERA_ERROR - An unknown camera error occurred"
            }
        } else {
            errorMessage = error.localizedDescription
        }
        
        print("MRZ error: \(errorMessage)")
        
        // Return error result to Flutter and ensure screen dismisses
        if let result = currentResult {
            let mrzResult: [String: Any] = [
                "success": false,
                "errorMessage": errorMessage
            ]
            result.send(mrzResult)
        }
        currentResult = nil
        cleanupPreviewViews()
    }
}
#endif