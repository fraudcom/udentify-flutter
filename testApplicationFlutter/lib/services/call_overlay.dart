import 'package:flutter/services.dart';

/// The app's own end-call button, drawn natively over the SDK's call screen.
///
/// The SDKs have no end-call button; they only expose a way to end a call (`cancelVideoCall`,
/// `endVideoCall`). A Dart widget cannot draw over the separate native call screen, so a Flutter app that
/// wants a button adds a small native overlay of its own and drives it from Dart, as this does. The native
/// side lives in the app (`MainActivity.kt`, `AppDelegate.swift`), not in a plugin. See "Adding your own
/// end-call button" in the video-call plugin's `USAGE.md`.
class CallOverlay {
  CallOverlay._();

  static const _channel = MethodChannel('fraud_test/call_overlay');

  /// Called when the button is tapped. What ending the call means is up to the app.
  static void setOnPressed(void Function() onPressed) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onPressed') onPressed();
    });
  }

  /// Shows the button above the call screen. Idempotent.
  static Future<void> show() => _invoke('show');

  /// Removes it. Idempotent, so every place a call can end may call it.
  static Future<void> hide() => _invoke('hide');

  static Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // No native side (a platform without the overlay): the call simply has no extra button.
    }
  }
}
