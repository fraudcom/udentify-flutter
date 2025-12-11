import Flutter
import UIKit
import AVFoundation
import UdentifyCommons

// Import UdentifyFACE framework if available
#if canImport(UdentifyFACE)
import UdentifyFACE
#endif

#if canImport(UdentifyFACE)
class LocalizationManager {
  static let shared = LocalizationManager()
  
  private var currentLanguage: String = "en"
  private var customStrings: [String: String] = [:]
  
  private init() {}
  
  func setLanguage(_ languageCode: String) {
    self.currentLanguage = languageCode
  }
  
  func setCustomStrings(_ strings: [String: String]) {
    self.customStrings = strings
  }
  
  func localizedString(for key: String, defaultValue: String = "") -> String {
    // First check custom strings
    if let customValue = customStrings[key] {
      return customValue
    }
    
    // Then check plugin bundle localization
    let pluginBundle = Bundle(for: LivenessFlutterPlugin.self)
    if let path = pluginBundle.path(forResource: currentLanguage, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      let localizedValue = NSLocalizedString(key, tableName: nil, bundle: bundle, value: defaultValue, comment: "")
      if localizedValue != key {
        return localizedValue
      }
    }
    
    // Fallback to main bundle
    if let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
       let bundle = Bundle(path: path) {
      let localizedValue = NSLocalizedString(key, tableName: nil, bundle: bundle, value: defaultValue, comment: "")
      if localizedValue != key {
        return localizedValue
      }
    }
    
    // Fallback to English or default value
    return NSLocalizedString(key, value: defaultValue, comment: "")
  }
}

// MARK: - Custom Settings Implementation
struct FlutterApiSettings: ApiSettings {
  var colors: ApiColors
  var fonts: ApiFonts
  var configs: ApiConfigs
  
  init(from arguments: [String: Any]) {
    // Extract colors configuration
    let colorsDict = arguments["colors"] as? [String: Any] ?? [:]
    self.colors = ApiColors(
      titleColor: UIColor.fromHex(colorsDict["titleColor"] as? String) ?? .white,
      titleBG: UIColor.fromHex(colorsDict["titleBG"] as? String) ?? .white.withAlphaComponent(0.476),
      errorColor: UIColor.fromHex(colorsDict["buttonErrorColor"] as? String) ?? UIColor(red: 1, green: 0.302, blue: 0.188, alpha: 1),
      successColor: UIColor.fromHex(colorsDict["buttonSuccessColor"] as? String) ?? UIColor(red: 0.302, green: 0.851, blue: 0.388, alpha: 1),
      buttonColor: UIColor.fromHex(colorsDict["buttonColor"] as? String) ?? UIColor(red: 0.223, green: 0.344, blue: 0.891, alpha: 1),
      buttonTextColor: UIColor.fromHex(colorsDict["buttonTextColor"] as? String) ?? .white,
      buttonErrorTextColor: UIColor.fromHex(colorsDict["buttonErrorTextColor"] as? String) ?? .white,
      buttonSuccessTextColor: UIColor.fromHex(colorsDict["buttonSuccessTextColor"] as? String) ?? .white,
      buttonBackColor: UIColor.fromHex(colorsDict["buttonBackColor"] as? String) ?? .white,
      footerTextColor: UIColor.fromHex(colorsDict["footerTextColor"] as? String) ?? .white,
      checkmarkTintColor: UIColor.fromHex(colorsDict["checkmarkTintColor"] as? String) ?? .white,
      backgroundColor: UIColor.fromHex(colorsDict["backgroundColor"] as? String) ?? UIColor(red: 0.518, green: 0.306, blue: 0.890, alpha: 1)
    )
    
    // Extract fonts configuration
    let fontsDict = arguments["fonts"] as? [String: Any] ?? [:]
    self.fonts = ApiFonts(
      titleFont: UIFont.fromDict(fontsDict["titleFont"] as? [String: Any]) ?? UIFont.boldSystemFont(ofSize: 24),
      buttonFont: UIFont.fromDict(fontsDict["buttonFont"] as? [String: Any]) ?? UIFont.systemFont(ofSize: 16),
      footerFont: UIFont.fromDict(fontsDict["footerFont"] as? [String: Any]) ?? UIFont.systemFont(ofSize: 14)
    )
    
    // Extract dimensions configuration
    let dimensionsDict = arguments["dimensions"] as? [String: Any] ?? [:]
    
    // Extract configs
    let configsDict = arguments["configs"] as? [String: Any] ?? [:]
    let progressBarDict = configsDict["progressBarStyle"] as? [String: Any] ?? [:]
    
    self.configs = ApiConfigs(
      cameraPosition: (configsDict["cameraPosition"] as? String == "back") ? .back : .front,
      requestTimeout: configsDict["requestTimeout"] as? TimeInterval ?? 15,
      autoTake: configsDict["autoTake"] as? Bool ?? true,
      errorDelay: configsDict["errorDelay"] as? Double ?? 0.25,
      successDelay: configsDict["successDelay"] as? Double ?? 0.75,
      bundle: Bundle(for: LivenessFlutterPlugin.self),
      tableName: configsDict["tableName"] as? String,
      maskDetection: configsDict["maskDetection"] as? Bool ?? false,
      maskConfidence: Float(configsDict["maskConfidence"] as? Double ?? 0.95),
      invertedAnimation: configsDict["invertedAnimation"] as? Bool ?? false,
      backButtonEnabled: configsDict["backButtonEnabled"] as? Bool ?? true,
      multipleFacesRejected: configsDict["multipleFacesRejected"] as? Bool ?? true,
      buttonHeight: dimensionsDict["buttonHeight"] as? CGFloat ?? configsDict["buttonHeight"] as? CGFloat ?? 48,
      buttonMarginLeft: dimensionsDict["buttonMarginLeft"] as? CGFloat ?? configsDict["buttonMarginLeft"] as? CGFloat ?? 50,
      buttonMarginRight: dimensionsDict["buttonMarginRight"] as? CGFloat ?? configsDict["buttonMarginRight"] as? CGFloat ?? 50,
      buttonCornerRadius: dimensionsDict["buttonCornerRadius"] as? CGFloat ?? configsDict["buttonCornerRadius"] as? CGFloat ?? 24,
      progressBarStyle: UdentifyProgressBarStyle.fromDict(progressBarDict)
    )
  }
}

