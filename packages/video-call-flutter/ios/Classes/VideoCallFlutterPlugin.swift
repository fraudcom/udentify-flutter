import Flutter
import UIKit
import AVFoundation

// Import UdentifyCommons framework and UdentifyVC source files are included directly
#if canImport(UdentifyCommons)
import UdentifyCommons
#endif

// MARK: - VideoCallBundleHelper (Inline Implementation)

@objc
class VideoCallBundleHelper: NSObject {
  static var localizationBundle: Bundle?
  
  @objc static func setupLocalizationBundle(_ bundle: Bundle) {
    localizationBundle = bundle
    testLocalization()
  }
  
  private static func testLocalization() {
    // Test localization setup
    if let bundle = localizationBundle {
      let testKey = "udentify_vc_notification_label_default"
      let localizedString = bundle.localizedString(forKey: testKey, value: nil, table: nil)
      if localizedString == testKey {
        print("VideoCallBundleHelper - Warning: Localization not working properly")
      }
    }
  }
  
  @objc static func localizedString(forKey key: String, value: String?, table: String?) -> String {
    if let bundle = localizationBundle {
      let result = bundle.localizedString(forKey: key, value: value, table: table)
      if result != key {
        return result
      }
    }
    
    // Fallback to main bundle
    return Bundle.main.localizedString(forKey: key, value: value ?? key, table: table)
  }
}

// MARK: - CustomVideoCallSettings (Inline Implementation)

class CustomVideoCallSettings: NSObject {
  private let localizationBundle: Bundle
  private let uiConfig: [String: Any]?
  
  init(localizationBundle: Bundle, uiConfig: [String: Any]? = nil) {
    self.localizationBundle = localizationBundle
    self.uiConfig = uiConfig
    super.init()
  }
  
#if canImport(UdentifyCommons)
  func createVCSettings() -> VCSettings {
    // Helper function to convert hex string to UIColor
    func colorFromHex(_ hex: String?) -> UIColor? {
      guard let hex = hex, hex.hasPrefix("#"), hex.count == 7 else { return nil }
      let start = hex.index(hex.startIndex, offsetBy: 1)
      let hexColor = String(hex[start...])
      
      let scanner = Scanner(string: hexColor)
      var hexNumber: UInt64 = 0
      
      if scanner.scanHexInt64(&hexNumber) {
        let r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
        let g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
        let b = CGFloat(hexNumber & 0x0000ff) / 255
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
      }
      return nil
    }
    
    // Parse UI configuration
    let backgroundColor = colorFromHex(uiConfig?["backgroundColor"] as? String) ?? .black
    let textColor = colorFromHex(uiConfig?["textColor"] as? String) ?? .white
    let pipBorderColor = colorFromHex(uiConfig?["pipViewBorderColor"] as? String) ?? .white
    
    // Create VCSettings with localization bundle and table name
    let settings = VCSettings(
      bundle: localizationBundle,
      tableName: getTableName(),
      backgroundColor: backgroundColor,
      backgroundStyle: nil,
      overlayImageStyle: nil,
      muteButtonStyle: VCMuteButtonStyle(),
      cameraSwitchButtonStyle: VCCameraSwitchButtonStyle(),
      pipViewStyle: UdentifyViewStyle(
        backgroundColor: .clear,
        borderColor: pipBorderColor,
        cornerRadius: 10,
        borderWidth: 2,
        horizontalSizing: .fixed(width: 120, horizontalPosition: .right(offset: 16)),
        verticalSizing: .fixed(height: 135, verticalPosition: .bottom(offset: 0))
      ),
      instructionLabelStyle: UdentifyTextStyle(
        font: UIFont.systemFont(ofSize: 20, weight: .medium),
        textColor: textColor,
        numberOfLines: 0,
        leading: 35,
        trailing: 35
      ),
      requestTimeout: getRequestTimeout()
    )
    
    return settings
  }
#endif
  
  // MARK: - Localization Methods
  
  func localizedString(forKey key: String, value: String? = nil, table: String? = nil) -> String {
    let result = localizationBundle.localizedString(forKey: key, value: value, table: table)
    if result != key {
      return result
    }
    
    // Fallback to main bundle
    return Bundle.main.localizedString(forKey: key, value: value, table: table)
  }
  
  // MARK: - Configuration Methods
  
  func getTableName() -> String? {
    return uiConfig?["tableName"] as? String
  }
  
