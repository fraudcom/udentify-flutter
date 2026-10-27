import UIKit
import Flutter

/// Finds where a plugin should present a native screen from.
///
/// A Flutter app's root view controller is usually the `FlutterViewController`, but anything may already be
/// presented above it (another plugin's modal, an earlier call screen, an alert) and `present(_:animated:)`
/// from a view controller that is already presenting does nothing. So the screen is presented from the
/// view controller that is actually on top, found from the window that holds the Flutter UI (the key window
/// when it does), through the foreground scene.
public enum UdentifyPresenter {

    /// The view controller currently on top of the app, or nil when there is no window yet.
    public static func topViewController() -> UIViewController? {
        return top(from: keyWindow()?.rootViewController)
    }

    /// Follows presented controllers, navigation stacks and tab bars down to the one on screen.
    public static func top(from root: UIViewController?) -> UIViewController? {
        guard var controller = root else { return nil }
        while true {
            if let presented = controller.presentedViewController, !presented.isBeingDismissed {
                controller = presented
            } else if let navigation = controller as? UINavigationController,
                      let visible = navigation.visibleViewController, visible !== navigation {
                controller = visible
            } else if let tabs = controller as? UITabBarController,
                      let selected = tabs.selectedViewController {
                controller = selected
            } else {
                return controller
            }
        }
    }

    /// The window holding the app's Flutter UI. Apps can have more than one window (a debug overlay, an
    /// alert window, a sign-in sheet's window) and any of them may be the key window, so the key window
    /// is only the answer when no window holds a `FlutterViewController`.
    private static func keyWindow() -> UIWindow? {
        let candidates: [UIWindow]
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            // The scene the user is looking at first; an app with several scenes may have others in the background.
            let active = scenes.filter { $0.activationState == .foregroundActive }
            candidates = (active.isEmpty ? scenes : active).flatMap { $0.windows }
        } else {
            candidates = UIApplication.shared.windows
        }
        let visible = candidates.filter { !$0.isHidden }
        if let flutter = visible.first(where: { $0.isKeyWindow && hostsFlutter($0.rootViewController) })
            ?? visible.first(where: { hostsFlutter($0.rootViewController) }) {
            return flutter
        }
        return visible.first(where: { $0.isKeyWindow }) ?? visible.first
    }

    /// Whether `controller` or anything it contains or presents is a `FlutterViewController`.
    private static func hostsFlutter(_ controller: UIViewController?, depth: Int = 0) -> Bool {
        guard let controller = controller, depth < 8 else { return false }
        if controller is FlutterViewController { return true }
        if hostsFlutter(controller.presentedViewController, depth: depth + 1) { return true }
        return controller.children.contains { hostsFlutter($0, depth: depth + 1) }
    }
}