// MARK: - UIColor Extension
extension UIColor {
  static func fromHex(_ hex: String?) -> UIColor? {
    guard let hex = hex else { return nil }
    var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexString = hexString.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    Scanner(string: hexString).scanHexInt64(&rgb)
    
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
    
    if hexString.count == 8 {
      // 8-digit hex (AARRGGBB)
      alpha = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
      red = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
      green = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
      blue = CGFloat(rgb & 0x000000FF) / 255.0
    } else {
      // 6-digit hex (RRGGBB)
      red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      blue = CGFloat(rgb & 0x0000FF) / 255.0
      alpha = 1.0
    }
    
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }
}

// MARK: - UIFont Extension
extension UIFont {
  static func fromDict(_ dict: [String: Any]?) -> UIFont? {
    guard let dict = dict,
          let name = dict["name"] as? String,
          let size = dict["size"] as? CGFloat else { return nil }
    
    if let font = UIFont(name: name, size: size) {
      return font
    }
    
    // Fallback to system font
    return UIFont.systemFont(ofSize: size)
  }
}

// MARK: - UdentifyProgressBarStyle Extension
extension UdentifyProgressBarStyle {
  static func fromDict(_ dict: [String: Any]) -> UdentifyProgressBarStyle {
    let textStyleDict = dict["textStyle"] as? [String: Any] ?? [:]
    
    return UdentifyProgressBarStyle(
      backgroundColor: UIColor.fromHex(dict["backgroundColor"] as? String) ?? .lightGray.withAlphaComponent(0.5),
      progressColor: UIColor.fromHex(dict["progressColor"] as? String) ?? .gray,
      completionColor: UIColor.fromHex(dict["completionColor"] as? String) ?? .green,
      textStyle: UdentifyTextStyle.fromDict(textStyleDict),
      cornerRadius: dict["cornerRadius"] as? CGFloat ?? 8
    )
  }
}

// MARK: - UdentifyTextStyle Extension
extension UdentifyTextStyle {
  static func fromDict(_ dict: [String: Any]) -> UdentifyTextStyle {
    let font = UIFont.fromDict(dict["font"] as? [String: Any]) ?? .boldSystemFont(ofSize: 24)
    let textColor = UIColor.fromHex(dict["textColor"] as? String) ?? .white
    
    var textAlignment: NSTextAlignment = .center
    if let alignmentString = dict["textAlignment"] as? String {
      switch alignmentString {
      case "left": textAlignment = .left
      case "right": textAlignment = .right
      case "center": textAlignment = .center
      case "justified": textAlignment = .justified
      case "natural": textAlignment = .natural
      default: textAlignment = .center
      }
    }
    
    var lineBreakMode: NSLineBreakMode = .byWordWrapping
    if let lineBreakString = dict["lineBreakMode"] as? String {
      switch lineBreakString {
      case "byWordWrapping": lineBreakMode = .byWordWrapping
      case "byTruncatingTail": lineBreakMode = .byTruncatingTail
      case "byTruncatingHead": lineBreakMode = .byTruncatingHead
      case "byClipping": lineBreakMode = .byClipping
      default: lineBreakMode = .byWordWrapping
      }
    }
    
    return UdentifyTextStyle(
      font: font,
      textColor: textColor,
      textAlignment: textAlignment,
      lineBreakMode: lineBreakMode,
      numberOfLines: dict["numberOfLines"] as? Int ?? 0,
      leading: dict["leading"] as? CGFloat ?? 20,
      trailing: dict["trailing"] as? CGFloat ?? 20
    )
  }
}
#endif

public class LivenessFlutterPlugin: NSObject, FlutterPlugin {
  private var channel: FlutterMethodChannel?
  private var currentViewController: UIViewController?
  private var currentIDCameraController: IDCameraController? // For API calls with captured images
  private var isInProgress = false
  
  public override init() {
    super.init()
    setupDefaultSettings()
  }
  