  func getRequestTimeout() -> Double {
    return uiConfig?["requestTimeout"] as? Double ?? 30.0
  }
}

public class VideoCallFlutterPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  
#if canImport(UdentifyCommons)
  private var videoCallOperator: VideoCallOperatorImpl?
  private var videoCallViewController: UIViewController?
#endif
  
  private var currentStatus = "idle"
  
  // Store UI configuration
  private var uiConfiguration: [String: Any]?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "video_call_flutter", binaryMessenger: registrar.messenger())
    let instance = VideoCallFlutterPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Setup localization bundle
    instance.setupLocalizationBundle()
  }
  
  private func setupLocalizationBundle() {
    // Setup custom bundle for localization
    setupCustomLocalizationBundle()
  }
  
  private func setupCustomLocalizationBundle() {
    let libraryBundle = Bundle(for: VideoCallFlutterPlugin.self)
    
    // Try to find localization resources
    var resourceBundle: Bundle?
    
    // First, check if the library bundle itself contains localization files
    if libraryBundle.path(forResource: "Localizable", ofType: "strings") != nil {
      resourceBundle = libraryBundle
      print("VideoCallFlutterPlugin - Using library bundle for localization")
    }
    
    // Check in language-specific bundles
    if resourceBundle == nil {
      let preferredLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
      if let langPath = libraryBundle.path(forResource: preferredLanguage, ofType: "lproj"),
         let langBundle = Bundle(path: langPath) {
        resourceBundle = langBundle
        print("VideoCallFlutterPlugin - Using \(preferredLanguage).lproj bundle for localization")
      }
    }
    
    // Fallback to main bundle
    if resourceBundle == nil {
      if Bundle.main.path(forResource: "Localizable", ofType: "strings") != nil {
        resourceBundle = Bundle.main
        print("VideoCallFlutterPlugin - Using main bundle for localization")
      }
    }
    
    if let bundle = resourceBundle {
      setVideoCallLocalizationBundle(bundle)
    } else {
      print("VideoCallFlutterPlugin - Warning: Could not find localization bundle")
    }
  }
  
  private func setVideoCallLocalizationBundle(_ bundle: Bundle) {
    // Set up VideoCallBundleHelper
    VideoCallBundleHelper.setupLocalizationBundle(bundle)
    
    // Set LocalizationConfiguration for SDK
    #if canImport(UdentifyCommons)
    LocalizationConfiguration.bundle = bundle
    
    if let tableName = uiConfiguration?["tableName"] as? String {
      LocalizationConfiguration.tableName = tableName
    } else {
      LocalizationConfiguration.tableName = nil
    }
    #endif
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "checkPermissions":
      checkPermissions(result: result)
    case "requestPermissions":
      requestPermissions(result: result)
    case "startVideoCall":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      startVideoCall(credentials: arguments, result: result)
    case "endVideoCall":
      endVideoCall(result: result)
    case "getVideoCallStatus":
      getVideoCallStatus(result: result)
    case "configureUISettings":
      // This method exists for compatibility but is handled internally by setVideoCallConfig
      result(true)
    case "setVideoCallConfig":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
      }
      setVideoCallConfig(config: arguments, result: result)
    case "toggleCamera":
      toggleCamera(result: result)
    case "switchCamera":
      switchCamera(result: result)
    case "toggleMicrophone":
      toggleMicrophone(result: result)
    case "dismissVideoCall":
      dismissVideoCall(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  // MARK: - Permission Methods
  
  private func checkPermissions(result: @escaping FlutterResult) {
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let hasCameraPermission = cameraStatus == .authorized
    
    let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    let hasRecordAudioPermission = microphoneStatus == .authorized
    
    // iOS doesn't require READ_PHONE_STATE permission like Android
    let hasPhoneStatePermission = true
    
    // Internet permission is not required on iOS
    let hasInternetPermission = true
    
    let permissions: [String: Any] = [
      "hasCameraPermission": hasCameraPermission,
      "hasPhoneStatePermission": hasPhoneStatePermission,
      "hasInternetPermission": hasInternetPermission,
      "hasRecordAudioPermission": hasRecordAudioPermission
    ]
    
    result(permissions)
  }
  
  private func requestPermissions(result: @escaping FlutterResult) {
    let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
    let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    
    // Check if we need to request any permissions
    let needsCameraPermission = cameraStatus == .notDetermined
    let needsMicrophonePermission = microphoneStatus == .notDetermined
    
    if !needsCameraPermission && !needsMicrophonePermission {
      // All permissions are already determined
      let cameraGranted = cameraStatus == .authorized
      let microphoneGranted = microphoneStatus == .authorized
      result((cameraGranted && microphoneGranted) ? "granted" : "denied")
      return
    }
    
    // Request camera permission first
    if needsCameraPermission {
      AVCaptureDevice.requestAccess(for: .video) { cameraGranted in
        if needsMicrophonePermission {
          // Request microphone permission after camera
          AVCaptureDevice.requestAccess(for: .audio) { microphoneGranted in
            DispatchQueue.main.async {
              result((cameraGranted && microphoneGranted) ? "granted" : "denied")
            }
          }
        } else {
          DispatchQueue.main.async {
            let microphoneGranted = microphoneStatus == .authorized
            result((cameraGranted && microphoneGranted) ? "granted" : "denied")
          }
        }
      }
    } else if needsMicrophonePermission {
      // Only request microphone permission
      AVCaptureDevice.requestAccess(for: .audio) { microphoneGranted in
        DispatchQueue.main.async {
          let cameraGranted = cameraStatus == .authorized
          result((cameraGranted && microphoneGranted) ? "granted" : "denied")
        }
      }
    }
  }
  
  // MARK: - Video Call Lifecycle Methods
  
  private func startVideoCall(credentials: [String: Any], result: @escaping FlutterResult) {
    print("VideoCallFlutterPlugin - Starting video call...")
    print("VideoCallFlutterPlugin - Checking UdentifyCommons availability...")
    
#if canImport(UdentifyCommons)
    print("VideoCallFlutterPlugin - ✅ UdentifyCommons framework available")
    print("VideoCallFlutterPlugin - ✅ UdentifyVC source files available")
    guard let serverURL = credentials["serverURL"] as? String,
          let wssURL = credentials["wssURL"] as? String,
          let userID = credentials["userID"] as? String,
          let transactionID = credentials["transactionID"] as? String,
          let clientName = credentials["clientName"] as? String else {
      result(FlutterError(code: "MISSING_PARAMETERS", message: "Missing required parameters", details: nil))
      return
    }
    
    let idleTimeout = credentials["idleTimeout"] as? String ?? "30"
    
    // Create video call operator
    self.videoCallOperator = VideoCallOperatorImpl(
      serverURL: serverURL,
      wssURL: wssURL,
      userID: userID,
      transactionID: transactionID,
      clientName: clientName,
      idleTimeout: idleTimeout,
      channel: self.channel
    )
    
    // Create and present video call view controller
    DispatchQueue.main.async {
      // Create VCSettings using our custom localization settings
      let settings: VCSettings
      
      if let bundle = VideoCallBundleHelper.localizationBundle {
        let customSettings = CustomVideoCallSettings(
          localizationBundle: bundle,
          uiConfig: self.uiConfiguration
        )
        settings = customSettings.createVCSettings()
      } else {
        settings = VCSettings(
          backgroundColor: .black,
          backgroundStyle: nil,
          overlayImageStyle: nil,
          muteButtonStyle: VCMuteButtonStyle(),
          cameraSwitchButtonStyle: VCCameraSwitchButtonStyle(),
          pipViewStyle: UdentifyViewStyle(
            backgroundColor: .clear,
            borderColor: .white,
            cornerRadius: 10,
            borderWidth: 2,
            horizontalSizing: .fixed(width: 120, horizontalPosition: .right(offset: 16)),
            verticalSizing: .fixed(height: 135, verticalPosition: .bottom(offset: 0))
          ),
          instructionLabelStyle: UdentifyTextStyle(
            font: UIFont.systemFont(ofSize: 20, weight: .medium),
            textColor: .white,
            numberOfLines: 0,
            leading: 35,
            trailing: 35
          ),
          requestTimeout: 30
        )
      }
      
      let videoCallViewController = VCCameraController(
        delegate: self.videoCallOperator!,
        serverURL: serverURL,
        wsURL: wssURL,
        transactionID: transactionID,
        username: clientName,
        idleTimeout: Int(idleTimeout) ?? 100,
        settings: settings,
        logLevel: .info
      )
      self.videoCallViewController = videoCallViewController
      
      // Flutter-specific way to get the root view controller
      var rootViewController: UIViewController?
      
      if #available(iOS 13.0, *) {
        rootViewController = UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
          .first { $0.isKeyWindow }?.rootViewController
      } else {
        rootViewController = UIApplication.shared.keyWindow?.rootViewController
      }
      
      // Fallback to the first window's root view controller
      if rootViewController == nil {
        rootViewController = UIApplication.shared.windows.first?.rootViewController
      }
      
      guard let viewController = rootViewController else {
        print("VideoCallFlutterPlugin - ERROR: No root view controller found")
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
        return
      }
      
      print("VideoCallFlutterPlugin - Presenting VCCameraController on: \(type(of: viewController))")
      viewController.present(videoCallViewController, animated: true) {
        print("VideoCallFlutterPlugin - VCCameraController presented successfully")
        let resultMap: [String: Any] = [
          "success": true,
          "status": "connecting",
          "transactionID": transactionID
        ]
        result(resultMap)
      }
    }
#else
    print("VideoCallFlutterPlugin - ❌ ERROR: UdentifyCommons framework NOT available")
    print("VideoCallFlutterPlugin - ❌ This means udentify-core dependency is missing or not properly linked")
    print("VideoCallFlutterPlugin - ❌ Please run: cd ios && pod install --repo-update")
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyCommons framework not available. Please ensure the udentify-core dependency is properly configured.", details: nil))
#endif
  }
  
  private func endVideoCall(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    DispatchQueue.main.async {
      if let viewController = self.videoCallViewController as? VCCameraController {
        // Use the proper dismissController method from UdentifyVC SDK
        viewController.dismissController()
        self.videoCallViewController = nil
        self.videoCallOperator = nil
        
        let resultMap: [String: Any] = [
          "success": true,
          "status": "disconnected"
        ]
        result(resultMap)
      } else {
        let resultMap: [String: Any] = [
          "success": true,
          "status": "disconnected"
        ]
        result(resultMap)
      }
    }
#else
    let resultMap: [String: Any] = [
      "success": true,
      "status": "disconnected"
    ]
    result(resultMap)
#endif
  }
  
  private func getVideoCallStatus(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    let status = videoCallOperator?.getStatus() ?? "idle"
    result(status)
#else
    result("idle")
#endif
  }
  
  // MARK: - Configuration Methods
  
  private func setVideoCallConfig(config: [String: Any], result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    let backgroundColor = config["backgroundColor"] as? String
    let textColor = config["textColor"] as? String
    let pipViewBorderColor = config["pipViewBorderColor"] as? String
    let notificationLabelDefault = config["notificationLabelDefault"] as? String
    let notificationLabelCountdown = config["notificationLabelCountdown"] as? String
    let notificationLabelTokenFetch = config["notificationLabelTokenFetch"] as? String
    
    videoCallOperator?.setConfig(
      backgroundColor: backgroundColor,
      textColor: textColor,
      pipViewBorderColor: pipViewBorderColor,
      notificationLabelDefault: notificationLabelDefault,
      notificationLabelCountdown: notificationLabelCountdown,
      notificationLabelTokenFetch: notificationLabelTokenFetch
    )
    
    result(nil)
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyCommons framework not available", details: nil))
#endif
  }
  
  // MARK: - Control Methods
  
  private func toggleCamera(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    let isEnabled = videoCallOperator?.toggleCamera() ?? false
    result(isEnabled)
#else
    result(false)
#endif
  }
  
  private func switchCamera(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    let success = videoCallOperator?.switchCamera() ?? false
    result(success)
#else
    result(false)
#endif
  }
  
  private func toggleMicrophone(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    let isEnabled = videoCallOperator?.toggleMicrophone() ?? false
    result(isEnabled)
#else
    result(false)
#endif
  }
  
  private func dismissVideoCall(result: @escaping FlutterResult) {
    endVideoCall(result: result)
  }
}

