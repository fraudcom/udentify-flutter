import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CallOverlay") {
      CallOverlay.shared.attach(messenger: registrar.messenger())
    }
  }
}

/// The app's own end-call button, drawn over the Udentify call screen.
///
/// The SDKs have no end-call button, only methods to end a call, and a Dart widget cannot draw over the native
/// call screen, so the app owns a small native button and drives it from Dart through the
/// `fraud_test/call_overlay` channel (`show`, `hide`; the tap comes back as `onPressed`).
///
/// It lives in a window of its own, one level above the app's, rather than inside the SDK's view hierarchy:
/// the call screen is presented by the SDK and its views are not ours to depend on, a separate window is never
/// covered by anything the SDK adds, and it goes away without touching the SDK's controller. The window passes
/// every touch outside the button through to the call screen, and never becomes the key window.
final class CallOverlay {
  static let shared = CallOverlay()

  private var channel: FlutterMethodChannel?
  private var window: PassthroughWindow?

  func attach(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "fraud_test/call_overlay", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "show": self?.show(); result(nil)
      case "hide": self?.hide(); result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    self.channel = channel
  }

  private func show() {
    guard window == nil else { return }
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else { return }

    let overlay = PassthroughWindow(windowScene: scene)
    overlay.windowLevel = UIWindow.Level.normal + 1
    overlay.backgroundColor = .clear
    overlay.rootViewController = CallOverlayViewController { [weak self] in
      self?.channel?.invokeMethod("onPressed", arguments: nil)
    }
    overlay.isHidden = false // visible, but deliberately not makeKeyAndVisible()
    window = overlay
  }

  private func hide() {
    window?.isHidden = true
    window = nil
  }
}

/// A window that only answers touches that land on its button.
final class PassthroughWindow: UIWindow {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    let hit = super.hitTest(point, with: event)
    return hit === rootViewController?.view ? nil : hit
  }
}

final class CallOverlayViewController: UIViewController {
  private let onTap: () -> Void

  init(onTap: @escaping () -> Void) {
    self.onTap = onTap
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    let size: CGFloat = 50
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = UIColor(red: 0.8, green: 0, blue: 0, alpha: 1)
    button.tintColor = .white
    button.layer.cornerRadius = size / 2
    // The glyph is half the button, like the SDK's own controls.
    button.setImage(Self.handset(side: size / 2).withRenderingMode(.alwaysTemplate), for: .normal)
    button.accessibilityLabel = "End call"
    button.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    view.addSubview(button)

    // 16pt in from the top right of the safe area.
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: size),
      button.heightAnchor.constraint(equalToConstant: size),
      button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
    ])
  }

  @objc private func tapped() { onTap() }

  /// A handset set down on its cradle, drawn in a 24-unit box.
  private static func handset(side: CGFloat) -> UIImage {
    let unit = side / 24
    return UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { _ in
      UIColor.white.setStroke()
      UIColor.white.setFill()
      let arc = UIBezierPath()
      arc.move(to: CGPoint(x: 4 * unit, y: 12.5 * unit))
      arc.addCurve(
        to: CGPoint(x: 20 * unit, y: 12.5 * unit),
        controlPoint1: CGPoint(x: 4 * unit, y: 4.5 * unit),
        controlPoint2: CGPoint(x: 20 * unit, y: 4.5 * unit))
      arc.lineWidth = 4.5 * unit
      arc.lineCapStyle = .round
      arc.stroke()
      UIBezierPath(
        roundedRect: CGRect(x: 3 * unit, y: 17 * unit, width: 18 * unit, height: 3 * unit),
        cornerRadius: 1.5 * unit).fill()
    }
  }
}