  private func setupDefaultSettings() {
#if canImport(UdentifyFACE)
    let defaultSettings = FlutterApiSettings(from: [:])
    ApiSettingsProvider.getInstance().currentSettings = defaultSettings
#endif
  }
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "liveness_flutter", binaryMessenger: registrar.messenger())
    let instance = LivenessFlutterPlugin()
    instance.channel = channel
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    
    switch method {
    case "checkPermissions":
      checkPermissions(result: result)
    case "requestPermissions":
      requestPermissions(result: result)
    case "startFaceRecognitionRegistration":
      startFaceRecognitionRegistration(call: call, result: result)
    case "startFaceRecognitionAuthentication":
      startFaceRecognitionAuthentication(call: call, result: result)
    case "startActiveLiveness":
      startActiveLiveness(call: call, result: result)
    case "startHybridLiveness":
      startHybridLiveness(call: call, result: result)
    case "registerUserWithPhoto":
      registerUserWithPhoto(call: call, result: result)
    case "authenticateUserWithPhoto":
      authenticateUserWithPhoto(call: call, result: result)
    case "startSelfieCapture":
      startSelfieCapture(call: call, result: result)
    case "performFaceRecognitionWithSelfie":
      performFaceRecognitionWithSelfie(call: call, result: result)
    case "cancelFaceRecognition":
      cancelFaceRecognition(result: result)
    case "isFaceRecognitionInProgress":
      isFaceRecognitionInProgress(result: result)
    case "addUserToList":
      addUserToList(call: call, result: result)
    case "startFaceRecognitionIdentification":
      startFaceRecognitionIdentification(call: call, result: result)
    case "deleteUserFromList":
      deleteUserFromList(call: call, result: result)
    case "configureUISettings":
      configureUISettings(call: call, result: result)
    case "setLocalization":
      setLocalization(call: call, result: result)
    default:
      result(FlutterError(code: "UNIMPLEMENTED", 
                         message: "Method not implemented: \(method)", 
                         details: nil))
    }
  }
  
  private func checkPermissions(result: @escaping FlutterResult) {
    // Check camera permission status
    let cameraStatus = getCameraPermissionStatus()
    
    let permissions = [
      "camera": cameraStatus,
      "readPhoneState": "granted", // Not applicable on iOS
      "internet": "granted" // Not applicable on iOS
    ]
    
    result(permissions)
  }
  
  private func requestPermissions(result: @escaping FlutterResult) {
    // Request camera permission
    requestCameraPermission { [weak self] in
      self?.checkPermissions(result: result)
    }
  }
  
  private func startFaceRecognitionRegistration(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard !isInProgress else {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "Face recognition is already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID", details: nil))
      return
    }
    
    let userId = arguments["userID"] as? String
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .registration,
        transactionID: transactionId,
        userID: userId,
        listName: nil,
        logLevel: logLevel
      ) { [weak self] controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize face recognition: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        controller.delegate = self
        self?.currentViewController = controller
        self?.isInProgress = true
        rootViewController.present(controller, animated: true)
        
        result([
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Face recognition registration started"
          ]
        ])
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func startFaceRecognitionAuthentication(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard !isInProgress else {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "Face recognition is already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID", details: nil))
      return
    }
    
    let userId = arguments["userID"] as? String
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .authentication,
        transactionID: transactionId,
        userID: userId,
        listName: nil,
        logLevel: logLevel
      ) { [weak self] controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize face recognition: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        controller.delegate = self
        self?.currentViewController = controller
        self?.isInProgress = true
        rootViewController.present(controller, animated: true)
        
        result([
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Face recognition authentication started"
          ]
        ])
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func startActiveLiveness(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard !isInProgress else {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "Active liveness is already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let userId = arguments["userID"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, userID", details: nil))
      return
    }
    
    let isAuthentication = arguments["isAuthentication"] as? Bool ?? false
    let hybridLivenessEnabled = arguments["hybridLivenessEnabled"] as? Bool ?? false
    let autoNextEnabled = arguments["autoNextEnabled"] as? Bool ?? true
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // Debug logging for troubleshooting
      print("🔧 ActiveCameraController.instantiate called with:")
      print("   serverURL: '\(serverURL)'")
      print("   transactionID: '\(transactionId)'") 
      print("   userID: '\(userId)'")
      print("   isAuthentication: \(isAuthentication)")
      print("   hybridLivenessEnabled: \(hybridLivenessEnabled)")
      print("   autoNextEnabled: \(autoNextEnabled)")
      print("   logLevel: \(logLevel)")
      
      ActiveCameraController.instantiate(
        serverURL: serverURL,
        method: isAuthentication ? .authentication : .registration,
        transactionID: transactionId,
        userID: userId,
        hybridLivenessEnabled: hybridLivenessEnabled,
        autoNextEnabled: autoNextEnabled,
        logLevel: logLevel
      ) { [weak self] controller, error in
        if let error = error {
          print("❌ ActiveCameraController instantiation failed:")
          print("   Error: \(error)")
          print("   LocalizedDescription: \(error.localizedDescription)")
          print("   Error type: \(type(of: error))")
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize active liveness: \(error.localizedDescription)", details: ["serverURL": serverURL, "transactionID": transactionId, "userID": userId, "error": "\(error)"]))
          return
        }
        
        guard let controller = controller,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        print("🔧 Setting ActiveCameraController delegate to self")
        controller.delegate = self
        self?.currentViewController = controller
        self?.isInProgress = true
        print("🚀 Presenting ActiveCameraController")
        rootViewController.present(controller, animated: true)
        
        result([
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Active liveness started"
          ]
        ])
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func startHybridLiveness(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard !isInProgress else {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "Hybrid liveness is already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let userId = arguments["userID"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, userID", details: nil))
      return
    }
    
    let isAuthentication = arguments["isAuthentication"] as? Bool ?? false
    let autoNextEnabled = arguments["autoNextEnabled"] as? Bool ?? true
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      // Debug logging for troubleshooting
      print("🔧 Hybrid Liveness ActiveCameraController.instantiate called with:")
      print("   serverURL: '\(serverURL)'")
      print("   transactionID: '\(transactionId)'") 
      print("   userID: '\(userId)'")
      print("   isAuthentication: \(isAuthentication)")
      print("   autoNextEnabled: \(autoNextEnabled)")
      print("   logLevel: \(logLevel)")
      
      // Use ActiveCameraController with hybrid liveness enabled
      ActiveCameraController.instantiate(
        serverURL: serverURL,
        method: isAuthentication ? .authentication : .registration,
        transactionID: transactionId,
        userID: userId,
        hybridLivenessEnabled: true, // This enables hybrid liveness
        autoNextEnabled: autoNextEnabled,
        logLevel: logLevel
      ) { [weak self] controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize hybrid liveness: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        controller.delegate = self
        self?.currentViewController = controller
        self?.isInProgress = true
        rootViewController.present(controller, animated: true)
        
        result([
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Hybrid liveness started"
          ]
        ])
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func registerUserWithPhoto(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let photoBase64 = arguments["photo"] as? String,
          let photoData = Data(base64Encoded: photoBase64),
          let photo = UIImage(data: photoData) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, photo", details: nil))
      return
    }
    
    let userId = arguments["userID"] as? String
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .registration,
        transactionID: transactionId,
        userID: userId,
        listName: nil,
        logLevel: logLevel
      ) { controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize face recognition: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller else {
          result(FlutterError(code: "CONTROLLER_CREATION_FAILED", message: "Could not create camera controller", details: nil))
          return
        }
        
        // Use the photo-based registration method
        controller.register(forImage: photo) { response in
          DispatchQueue.main.async {
            let resultMap: [String: Any] = [
              "status": response.error == nil ? "success" : "failure",
              "result": [
                "verified": response.verified,
                "matchScore": response.matchScore,
                "transactionID": response.transactionID ?? "",
                "userID": response.userID ?? "",
                "error": response.error?.localizedDescription
              ]
            ]
            result(resultMap)
          }
        }
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func authenticateUserWithPhoto(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let photoBase64 = arguments["photo"] as? String,
          let photoData = Data(base64Encoded: photoBase64),
          let photo = UIImage(data: photoData) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, photo", details: nil))
      return
    }
    
    let userId = arguments["userID"] as? String
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .authentication,
        transactionID: transactionId,
        userID: userId,
        listName: nil,
        logLevel: logLevel
      ) { controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize face recognition: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller else {
          result(FlutterError(code: "CONTROLLER_CREATION_FAILED", message: "Could not create camera controller", details: nil))
          return
        }
        
        // Use the photo-based authentication method
        controller.authenticate(forImage: photo) { response in
          DispatchQueue.main.async {
            let resultMap: [String: Any] = [
              "status": response.error == nil ? "success" : "failure",
              "result": [
                "verified": response.verified,
                "matchScore": response.matchScore,
                "transactionID": response.transactionID ?? "",
                "userID": response.userID ?? "",
                "error": response.error?.localizedDescription
              ]
            ]
            result(resultMap)
          }
        }
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }

  
  private func startSelfieCapture(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    NSLog("LivenessFlutterPlugin - 🔄 Starting selfie capture")
    
    guard !isInProgress else {
      result(FlutterError(code: "OPERATION_IN_PROGRESS", message: "Face recognition operation already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionID = arguments["transactionID"] as? String,
          let userID = arguments["userID"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, userID", details: nil))
      return
    }
    
    DispatchQueue.main.async { [weak self] in
      self?.isInProgress = true
      
      // Create IDCameraController for selfie capture using .selfie method
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .selfie,
        transactionID: transactionID,
        userID: userID,
        listName: nil,
        logLevel: .warning
      ) { controller, error in
        if let error = error {
          self?.isInProgress = false
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize selfie capture: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller else {
          self?.isInProgress = false
          result(FlutterError(code: "CONTROLLER_CREATION_FAILED", message: "Could not create camera controller for selfie capture", details: nil))
          return
        }
        
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          self?.isInProgress = false
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        controller.delegate = self
        self?.currentViewController = controller
        rootViewController.present(controller, animated: true)
        
        let resultMap: [String: Any] = [
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Selfie capture started"
          ]
        ]
        result(resultMap)
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }

  private func performFaceRecognitionWithSelfie(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    NSLog("LivenessFlutterPlugin - 🔄 Performing face recognition with selfie")
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionID = arguments["transactionID"] as? String,
          let userID = arguments["userID"] as? String,
          let base64Image = arguments["base64Image"] as? String,
          let isAuthentication = arguments["isAuthentication"] as? Bool else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, userID, base64Image, isAuthentication", details: nil))
      return
    }
    
    // Convert base64 image to UIImage
    guard let imageData = Data(base64Encoded: base64Image),
          let image = UIImage(data: imageData) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Failed to decode base64 image", details: nil))
      return
    }
    
    NSLog("LivenessFlutterPlugin - ✅ Processing selfie with Face Recognition API (isAuth: \(isAuthentication))")
    
    DispatchQueue.main.async { [weak self] in
      NSLog("LivenessFlutterPlugin - ✅ Processing selfie with Face Recognition API")
      
      let logLevel = UdentifyCommons.LogLevel.warning
      let method: MethodType = isAuthentication ? .authentication : .registration
      
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: method,
        transactionID: transactionID,
        userID: userID,
        listName: nil,
        logLevel: logLevel
      ) { [weak self] controller, error in
        guard let self = self else { 
          result(FlutterError(code: "WEAK_SELF", message: "LivenessFlutterPlugin was deallocated", details: nil))
          return 
        }
        
        if let error = error {
          NSLog("LivenessFlutterPlugin - ❌ Failed to initialize controller: \(error.localizedDescription)")
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize face recognition: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller else {
          NSLog("LivenessFlutterPlugin - ❌ Controller is nil")
          result(FlutterError(code: "NO_CONTROLLER", message: "Could not create face recognition controller", details: nil))
          return
        }
        
        NSLog("LivenessFlutterPlugin - 🎯 Controller created successfully, calling performFaceIDandLiveness")
        
        self.currentIDCameraController = controller
        
        controller.performFaceIDandLiveness(image: image, methodType: method) { faceIDResult, livenessResult in
          DispatchQueue.main.async {
            NSLog("LivenessFlutterPlugin - 📋 performFaceIDandLiveness completed")
            NSLog("LivenessFlutterPlugin - 📊 FaceIDResult: \(faceIDResult?.description ?? "nil")")
            NSLog("LivenessFlutterPlugin - 📊 LivenessResult: \(livenessResult?.assessmentValue ?? 0.0)")
            
            self.currentIDCameraController = nil
            
            if faceIDResult == nil && livenessResult == nil {
              NSLog("LivenessFlutterPlugin - ❌ Both results are nil - this indicates an API call failure")
              result(FlutterError(code: "API_CALL_FAILED", message: "Both faceIDResult and livenessResult are nil", details: nil))
              return
            }
            
            self.currentIDCameraController = nil
            
            var isFailed = false
            if faceIDResult == nil || faceIDResult?.error != nil || faceIDResult?.verified == false {
              isFailed = true
            } else if livenessResult == nil || livenessResult?.error != nil || livenessResult?.assessmentValue == nil {
              isFailed = true
            }
            
            let faceIDMessageDict = self.createFaceIDMessage(faceIDResult: faceIDResult, livenessResult: livenessResult)
            
            let responseResult: [String: Any] = [
              "status": isFailed ? "failure" : "success",
              "faceIDMessage": faceIDMessageDict
            ]
            
            self.channel?.invokeMethod("onResult", arguments: responseResult)
            result(responseResult)
          }
        }
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func addUserToList(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let listName = arguments["listName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, listName", details: nil))
      return
    }
    
    // Extract metadata if provided
    let metadata = arguments["metadata"] as? [String: Any]
    
    DispatchQueue.main.async {
      IDCameraController.addUserToList(
        serverUrl: serverURL,
        transactionId: transactionId,
        listName: listName,
        metadata: metadata
      ) { response, error in
        DispatchQueue.main.async {
          if let error = error {
            result(FlutterError(code: "ADD_USER_FAILED", message: error.localizedDescription, details: nil))
          } else {
            result([
              "status": "success", 
              "message": "User added successfully",
              "response": response != nil ? ["data": "User added to list"] : nil
            ])
          }
        }
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func startFaceRecognitionIdentification(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard !isInProgress else {
      result(FlutterError(code: "ALREADY_IN_PROGRESS", message: "Face recognition is already in progress", details: nil))
      return
    }
    
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let listName = arguments["listName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, listName", details: nil))
      return
    }
    
    let logLevel = convertLogLevel(arguments["logLevel"] as? String ?? "warning")
    
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      IDCameraController.instantiate(
        serverURL: serverURL,
        method: .identification,
        transactionID: transactionId,
        userID: nil,
        listName: listName,
        logLevel: logLevel
      ) { [weak self] controller, error in
        if let error = error {
          result(FlutterError(code: "INITIALIZATION_FAILED", message: "Failed to initialize identification: \(error.localizedDescription)", details: nil))
          return
        }
        
        guard let controller = controller,
              let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
          result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find root view controller", details: nil))
          return
        }
        
        controller.delegate = self
        self?.currentViewController = controller
        self?.isInProgress = true
        rootViewController.present(controller, animated: true)
        
        result([
          "status": "success",
          "faceIDMessage": [
            "success": true,
            "message": "Face identification started"
          ]
        ])
      }
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func deleteUserFromList(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any],
          let serverURL = arguments["serverURL"] as? String,
          let transactionId = arguments["transactionID"] as? String,
          let listName = arguments["listName"] as? String,
          let photoBase64 = arguments["photo"] as? String,
          let photoData = Data(base64Encoded: photoBase64),
          let photo = UIImage(data: photoData) else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments: serverURL, transactionID, listName, photo", details: nil))
      return
    }
    
    result(FlutterError(code: "METHOD_NOT_IMPLEMENTED", message: "deleteUserFromList method is not available in the UdentifyFACE iOS SDK", details: nil))
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func configureUISettings(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any] else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing UI settings arguments", details: nil))
      return
    }
    
    DispatchQueue.main.async {
      let customSettings = FlutterApiSettings(from: arguments)
      ApiSettingsProvider.getInstance().currentSettings = customSettings
      result(["status": "success", "message": "UI settings configured"])
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func setLocalization(call: FlutterMethodCall, result: @escaping FlutterResult) {
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
    guard let arguments = call.arguments as? [String: Any],
          let languageCode = arguments["languageCode"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing language code", details: nil))
      return
    }
    
    // Get custom strings if provided
    let customStrings = arguments["strings"] as? [String: String] ?? [:]
    
    DispatchQueue.main.async {
      // Apply localization settings
      LocalizationManager.shared.setLanguage(languageCode)
      LocalizationManager.shared.setCustomStrings(customStrings)
      
      result(["status": "success", "message": "Localization configured for language: \(languageCode)"])
    }
#else
    result(FlutterError(code: "FRAMEWORK_NOT_AVAILABLE", message: "UdentifyFACE framework not available. Please add UdentifyFACE.xcframework to ios/Frameworks/", details: nil))
#endif
  }
  
  private func cancelFaceRecognition(result: @escaping FlutterResult) {
    if isInProgress {
      isInProgress = false
      currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
    }
    result(nil)
  }
  
  private func isFaceRecognitionInProgress(result: @escaping FlutterResult) {
    result(isInProgress)
  }
  
  // MARK: - Helper Methods
  
#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
  private func convertLogLevel(_ levelString: String) -> UdentifyCommons.LogLevel {
    switch levelString.lowercased() {
    case "debug":
      return .debug
    case "info":
      return .info
    case "warning":
      return .warning
    case "error":
      return .error
    default:
      return .warning
    }
  }
  
  private func convertUdentifyAnyToSwift(_ udentifyAny: UdentifyCommons.UdentifyAny) -> Any {
    if let stringValue = udentifyAny as? String {
      return stringValue
    } else if let intValue = udentifyAny as? Int {
      return intValue
    } else if let doubleValue = udentifyAny as? Double {
      return doubleValue
    } else if let boolValue = udentifyAny as? Bool {
      return boolValue
    } else if let arrayValue = udentifyAny as? [Any] {
      return arrayValue.map { item in
        if let udentifyAnyItem = item as? UdentifyCommons.UdentifyAny {
          return convertUdentifyAnyToSwift(udentifyAnyItem)
        }
        return item
      }
    } else if let dictValue = udentifyAny as? [String: Any] {
      var convertedDict: [String: Any] = [:]
      for (key, value) in dictValue {
        if let udentifyAnyValue = value as? UdentifyCommons.UdentifyAny {
          convertedDict[key] = convertUdentifyAnyToSwift(udentifyAnyValue)
        } else {
          convertedDict[key] = value
        }
      }
      return convertedDict
    } else {
      return String(describing: udentifyAny)
    }
  }
  
  private func methodTypeToString(_ methodType: MethodType?) -> String {
    guard let methodType = methodType else { return "" }
    switch methodType {
    case .registration:
      return "registration"
    case .authentication:
      return "authentication"
    case .imageUpload:
      return "imageUpload"
    case .selfie:
      return "selfie"
    case .identification:
      return "identification"
    @unknown default:
      return "unknown"
    }
  }
#endif
  
  // MARK: - Helper Methods for Raw Server Response (like Android)
  
  private func createRawServerResponse(faceIDResult: FaceIDResult?, livenessResult: LivenessResult?) -> [String: Any] {
    var rawData: [String: Any] = [:]
    
    // Extract all fields from FaceIDResult using reflection (like Android)
    if let faceIDResult = faceIDResult {
      extractAllFields(from: faceIDResult, into: &rawData)
    }
    
    // Extract all fields from LivenessResult using reflection (like Android)
    if let livenessResult = livenessResult {
      extractAllFields(from: livenessResult, into: &rawData)
    }
    
    // Determine failure status based on actual data
    let isFailed = (faceIDResult?.error != nil || faceIDResult?.verified == false || 
                   livenessResult?.error != nil || livenessResult?.assessmentValue == nil)
    rawData["isFailed"] = isFailed
    
    return rawData
  }
  
  private func createRawActiveLivenessResponse(result: FaceIDMessage) -> [String: Any] {
    var rawData: [String: Any] = [:]
    
    // Extract all fields from FaceIDResult using reflection (like Android)
    if let faceIDResult = result.faceIDResult {
      extractAllFields(from: faceIDResult, into: &rawData)
    }
    
    // Extract all fields from LivenessResult using reflection (like Android)
    if let livenessResult = result.livenessResult {
      extractAllFields(from: livenessResult, into: &rawData)
    }
    
    // Extract all fields from ActiveLivenessResult using reflection (like Android)
    if let activeLivenessResult = result.activeLivenessResult {
      extractAllFields(from: activeLivenessResult, into: &rawData)
    }
    
    // Determine failure status based on actual data
    rawData["isFailed"] = result.isFailed
    
    return rawData
  }
  
  private func createRawFaceRecognitionResponse(faceIDResult: FaceIDResult?, livenessResult: LivenessResult?) -> [String: Any] {
    return createRawServerResponse(faceIDResult: faceIDResult, livenessResult: livenessResult)
  }
  
  // MARK: - Universal Field Extraction (like Android reflection)
  
  private func extractAllFields(from object: Any, into rawData: inout [String: Any]) {
    let mirror = Mirror(reflecting: object)
    
    print("🔍 Extracting all fields from \(type(of: object))")
    
    for child in mirror.children {
      guard let propertyName = child.label else { continue }
      let value = child.value
      
      print("📊 Found property: \(propertyName) = \(value)")
      
      // Handle different value types
      switch value {
      case let stringValue as String:
        rawData[propertyName] = stringValue
      case let numberValue as NSNumber:
        rawData[propertyName] = numberValue
      case let boolValue as Bool:
        rawData[propertyName] = boolValue
      case let doubleValue as Double:
        rawData[propertyName] = doubleValue
      case let floatValue as Float:
        rawData[propertyName] = floatValue
      case let intValue as Int:
        rawData[propertyName] = intValue
      case let imageValue as UIImage:
        // Convert UIImage to base64
        if let imageData = imageValue.jpegData(compressionQuality: 0.8) {
          rawData[propertyName] = imageData.base64EncodedString()
          rawData["\(propertyName)Base64"] = imageData.base64EncodedString()
        }
      case let errorValue as Error:
        rawData[propertyName] = errorValue.localizedDescription
        rawData["\(propertyName)Message"] = errorValue.localizedDescription
      case let dictValue as [String: Any]:
        // Handle dictionary values (like gestureResult)
        rawData[propertyName] = dictValue
        // Also add individual keys from dictionary
        for (key, dictVal) in dictValue {
          rawData[key] = dictVal
        }
      case let metadataValue as [String: UdentifyCommons.UdentifyAny?]:
        // Handle metadata (raw server response data)
        for (key, udentifyAny) in metadataValue {
          if let udentifyAny = udentifyAny {
            rawData[key] = convertUdentifyAnyToSwift(udentifyAny)
          }
        }
        rawData[propertyName] = metadataValue.compactMapValues { udentifyAny in
          udentifyAny != nil ? convertUdentifyAnyToSwift(udentifyAny!) : nil
        }
      case is NSNull:
        rawData[propertyName] = nil
      case Optional<Any>.none:
        rawData[propertyName] = nil
      default:
        // For any other type, convert to string
        rawData[propertyName] = String(describing: value)
      }
    }
    
    print("✅ Extracted \(mirror.children.count) fields from \(type(of: object))")
  }
  
  // MARK: - Helper Methods for Selfie Processing (Legacy - kept for compatibility)
  
  private func createFaceIDMessage(faceIDResult: FaceIDResult?, livenessResult: LivenessResult?) -> [String: Any] {
    var faceIDMessage: [String: Any] = [:]
    
    var isFailed = false
    
    // Process FaceIDResult
    if let faceIDResult = faceIDResult {
      var faceIDResultDict: [String: Any] = [
        "verified": faceIDResult.verified,
        "matchScore": faceIDResult.matchScore,
        "description": faceIDResult.description,
        "transactionID": faceIDResult.transactionID ?? "",
        "userID": faceIDResult.userID ?? "",
        "header": faceIDResult.header ?? "",
        "listNames": faceIDResult.listNames ?? "",
        "listIds": faceIDResult.listIds ?? "",
        "registrationTransactionID": faceIDResult.registrationTransactionID ?? "",
        "method": self.methodTypeToString(faceIDResult.method)
      ]
      
      if let error = faceIDResult.error {
        faceIDResultDict["error"] = [
          "code": "\(error)",
          "description": error.localizedDescription
        ]
        isFailed = true
      }
      
      if let referencePhoto = faceIDResult.referencePhoto {
        if let imageData = referencePhoto.jpegData(compressionQuality: 0.8) {
          faceIDResultDict["referencePhotoBase64"] = imageData.base64EncodedString()
        }
      }
      
      if let metadata = faceIDResult.metadata {
        var metadataDict: [String: Any] = [:]
        for (key, value) in metadata {
          if let udentifyAny = value {
            metadataDict[key] = convertUdentifyAnyToSwift(udentifyAny)
          }
        }
        faceIDResultDict["metadata"] = metadataDict
      }
      
      faceIDMessage["faceIDResult"] = faceIDResultDict
      
      if faceIDResult.error != nil || !faceIDResult.verified {
        isFailed = true
      }
    } else {
      isFailed = true
    }
    
    // Process LivenessResult
    if let livenessResult = livenessResult {
      var livenessResultDict: [String: Any] = [
        "assessmentValue": livenessResult.assessmentValue ?? 0.0,
        "assessmentDescription": livenessResult.assessmentDescription ?? "",
        "probability": livenessResult.probability ?? 0.0,
        "quality": livenessResult.quality ?? 0.0,
        "livenessScore": livenessResult.livenessScore ?? 0.0,
        "transactionID": livenessResult.transactionID ?? ""
      ]
      
      if let error = livenessResult.error {
        livenessResultDict["error"] = [
          "code": "\(error)",
          "description": error.localizedDescription
        ]
        isFailed = true
      }
      
      let assessment = livenessResult.assessment()
      livenessResultDict["assessment"] = assessment.description
      
      faceIDMessage["livenessResult"] = livenessResultDict
      
      if livenessResult.error != nil || livenessResult.assessmentValue == nil {
        isFailed = true
      }
    } else {
      isFailed = true
    }
    
    faceIDMessage["success"] = !isFailed
    faceIDMessage["isFailed"] = isFailed
    faceIDMessage["message"] = isFailed ? "Face recognition failed" : "Face recognition completed"
    
    return faceIDMessage
  }
  
  // MARK: - Camera Permission Methods
  
  private func getCameraPermissionStatus() -> String {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    switch status {
    case .authorized:
      return "granted"
    case .denied:
      return "denied"
    case .restricted:
      return "restricted"
    case .notDetermined:
      return "notDetermined"
    @unknown default:
      return "unknown"
    }
  }
  
  private func requestCameraPermission(completion: @escaping () -> Void) {
    AVCaptureDevice.requestAccess(for: .video) { _ in
      DispatchQueue.main.async {
        completion()
      }
    }
  }
}

#if canImport(UdentifyFACE) && canImport(UdentifyCommons)
extension LivenessFlutterPlugin: IDCameraControllerDelegate {
  public func cameraController(image: UIImage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      NSLog("LivenessFlutterPlugin - 📸 cameraController called with image")
      NSLog("LivenessFlutterPlugin - 🖼️ Image size: \(image.size)")
      
      self.isInProgress = false
      self.currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
      
      let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() ?? ""
      NSLog("LivenessFlutterPlugin - 📷 Base64 image length: \(base64Image.count)")
      
      let eventBody: [String: Any] = ["base64Image": base64Image]
      self.channel?.invokeMethod("onSelfieTaken", arguments: eventBody)
      
      NSLog("LivenessFlutterPlugin - ✅ onSelfieTaken event sent")
    }
  }
  
  public func cameraController(didEncounterError error: FaceError) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
      
      let errorMap: [String: Any] = [
        "code": "FACE_RECOGNITION_ERROR",
        "message": error.localizedDescription
      ]
      
      self.channel?.invokeMethod("onFailure", arguments: errorMap)
    }
  }
  
  public func cameraControllerDidFinishWithResult(viewMode: IDCameraController.ViewMode, result: FaceIDMessage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
      
      var faceIDResultMap: [String: Any] = [:]
      
      if let faceIDResult = result.faceIDResult {
        faceIDResultMap["verified"] = faceIDResult.verified
        faceIDResultMap["matchScore"] = faceIDResult.matchScore
        faceIDResultMap["transactionID"] = faceIDResult.transactionID ?? ""
        faceIDResultMap["userID"] = faceIDResult.userID ?? ""
        faceIDResultMap["method"] = methodTypeToString(faceIDResult.method)
        faceIDResultMap["header"] = faceIDResult.header ?? ""
        faceIDResultMap["description"] = faceIDResult.description ?? ""
        faceIDResultMap["listNames"] = faceIDResult.listNames ?? ""
        faceIDResultMap["listIds"] = faceIDResult.listIds ?? ""
        
        // Add identification-specific fields if available
        if let registrationTransactionID = faceIDResult.registrationTransactionID {
          faceIDResultMap["registrationTransactionID"] = registrationTransactionID
        }
        
        if let referencePhoto = faceIDResult.referencePhoto,
           let photoData = referencePhoto.jpegData(compressionQuality: 0.8) {
          faceIDResultMap["referencePhoto"] = photoData.base64EncodedString()
        }
        
        if let metadata = faceIDResult.metadata {
          var metadataMap: [String: Any] = [:]
          for (key, anyValue) in metadata {
            if let value = anyValue?.value {
              metadataMap[key] = value
            }
          }
          faceIDResultMap["metadata"] = metadataMap
        }
      }
      
      // Build liveness result dictionary separately
      var livenessResultDict: [String: Any]? = nil
      if let livenessResult = result.livenessResult {
        livenessResultDict = [
          "assessmentValue": livenessResult.assessmentValue ?? 0.0,
          "assessmentDescription": livenessResult.assessmentDescription ?? "",
          "probability": livenessResult.probability ?? 0.0,
          "quality": livenessResult.quality ?? 0.0,
          "livenessScore": livenessResult.livenessScore ?? 0.0,
          "transactionID": livenessResult.transactionID ?? ""
        ]
      }
      
      // Build face ID message dictionary
      let faceIDMessage: [String: Any] = [
        "success": !result.isFailed,
        "message": result.isFailed ? "Face recognition failed" : "Face recognition completed",
        "faceIDResult": faceIDResultMap.isEmpty ? nil : faceIDResultMap,
        "livenessResult": livenessResultDict
      ]
      
      // Create raw server response data (like Android)
      let rawResponseData = self.createRawFaceRecognitionResponse(faceIDResult: result.faceIDResult, livenessResult: result.livenessResult)
      
      self.channel?.invokeMethod("onResult", arguments: rawResponseData)
    }
  }
  
  public func cameraControllerUserPressedBackButton() {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onBackButtonPressed", arguments: nil)
    }
  }
  
  public func cameraControllerWillDismiss() {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onWillDismiss", arguments: nil)
    }
  }
  
  public func cameraControllerDidDismiss() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isInProgress = false
      self.currentViewController = nil
      self.channel?.invokeMethod("onDidDismiss", arguments: nil)
    }
  }
}

