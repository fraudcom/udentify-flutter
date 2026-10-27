import Flutter
import UIKit
import AVFoundation

#if canImport(UdentifyCommons)
import UdentifyCommons
#endif
import UdentifyVC
import UdentifyLiveKYC
import udentify_core_flutter

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
  
  // MARK: - Config parsing helpers

  /// Accepts `#RGB`, `#RRGGBB` and `#AARRGGBB` (the convention of every other plugin here), and
  /// returns nil for anything else so callers keep the SDK's own value.
  private static func color(fromHex hex: Any?) -> UIColor? {
    guard var value = hex as? String else { return nil }
    value = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard value.hasPrefix("#") else { return nil }
    value.removeFirst()

    if value.count == 3 {
      value = value.map { "\($0)\($0)" }.joined()
    }
    guard value.count == 6 || value.count == 8 else { return nil }

    var hexNumber: UInt64 = 0
    guard Scanner(string: value).scanHexInt64(&hexNumber) else { return nil }

    if value.count == 6 {
      return UIColor(
        red: CGFloat((hexNumber & 0xff0000) >> 16) / 255,
        green: CGFloat((hexNumber & 0x00ff00) >> 8) / 255,
        blue: CGFloat(hexNumber & 0x0000ff) / 255,
        alpha: 1.0)
    }
    return UIColor(
      red: CGFloat((hexNumber & 0x00ff0000) >> 16) / 255,
      green: CGFloat((hexNumber & 0x0000ff00) >> 8) / 255,
      blue: CGFloat(hexNumber & 0x000000ff) / 255,
      alpha: CGFloat((hexNumber & 0xff000000) >> 24) / 255)
  }

  private static func dict(_ container: [String: Any]?, _ key: String) -> [String: Any]? {
    return container?[key] as? [String: Any]
  }

  private static func number(_ container: [String: Any]?, _ key: String) -> CGFloat? {
    guard let value = container?[key] as? NSNumber else { return nil }
    return CGFloat(truncating: value)
  }