#if canImport(UdentifyCommons)
// MARK: - Video Call Operator Implementation

class VideoCallOperatorImpl: VCCameraControllerDelegate {
  private let serverURL: String
  private let wssURL: String
  private let userID: String
  private let transactionID: String
  private let clientName: String
  private let idleTimeout: String
  private weak var channel: FlutterMethodChannel?
  
  private var currentStatus = "idle"
  
  // Configuration properties
  private var backgroundColor: String?
  private var textColor: String?
  private var pipViewBorderColor: String?
  private var notificationLabelDefault: String?
  private var notificationLabelCountdown: String?
  private var notificationLabelTokenFetch: String?
  
  init(serverURL: String, wssURL: String, userID: String, transactionID: String, 
       clientName: String, idleTimeout: String, channel: FlutterMethodChannel?) {
    self.serverURL = serverURL
    self.wssURL = wssURL
    self.userID = userID
    self.transactionID = transactionID
    self.clientName = clientName
    self.idleTimeout = idleTimeout
    self.channel = channel
  }
  
  func getStatus() -> String {
    return currentStatus
  }
  
  func setConfig(backgroundColor: String?, textColor: String?, pipViewBorderColor: String?,
                 notificationLabelDefault: String?, notificationLabelCountdown: String?,
                 notificationLabelTokenFetch: String?) {
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.pipViewBorderColor = pipViewBorderColor
    self.notificationLabelDefault = notificationLabelDefault
    self.notificationLabelCountdown = notificationLabelCountdown
    self.notificationLabelTokenFetch = notificationLabelTokenFetch
  }
  