// MARK: - ActiveCameraController Delegate (Liveness)
extension LivenessFlutterPlugin: ActiveCameraControllerDelegate {
  public func onResult(result: FaceIDMessage) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
      
      // Debug logging for FaceIDMessage
      print("🎭 ========== iOS ACTIVE LIVENESS DELEGATE CALLED ==========")
      print("📊 FaceIDMessage.isFailed: \(result.isFailed)")
      print("📊 FaceIDMessage.faceIDResult: \(result.faceIDResult != nil ? "present" : "nil")")
      print("📊 FaceIDMessage.livenessResult: \(result.livenessResult != nil ? "present" : "nil")")
      print("📊 FaceIDMessage.activeLivenessResult: \(result.activeLivenessResult != nil ? "present" : "nil")")
      
      // Create comprehensive result map with ALL available data
      var faceIDMessageDict: [String: Any] = [
        "success": !result.isFailed,
        "message": result.isFailed ? "Active liveness failed" : "Active liveness completed",
        "isFailed": result.isFailed
      ]
      
      var resultMap: [String: Any] = [
        "status": result.isFailed ? "failure" : "success"
      ]
      
      // Add FaceIDResult if available (contains server response data)
      if let faceIDResult = result.faceIDResult {
        print("🔍 Processing FaceIDResult...")
        var faceIDResultDict: [String: Any] = [
          "verified": faceIDResult.verified,
          "matchScore": faceIDResult.matchScore,
          "transactionID": faceIDResult.transactionID ?? "",
          "userID": faceIDResult.userID ?? "",
          "method": methodTypeToString(faceIDResult.method),
          "header": faceIDResult.header ?? "",
          "description": faceIDResult.description ?? "",
          "listNames": faceIDResult.listNames ?? "",
          "listIds": faceIDResult.listIds ?? "",
          "registrationTransactionID": faceIDResult.registrationTransactionID ?? ""
        ]
        
        // Add error if present
        if let error = faceIDResult.error {
          faceIDResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        // Convert reference photo to base64 if present
        if let referencePhoto = faceIDResult.referencePhoto {
          if let imageData = referencePhoto.jpegData(compressionQuality: 0.8) {
            faceIDResultDict["referencePhotoBase64"] = imageData.base64EncodedString()
          }
        }
        
        // CRITICAL: Add raw server response from metadata
        if let metadata = faceIDResult.metadata {
          print("🌐 ========== RAW SERVER RESPONSE METADATA ==========")
          var metadataDict: [String: Any] = [:]
          for (key, value) in metadata {
            if let udentifyAny = value {
              let convertedValue = convertUdentifyAnyToSwift(udentifyAny)
              metadataDict[key] = convertedValue
              print("📊 Metadata[\(key)]: \(convertedValue)")
            }
          }
          faceIDResultDict["metadata"] = metadataDict
          faceIDResultDict["rawServerResponse"] = metadataDict
          print("✅ Raw server response captured in metadata")
          print("================================================")
        } else {
          print("⚠️ No metadata found in FaceIDResult")
        }
        
        faceIDMessageDict["faceIDResult"] = faceIDResultDict
      } else {
        print("⚠️ No FaceIDResult in response")
      }
      
      // Add LivenessResult if available (passive liveness data)
      if let livenessResult = result.livenessResult {
        print("🔍 Processing LivenessResult...")
        var livenessResultDict: [String: Any] = [
          "assessmentValue": livenessResult.assessmentValue ?? 0.0,
          "assessmentDescription": livenessResult.assessmentDescription ?? "",
          "probability": livenessResult.probability ?? 0.0,
          "quality": livenessResult.quality ?? 0.0,
          "livenessScore": livenessResult.livenessScore ?? 0.0,
          "transactionID": livenessResult.transactionID ?? ""
        ]
        
        // Add error if present
        if let error = livenessResult.error {
          livenessResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        // Add assessment result
        let assessment = livenessResult.assessment()
        livenessResultDict["assessment"] = assessment.description
        
        faceIDMessageDict["livenessResult"] = livenessResultDict
      } else {
        print("⚠️ No LivenessResult in response")
      }
      
      // Add ActiveLivenessResult if available (gesture results)
      if let activeLivenessResult = result.activeLivenessResult {
        print("🔍 Processing ActiveLivenessResult...")
        var activeLivenessResultDict: [String: Any] = [
          "transactionID": activeLivenessResult.transactionID ?? "",
          "gestureResult": activeLivenessResult.gestureResult ?? [:]
        ]
        
        // Add error if present
        if let error = activeLivenessResult.error {
          activeLivenessResultDict["error"] = [
            "code": "\(error)",
            "description": error.localizedDescription
          ]
        }
        
        // Log gesture results for debugging
        if let gestureResult = activeLivenessResult.gestureResult {
          print("🎭 Gesture Results:")
          for (gesture, success) in gestureResult {
            print("   \(gesture): \(success)")
          }
        }
        
        faceIDMessageDict["activeLivenessResult"] = activeLivenessResultDict
      } else {
        print("⚠️ No ActiveLivenessResult in response")
      }
      
      // Create raw server response data (like Android)
      let rawResponseData = self.createRawActiveLivenessResponse(result: result)
      
      // Debug final result being sent to Flutter
      print("📤 ========== SENDING RAW DATA TO FLUTTER ==========")
      print("📊 Raw response keys: \(rawResponseData.keys.sorted())")
      print("📋 Raw response data: \(rawResponseData)")
      print("====================================================")
      
      // Send raw response to Flutter (like Android)
      self.channel?.invokeMethod("onActiveLivenessResult", arguments: rawResponseData)
    }
  }
  
  public func onVideoTaken() {
    print("📹 iOS: onVideoTaken delegate called")
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onVideoTaken", arguments: nil)
    }
  }
  
  public func onFailure(error: Error) {
    print("❌ iOS: onFailure delegate called with error: \(error.localizedDescription)")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      
      self.isInProgress = false
      self.currentViewController?.dismiss(animated: true) {
        self.currentViewController = nil
      }
      
      let errorMap: [String: Any] = [
        "code": "ACTIVE_LIVENESS_ERROR",
        "message": error.localizedDescription
      ]
      
      self.channel?.invokeMethod("onActiveLivenessFailure", arguments: errorMap)
    }
  }
  
  public func backButtonPressed() {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onBackButtonPressed", arguments: nil)
    }
  }
  
  public func willDismiss() {
    DispatchQueue.main.async { [weak self] in
      self?.channel?.invokeMethod("onWillDismiss", arguments: nil)
    }
  }
  
  public func didDismiss() {
    print("✅ iOS: didDismiss delegate called")
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.isInProgress = false
      self.currentViewController = nil
      self.channel?.invokeMethod("onDidDismiss", arguments: nil)
    }
  }
}
#endif