#if canImport(UdentifyCommons)

  /// `nil` when the app named no position, so the caller leaves the SDK's own value in place. A
  /// `center` with a signed offset becomes an absolute `.custom(x:)`, since the SDK's `.center`
  /// carries no offset; that keeps one config producing the same layout on both platforms.
  private func horizontalPosition(
    _ position: [String: Any]?,
    elementWidth: CGFloat
  ) -> UdentifyHorizontalPosition? {
    guard let position = position, let type = position["type"] as? String else { return nil }
    let offset = Self.number(position, "offset") ?? 0
    switch type {
    case "center":
      // Without a known container width there is nothing to measure the shift against, so fall
      // back to the SDK's own plain centering.
      let containerWidth = UIScreen.main.bounds.width
      guard offset != 0, containerWidth > 0 else { return .center }
      return .custom(x: containerWidth / 2 + offset - elementWidth / 2)
    case "left": return .left(offset: offset)
    case "right": return .right(offset: offset)
    case "custom": return .custom(x: Self.number(position, "x") ?? 0)
    default: return nil
    }
  }

  /// `nil` when the app named no position - see `horizontalPosition`.
  private static func verticalPosition(_ position: [String: Any]?) -> UdentifyVerticalPosition? {
    guard let position = position, let type = position["type"] as? String else { return nil }
    let offset = number(position, "offset") ?? 0
    switch type {
    case "center": return .center
    case "top": return .top(offset: offset)
    case "bottom": return .bottom(offset: offset)
    case "custom": return .custom(y: number(position, "y") ?? 0)
    default: return nil
    }
  }

  /// `nil` unless the app sized or positioned the element horizontally. `horizontalAnchors` (stretch
  /// between two insets) takes precedence over `width` + `horizontalPosition` (fixed size).
  private func horizontalSizing(_ style: [String: Any]?) -> UdentifyHorizontalSizing? {
    if let anchors = Self.dict(style, "horizontalAnchors") {
      return .anchors(
        leading: Self.number(anchors, "leading") ?? 0,
        trailing: Self.number(anchors, "trailing") ?? 0)
    }
    let width = Self.number(style, "width")
    let position = horizontalPosition(Self.dict(style, "horizontalPosition"), elementWidth: width ?? 90)
    guard width != nil || position != nil else { return nil }
    // `.fixed` needs both halves and the SDK does not expose the default it would have used, so an
    // app that sets only one of the two gets the SDK's documented starting point for the other.
    return .fixed(width: width ?? 90, horizontalPosition: position ?? .right(offset: 16))
  }

  /// `nil` unless the app sized or positioned the element vertically.
  private static func verticalSizing(_ style: [String: Any]?) -> UdentifyVerticalSizing? {
    if let anchors = dict(style, "verticalAnchors") {
      return .anchors(
        top: number(anchors, "top") ?? 0,
        bottom: number(anchors, "bottom") ?? 0)
    }
    let height = number(style, "height")
    let position = verticalPosition(dict(style, "verticalPosition"))
    guard height != nil || position != nil else { return nil }
    return .fixed(height: height ?? 135, verticalPosition: position ?? .bottom(offset: 0))
  }

  /// `nil` when the app set no alignment.
  private static func textAlignment(_ style: [String: Any]?) -> NSTextAlignment? {
    switch style?["textAlign"] as? String {
    case "left": return .left
    case "right": return .right
    case "center": return .center
    default: return nil
    }
  }

  private static func font(_ style: [String: Any]?) -> UIFont {
    // Only reached when the app styles the label at all; the SDK exposes no readable default
    // font, so this mirrors UdentifyTextStyle's own (system, 20pt, medium).
    let size = number(style, "fontSize") ?? 20
    let weight: UIFont.Weight
    switch style?["fontWeight"] as? String {
    case "regular": weight = .regular
    case "medium": weight = .medium
    case "semibold": weight = .semibold
    case "bold": weight = .bold
    default: weight = .medium
    }

    // UIFont(name:) returns nil for a family the app has not bundled, so a typo'd or missing font
    // degrades to the system font at the requested size and weight.
    if let family = style?["fontFamily"] as? String, !family.isEmpty,
       let custom = UIFont(name: family, size: size) {
      return custom
    }
    return UIFont.systemFont(ofSize: size, weight: weight)
  }

  // MARK: - Settings construction

  /// Builds `VCSettings` from the app's `VideoCallConfig`. The styler holds no defaults of its own:
  /// each element starts from the SDK's default-constructed value and only supplied fields are
  /// overwritten, so anything the app omits keeps whatever the SDK ships. `visible` has no home in
  /// `VCSettings` (the compiled SDK offers no way to hide these views), so it is Android only.
  func createVCSettings() -> VCSettings {
    let pipStyle = Self.dict(uiConfig, "pipViewStyle")
    let muteStyle = Self.dict(uiConfig, "muteButtonStyle")
    let cameraSwitchStyle = Self.dict(uiConfig, "cameraSwitchButtonStyle")
    let labelStyle = Self.dict(uiConfig, "instructionLabelStyle")

    let backgroundColor = Self.color(fromHex: uiConfig?["backgroundColor"])
    // The flat `textColor` / `pipViewBorderColor` keys are shorthands; the specific style wins.
    let textColor = Self.color(fromHex: labelStyle?["textColor"])
      ?? Self.color(fromHex: uiConfig?["textColor"])
    let pipBorderColor = Self.color(fromHex: pipStyle?["borderColor"])
      ?? Self.color(fromHex: uiConfig?["pipViewBorderColor"])

    var muteButtonStyle: VCMuteButtonStyle?
    if let muteStyle = muteStyle {
      var style = VCMuteButtonStyle()
      if let v = Self.color(fromHex: muteStyle["mutedColor"]) { style.mutedColor = v }
      if let v = Self.color(fromHex: muteStyle["unmutedColor"]) { style.unmutedColor = v }
      if let v = Self.number(muteStyle, "size") { style.size = v }
      if let v = horizontalPosition(Self.dict(muteStyle, "horizontalPosition"), elementWidth: style.size) {
        style.horizontalPosition = v
      }
      if let v = Self.verticalPosition(Self.dict(muteStyle, "verticalPosition")) {
        style.verticalPosition = v
      }
      muteButtonStyle = style
    }

    var cameraSwitchButtonStyle: VCCameraSwitchButtonStyle?
    if let cameraSwitchStyle = cameraSwitchStyle {
      var style = VCCameraSwitchButtonStyle()
      if let v = Self.color(fromHex: cameraSwitchStyle["color"]) { style.color = v }
      if let v = Self.number(cameraSwitchStyle, "size") { style.size = v }
      if let v = horizontalPosition(Self.dict(cameraSwitchStyle, "horizontalPosition"), elementWidth: style.size) {
        style.horizontalPosition = v
      }
      if let v = Self.verticalPosition(Self.dict(cameraSwitchStyle, "verticalPosition")) {
        style.verticalPosition = v
      }
      cameraSwitchButtonStyle = style
    }

    var pipViewStyle: UdentifyViewStyle?
    if pipStyle != nil || pipBorderColor != nil {
      // borderWidth is get-only, so it goes through the initializer, and its fallback is read
      // back off a default-constructed instance so the SDK still owns the value. backgroundColor
      // has no default, so .clear is used unless the app set one.
      let sdk = UdentifyViewStyle(backgroundColor: .clear)
      var style = UdentifyViewStyle(
        backgroundColor: Self.color(fromHex: pipStyle?["backgroundColor"]) ?? .clear,
        borderWidth: Self.number(pipStyle, "borderWidth") ?? sdk.borderWidth)
      if let v = pipBorderColor { style.borderColor = v }
      if let v = Self.number(pipStyle, "cornerRadius") { style.cornerRadius = v }
      if let v = horizontalSizing(pipStyle) { style.horizontalSizing = v }
      if let v = Self.verticalSizing(pipStyle) { style.verticalSizing = v }
      pipViewStyle = style
    }

    var instructionLabelStyle: UdentifyTextStyle?
    if labelStyle != nil || textColor != nil {
      // font and textColor have no defaults on UdentifyTextStyle, so both are always supplied.
      var style = UdentifyTextStyle(font: Self.font(labelStyle), textColor: textColor ?? .white)
      if let v = Self.textAlignment(labelStyle) { style.textAlignment = v }
      if let v = Self.number(labelStyle, "numberOfLines") { style.numberOfLines = Int(v) }
      if let v = Self.number(labelStyle, "lineHeightMultiple") { style.lineHeightMultiple = v }
      if let v = Self.number(labelStyle, "leading") { style.leading = v }
      if let v = Self.number(labelStyle, "trailing") { style.trailing = v }
      if let v = Self.verticalPosition(Self.dict(labelStyle, "verticalPosition")) {
        style.verticalPosition = v
      }
      instructionLabelStyle = style
    }

    return VCSettings(
      bundle: localizationBundle,
      tableName: getTableName(),
      backgroundColor: backgroundColor,
      backgroundStyle: nil,
      overlayImageStyle: nil,
      muteButtonStyle: muteButtonStyle,
      cameraSwitchButtonStyle: cameraSwitchButtonStyle,
      pipViewStyle: pipViewStyle,
      instructionLabelStyle: instructionLabelStyle,
      requestTimeout: getRequestTimeout())
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
  // A second cancel while one is on the wire is refused: the server does not treat a
  // duplicate cancel as idempotent.
  private var cancelInFlight = false
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
  
  /// The bundle chosen at registration follows the device language. When the app has since picked a
  /// language (`instantiateServerBasedLocalization`), narrow to it if this plugin ships that language,
  /// like OCR, liveness and NFC do. With no choice made, or no matching table, nothing changes.
  private func applySelectedLanguage() {
    let libraryBundle = Bundle(for: VideoCallFlutterPlugin.self)
    let narrowed = UdentifyLanguagePreference.localizedBundle(for: libraryBundle)
    guard narrowed.bundlePath != libraryBundle.bundlePath else { return }
    setVideoCallLocalizationBundle(narrowed)
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
    case "cancelVideoCall":
      cancelVideoCall(result: result)
    case "setMicrophoneEnabled":
      guard let arguments = call.arguments as? [String: Any],
            let enabled = arguments["enabled"] as? Bool else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "enabled is required", details: nil))
        return
      }
      setMicrophoneEnabled(enabled, result: result)
    case "isMicrophoneEnabled":
      isMicrophoneEnabled(result: result)
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
    
    // One call screen at a time. A second start would replace the delegate of the screen that is still up.
    if let current = self.videoCallViewController, current.presentingViewController != nil {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "A video call is already on screen.", details: nil))
      return
    }

    let idleTimeout = credentials["idleTimeout"] as? String ?? "30"

    // Frames per second. Stays nil unless the app asked, so the SDK's own default applies;
    // the SDK clamps a rate the sensor cannot do, so only meaningless input is refused here.
    var cameraFeedFrameRate: Int?
    if let value = credentials["cameraFeedFrameRate"] as? NSNumber {
      if value.intValue > 0 {
        cameraFeedFrameRate = value.intValue
      } else {
        print("VideoCallFlutterPlugin - cameraFeedFrameRate=\(value) ignored: expected a positive number of frames per second")
      }
    }
    
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
      self.applySelectedLanguage()
      // The compiled SDK resolves its texts through this static, not through the settings object, and a table
      // name belongs to this call's config: assign it now, because the bundle set-up above ran before any config
      // existed (and only re-runs when the language choice narrows the bundle).
      LocalizationConfiguration.tableName = self.uiConfiguration?["tableName"] as? String

      // Create VCSettings using our custom localization settings
      let settings: VCSettings
      
      if let bundle = VideoCallBundleHelper.localizationBundle {
        let customSettings = CustomVideoCallSettings(
          localizationBundle: bundle,
          uiConfig: self.uiConfiguration
        )
        settings = customSettings.createVCSettings()
      } else {
        // No localization bundle resolved: the SDK's own settings, unstyled.
        settings = VCSettings()
      }
      
      // LiveKYC is toggled exactly the way the SDK toggles it: nil runs a plain call, a non-nil
      // VCLiveKYCOptions enables it. The wrapper adds no gate of its own: passing liveKYCOptions
      // (or credentials.observationMode) is the app asking for LiveKYC.
      Self.installLiveKYCModuleSettings()
      let liveKYCOptions = Self.buildLiveKYCOptions(
        from: credentials["liveKYCOptions"] as? [String: Any],
        credentials: credentials,
        operatorImpl: self.videoCallOperator!
      )

      // Two call sites rather than a `?? 15`: cameraFeedFrameRate defaults in the SDK's own
      // initialiser, and copying that number here would pin it.
      // `info` is the SDK's documented default, used when the app sets none.
      let controllerLogLevel = Self.logLevel(credentials["logLevel"]) ?? .info
      let videoCallViewController: VCCameraController
      if let cameraFeedFrameRate = cameraFeedFrameRate {
        videoCallViewController = VCCameraController(
          delegate: self.videoCallOperator!,
          serverURL: serverURL,
          wsURL: wssURL,
          transactionID: transactionID,
          username: clientName,
          idleTimeout: Int(idleTimeout) ?? 100,
          settings: settings,
          cameraFeedFrameRate: cameraFeedFrameRate,
          liveKYCOptions: liveKYCOptions,
          logLevel: controllerLogLevel
        )
      } else {
        videoCallViewController = VCCameraController(
          delegate: self.videoCallOperator!,
          serverURL: serverURL,
          wsURL: wssURL,
          transactionID: transactionID,
          username: clientName,
          idleTimeout: Int(idleTimeout) ?? 100,
          settings: settings,
          liveKYCOptions: liveKYCOptions,
          logLevel: controllerLogLevel
        )
      }
      // The SDK publishes every microphone change (in-call button, agent signal, automatic
      // mutes) through this static hook; it is already de-duplicated.
      VCCameraController.onMicrophoneStateChanged = { [weak op = self.videoCallOperator] enabled in
        op?.onMicrophoneStateChanged(enabled)
      }
      self.videoCallViewController = videoCallViewController
      // The controller holds its delegate weakly, so the operator has to outlive the call screen: it is
      // released only when the SDK reports the screen gone (`cameraControllerDidDismiss`), as the
      // documentation says, never while a dismissal is still in flight.
      if let op = self.videoCallOperator {
        op.onDismissed = { [weak self, weak op] in
          guard let self = self, let op = op, self.videoCallOperator === op else { return }
          self.videoCallViewController = nil
          self.videoCallOperator = nil
        }
      }
      
      // Present from whatever is on top of the app right now, not from the root view controller: the root
      // may already be presenting something, and presenting from it would then do nothing.
      guard let presenter = UdentifyPresenter.topViewController() else {
        print("VideoCallFlutterPlugin - ERROR: nothing to present from")
        self.videoCallViewController = nil
        self.videoCallOperator = nil
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "No view controller available", details: nil))
        return
      }

      print("VideoCallFlutterPlugin - Presenting VCCameraController on: \(type(of: presenter))")
      // The SDK ends the call by dismissing or popping the controller, so it is presented rather than
      // embedded, full screen, exactly as the iOS documentation shows.
      videoCallViewController.modalPresentationStyle = .fullScreen
      presenter.present(videoCallViewController, animated: true) {
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
        Self.clearLiveKYCModuleSettings()
        // Not released here: the operator is the controller's (weak) delegate, and it must still be
        // alive to receive `cameraControllerDidDismiss`, where it is released.
        
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
    // Cache the raw configuration so createVCSettings(uiConfig:) picks it up
    // the next time a video call is started/presented.
    self.uiConfiguration = config

    let backgroundColor = config["backgroundColor"] as? String
    let textColor = config["textColor"] as? String
    let pipViewBorderColor = config["pipViewBorderColor"] as? String
    
    videoCallOperator?.setConfig(
      backgroundColor: backgroundColor,
      textColor: textColor,
      pipViewBorderColor: pipViewBorderColor
    )
    
    result(nil)
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyCommons framework not available", details: nil))
#endif
  }
  
  // MARK: - Control Methods
  
  // MARK: - LiveKYC

  /// Assigns `LiveKYCSettings.ocr` / `.face` / `.nfc`, so the in-call module screens get their own
  /// plugin's settings provider. The bodies live in the module plugins and arrive through
  /// udentify_core_flutter, so this plugin links neither UdentifyOCR nor UdentifyFACE. An unfilled
  /// slot stays nil. Assigned as the call starts: no module screen exists before the controller.
  fileprivate static func installLiveKYCModuleSettings() {
    LiveKYCSettings.ocr = { UdentifyLiveKYCModuleSettings.installOCRSettings?() }
    LiveKYCSettings.face = { UdentifyLiveKYCModuleSettings.installFaceSettings?() }
    LiveKYCSettings.nfc = { UdentifyLiveKYCModuleSettings.installNFCSettings?() }
  }

  fileprivate static func clearLiveKYCModuleSettings() {
    LiveKYCSettings.ocr = nil
    LiveKYCSettings.face = nil
    LiveKYCSettings.nfc = nil
  }

  /// Builds `VCLiveKYCOptions` from the `liveKYCOptions` map, falling back to
  /// `credentials.observationMode` alone; `liveKYCOptions` wins when both are given. `nil` means no
  /// LiveKYC, and omitted fields keep the SDK's defaults.
  private static func buildLiveKYCOptions(
    from options: [String: Any]?,
    credentials creds: [String: Any],
    operatorImpl: VideoCallOperatorImpl
  ) -> VCLiveKYCOptions? {
    let legacyMode = (creds["observationMode"] as? String).flatMap(observationMode)
    guard let options = options else {
      guard let mode = legacyMode else { return nil }
      return VCLiveKYCOptions(
        userID: creds["userID"] as? String,
        observationMode: mode,
        onEvent: { [weak operatorImpl] in operatorImpl?.handleLiveKYCEvent($0) }
      )
    }

    let defaults = VCLiveKYCOptions()
    let mode = (options["observationMode"] as? String).flatMap(observationMode)
      ?? legacyMode ?? defaults.observationMode

    return VCLiveKYCOptions(
      ocrDocumentType: enumValue(options["ocrDocumentType"], defaults.ocrDocumentType),
      ocrCountry: country(options["ocrCountry"]) ?? defaults.ocrCountry,
      ocrDocumentSide: enumValue(options["ocrDocumentSide"], defaults.ocrDocumentSide),
      ocrManualCapture: options["ocrManualCapture"] as? Bool ?? defaults.ocrManualCapture,
      ocrDocumentLivenessEnabled: options["ocrDocumentLivenessEnabled"] as? Bool
        ?? defaults.ocrDocumentLivenessEnabled,
      ocrLogLevel: logLevel(options["ocrLogLevel"]) ?? defaults.ocrLogLevel,
      hologramNoFlashDuration: number(options["hologramNoFlashDuration"]) ?? defaults.hologramNoFlashDuration,
      hologramFlashDuration: number(options["hologramFlashDuration"]) ?? defaults.hologramFlashDuration,
      hologramTotalDuration: number(options["hologramTotalDuration"]) ?? defaults.hologramTotalDuration,
      hologramBitrate: number(options["hologramBitrate"]) ?? defaults.hologramBitrate,
      hologramRequestTimeout: number(options["hologramRequestTimeout"]) ?? defaults.hologramRequestTimeout,
      hologramLogLevel: logLevel(options["hologramLogLevel"]) ?? defaults.hologramLogLevel,
      faceMethod: enumValue(options["faceMethod"], defaults.faceMethod),
      selfieOperation: enumValue(options["selfieOperation"], defaults.selfieOperation),
      faceLivenessMode: enumValue(options["faceLivenessMode"], defaults.faceLivenessMode),
      faceLogLevel: logLevel(options["faceLogLevel"]) ?? defaults.faceLogLevel,
      userID: options["userID"] as? String ?? creds["userID"] as? String ?? defaults.userID,
      listName: options["listName"] as? String ?? defaults.listName,
      nfcChipAnticloneMode: enumValue(options["nfcChipAnticloneMode"], defaults.nfcChipAnticloneMode),
      nfcIsPassiveAuthenticationEnabled: options["nfcIsPassiveAuthenticationEnabled"] as? Bool
        ?? defaults.nfcIsPassiveAuthenticationEnabled,
      nfcRequestTimeout: number(options["nfcRequestTimeout"]) ?? defaults.nfcRequestTimeout,
      nfcIsFastModeEnabled: options["nfcIsFastModeEnabled"] as? Bool ?? defaults.nfcIsFastModeEnabled,
      // NFC takes its text bundle here rather than through a settings provider, so without this
      // the in-call NFC screen reads from .main. Falls back to the SDK's default when the NFC
      // plugin is not installed.
      nfcBundle: UdentifyLiveKYCModuleSettings.nfcLocalizationBundle?() ?? defaults.nfcBundle,
      nfcTableName: options["nfcTableName"] as? String ?? defaults.nfcTableName,
      nfcLogLevel: logLevel(options["nfcLogLevel"]) ?? defaults.nfcLogLevel,
      observationMode: mode,
      onEvent: { [weak operatorImpl] in operatorImpl?.handleLiveKYCEvent($0) }
    )
  }

  /// The SDK's `LogLevel` for the name Dart sent (`verbose`, `debug`, `info`, `warning`, `error`), or
  /// nil so the SDK's own default stays. An unrecognised name is ignored rather than failing the call.
  private static func logLevel(_ raw: Any?) -> LogLevel? {
    switch raw as? String {
    case "verbose": return .verbose
    case "debug": return .debug
    case "info": return .info
    case "warning": return .warning
    case "error": return .error
    default: return nil
    }
  }

  /// Dart doubles arrive as NSNumber; ints from Dart arrive as Int, so accept either.
  private static func number(_ raw: Any?) -> Double? {
    (raw as? NSNumber)?.doubleValue
  }

  /// A `String`-backed SDK enum from the value Dart sent. No name translation: the Dart enums carry
  /// the SDK's own raw values, so a lookup is exact. An unrecognised value keeps the SDK default
  /// rather than failing the call.
  private static func enumValue<T: RawRepresentable>(_ raw: Any?, _ fallback: T) -> T
    where T.RawValue == String {
    guard let name = raw as? String else { return fallback }
    guard let match = T(rawValue: name) else {
      print("VideoCallFlutterPlugin - unknown LiveKYC value '\(name)'; keeping the SDK default")
      return fallback
    }
    return match
  }

  private static func country(_ raw: Any?) -> Country? {
    guard let code = raw as? String else { return nil }
    if let exact = Country(rawValue: code.uppercased()) { return exact }
    print("VideoCallFlutterPlugin - unknown ocrCountry '\(code)'; keeping the SDK default")
    return nil
  }

  private static func observationMode(_ raw: String) -> VCLiveKYCObservationMode? {
    switch raw.uppercased() {
    case "CAMERA_FEED": return .cameraFeed
    case "SCREEN_SHARE": return .screenShare
    case "PROGRESS_ONLY": return .progressOnly
    default:
      print("VideoCallFlutterPlugin - unknown observationMode '\(raw)'; LiveKYC stays off")
      return nil
    }
  }

  private func cancelVideoCall(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    guard let operatorImpl = videoCallOperator else {
      result(FlutterError(code: "NO_ACTIVE_CALL", message: "There is no active video call to cancel.", details: nil))
      return
    }
    if cancelInFlight {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "A cancel request is already in progress.", details: nil))
      return
    }
    cancelInFlight = true

    DispatchQueue.main.async {
      // A cancel that reaches the SDK dismisses the controller itself.
      VCCameraController.cancelVideoCall(
        serverUrl: operatorImpl.serverURL,
        transactionId: operatorImpl.transactionID
      ) { outcome in
        DispatchQueue.main.async {
          self.cancelInFlight = false
          switch outcome {
          case .success(let success):
            // On success the SDK dismisses the screen itself; the operator stays alive until
            // `cameraControllerDidDismiss` reports it, where it is released.
            result([
              "success": success,
              "status": success ? "disconnected" : operatorImpl.getStatus()
            ])
          case .failure(let error):
            result(FlutterError(code: "CANCEL_VIDEO_CALL_FAILED", message: error.localizedDescription, details: nil))
          }
        }
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyCommons framework not available", details: nil))
#endif
  }

  // `true` means the request was accepted, not applied: the real outcome arrives as
  // onMicrophoneStateChanged.
  private func setMicrophoneEnabled(_ enabled: Bool, result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    DispatchQueue.main.async {
      result(VCCameraController.setMicrophoneEnabled(enabled))
    }
#else
    result(false)
#endif
  }

  private func isMicrophoneEnabled(result: @escaping FlutterResult) {
#if canImport(UdentifyCommons)
    DispatchQueue.main.async {
      result(VCCameraController.isMicrophoneEnabled())
    }
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
  let serverURL: String
  private let wssURL: String
  private let userID: String
  let transactionID: String
  private let clientName: String
  private let idleTimeout: String
  private weak var channel: FlutterMethodChannel?
  
  private var currentStatus = "idle"

  /// Set by the plugin; run once the SDK reports the call screen dismissed.
  var onDismissed: (() -> Void)?
  
  // Configuration properties
  private var backgroundColor: String?
  private var textColor: String?
  private var pipViewBorderColor: String?
  
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
  
  func setConfig(backgroundColor: String?, textColor: String?, pipViewBorderColor: String?) {
    self.backgroundColor = backgroundColor
    self.textColor = textColor
    self.pipViewBorderColor = pipViewBorderColor
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

      // The SDK only reports an actual change, and after a background/reconnect cycle the
      // microphone state is not restored and no event fires. Its documented guidance is to
      // re-seed from isMicrophoneEnabled() whenever the user state becomes connected again.
      if stateString == "connected" {
        self.onMicrophoneStateChanged(VCCameraController.isMicrophoneEnabled())
      }
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
    print("VideoCallOperatorImpl - Error occurred: \(error.localizedDescription)")

    // Not every error ends the call. ERR_LIVEKYC_SCREEN_RECORDING_PERMISSION_DENIED is informational:
    // the call carries on camera-only with screen sharing off. Reporting "failed" would tell the app
    // the call died while it is still running, so the error is surfaced and the status left alone.
    let informational = Self.isInformational(error)
    if !informational {
      currentStatus = "failed"
    }

    DispatchQueue.main.async {
      self.channel?.invokeMethod("onError", arguments: [
        "type": Self.errorType(for: error),
        "message": error.localizedDescription
      ])
      if !informational {
        self.channel?.invokeMethod("onStatusChanged", arguments: "failed")
      }
    }
  }

  /// Errors the SDK reports for information, which leave the call running.
  private static func isInformational(_ error: Error) -> Bool {
    guard let vcError = error as? VCError else { return false }
    if case .screenRecordingPermissionDenied = vcError { return true }
    return false
  }

  // Permission failures get their own type rather than the catch-all ERR_SDK: they are the one
  // class of SDK error the app can act on (prompt, or send the user to Settings). The SDK's own
  // errorDescription for these cases is the ERR_* code.
  private static func errorType(for error: Error) -> String {
    guard let vcError = error as? VCError else { return "ERR_SDK" }
    switch vcError {
    case .cameraPermissionRequired, .cameraPermissionDenied,
         .microphonePermissionRequired, .microphonePermissionDenied:
      return vcError.errorDescription ?? "ERR_SDK"
    default:
      return "ERR_SDK"
    }
  }
  
  public func cameraControllerDidDismiss(_ controller: VCCameraController) {
    currentStatus = "disconnected"
    print("VideoCallOperatorImpl - Camera controller dismissed")

    DispatchQueue.main.async {
      VideoCallFlutterPlugin.clearLiveKYCModuleSettings()
      self.channel?.invokeMethod("onStatusChanged", arguments: "disconnected")
      self.channel?.invokeMethod("onVideoCallDismissed", arguments: nil)
      // The call screen is gone; the plugin can now let go of the controller and this delegate.
      self.onDismissed?()
    }
  }

  public func cameraControllerDidEndSessionSuccessfully(_ controller: VCCameraController) {
    currentStatus = "completed"
    print("VideoCallOperatorImpl - Session ended successfully")

    DispatchQueue.main.async {
      VideoCallFlutterPlugin.clearLiveKYCModuleSettings()
      self.channel?.invokeMethod("onStatusChanged", arguments: "completed")
      self.channel?.invokeMethod("onVideoCallEnded", arguments: ["success": true])
    }
  }

  // Informational only: a device phone call overlapping the video call does not end the
  // session, so `currentStatus` is deliberately left alone.
  public func cameraController(_ controller: VCCameraController, didChangePhoneCallState state: PhoneCallState) {
    let stateString: String
    switch state {
    case .incoming:
      stateString = "incoming"
    case .outgoing:
      stateString = "outgoing"
    case .connected:
      stateString = "connected"
    case .ended:
      stateString = "ended"
    @unknown default:
      stateString = "ended"
    }

    DispatchQueue.main.async {
      self.channel?.invokeMethod("onPhoneCallStateChanged", arguments: ["state": stateString])
    }
  }

  // MARK: - LiveKYC events

  func handleLiveKYCEvent(_ event: VCLiveKYCEvent) {
    switch event {
    case .moduleStarted(let module):
      emitOnMain("onRepeatStarted", ["role": module.rawValue.uppercased()])
    case .moduleCompleted(let module):
      // Android emits a result before the end-of-repeat event; mirror that ordering so a Dart
      // handler written for one platform behaves the same on the other.
      emitOnMain("onRepeatResult", ["role": module.rawValue.uppercased()])
      emitRepeatEnded(module: module, outcome: "COMPLETED", reason: nil)
    case .moduleCancelled(let module):
      emitRepeatEnded(module: module, outcome: "CANCELLED", reason: nil)
    case .moduleFailed(let module, let code, let description):
      emitRepeatEnded(module: module, outcome: "FAILED", reason: "\(code.rawValue): \(description)")
    case .nfcProgress(let percent):
      // The SDK ships no NFC UI for the chip read; the value is passed through as reported
      // (0...99, repeats already filtered, never 100: completion is moduleCompleted(.nfc)).
      emitOnMain("onNfcProgress", ["percent": percent])
    default:
      // Signals, capabilities, per-module progress and screen-share lifecycle are diagnostic;
      // surfacing one is a public API decision, not a local change.
      break
    }
  }

  private func emitRepeatEnded(module: VCLiveKYCModule, outcome: String, reason: String?) {
    var payload: [String: Any] = ["role": module.rawValue.uppercased(), "outcome": outcome]
    if let reason = reason { payload["reason"] = reason }
    emitOnMain("onRepeatEnded", payload)
  }

  private func emitOnMain(_ method: String, _ arguments: [String: Any]) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod(method, arguments: arguments)
    }
  }

  public func onScreenLocked() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onScreenLocked", arguments: nil)
    }
  }

  public func onScreenUnlocked() {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onScreenUnlocked", arguments: nil)
    }
  }

  func onMicrophoneStateChanged(_ enabled: Bool) {
    DispatchQueue.main.async {
      self.channel?.invokeMethod("onMicrophoneStateChanged", arguments: ["enabled": enabled])
    }
  }
}
#endif