  func toggleCamera() -> Bool {
    // Note: Based on UdentifyVC documentation, camera toggle is handled internally by the SDK
    // The VCCameraController manages camera state through its internal UI controls
    // This method returns true to indicate the feature is available, but actual control
    // is managed by the user through the VCCameraController UI
    return true
  }
  
  func switchCamera() -> Bool {
    // Note: Based on UdentifyVC documentation, camera switching is handled internally by the SDK
    // The VCCameraController provides a camera switch button in the UI
    // This method returns true to indicate the feature is available, but actual control
    // is managed by the user through the VCCameraController UI
    return true
  }
  
  func toggleMicrophone() -> Bool {
    // Note: Based on UdentifyVC documentation, microphone toggle is handled internally by the SDK
    // The VCCameraController provides a mute button in the UI
    // This method returns true to indicate the feature is available, but actual control
    // is managed by the user through the VCCameraController UI
    return true
  }
  
  // MARK: - VCCameraControllerDelegate Implementation
  
  public func cameraController(_ controller: VCCameraController, didChangeUserState state: UserState) {
    let stateString: String
    switch state {
    case .initiating:
      stateString = "initiating"
    case .tokenFetching:
      stateString = "tokenFetching"
    case .tokenFetched:
      stateString = "tokenFetched"
    case .connecting:
      stateString = "connecting"
    case .connected:
      stateString = "connected"
    case .disconnected:
      stateString = "disconnected"
    case .reconnecting:
      stateString = "reconnecting"
    @unknown default:
      stateString = "unknown"
    }
    
    currentStatus = stateString
    print("VideoCallOperatorImpl - User state changed: \(stateString)")
    
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onStatusChanged", arguments: stateString)
      self.channel?.invokeMethod("onUserStateChanged", arguments: ["state": stateString])
    }
  }
  
  public func cameraController(_ controller: VCCameraController, participantType: ParticipantType, didChangeState state: ParticipantState) {
    let participantTypeString = participantType == .agent ? "agent" : "supervisor"
    let stateString: String
    
    switch state {
    case .connected:
      stateString = "connected"
    case .videoTrackActivated:
      stateString = "videoTrackActivated"
    case .videoTrackPaused:
      stateString = "videoTrackPaused"
    case .disconnected:
      stateString = "disconnected"
    @unknown default:
      stateString = "unknown"
    }
    
    print("VideoCallOperatorImpl - Participant \(participantTypeString) state changed: \(stateString)")
    
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onParticipantStateChanged", arguments: [
        "participantType": participantTypeString,
        "state": stateString
      ])
    }
  }
  
  public func cameraController(_ controller: VCCameraController, didFailWithError error: Error) {
    currentStatus = "error"
    print("VideoCallOperatorImpl - Error occurred: \(error.localizedDescription)")
    
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onError", arguments: [
        "type": "ERR_SDK",
        "message": error.localizedDescription
      ])
    }
  }
  
  public func cameraControllerDidDismiss(_ controller: VCCameraController) {
    currentStatus = "dismissed"
    print("VideoCallOperatorImpl - Camera controller dismissed")
    
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onVideoCallDismissed", arguments: nil)
    }
  }
  
  public func cameraControllerDidEndSessionSuccessfully(_ controller: VCCameraController) {
    currentStatus = "ended"
    print("VideoCallOperatorImpl - Session ended successfully")
    
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onVideoCallEnded", arguments: ["success": true])
    }
  }
}
#endif
