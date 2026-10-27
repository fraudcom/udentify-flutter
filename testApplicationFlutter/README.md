# Udentify Flutter test app

A sample app that exercises every plugin in this repository against Udentify SDK 26.3.0928. It is also the reference for
integrating the plugins (permissions, host activity, LiveKYC and the video-call screen).

## Requirements

- **Flutter 3.38 or newer** (Dart 3.10). The app's iOS startup files use Flutter's UIScene template, which first shipped in 3.38.
- **iOS:** Xcode 26.x, CocoaPods, a device (the MRZ frameworks have no arm64 simulator slice).
- **Android:** JDK 17. The test app builds with Gradle 8.14.3, Android Gradle Plugin 8.11.1 and Kotlin 2.2.20.

```bash
cd testApplicationFlutter
flutter pub get
cd ios && pod install && cd ..
flutter run --release
```

The plugins are referenced by path (`../packages/...`), so edits to a plugin are picked up on the next build.

## What it shows

One tab per plugin: SSL pinning, remote language pack, OCR, NFC, MRZ, video call and liveness.

- **Video call.** Asks for camera and microphone when the user starts a call, not at launch (iOS shows each system prompt
  once). The call screen is styled from one `VideoCallConfig` on both platforms. **LiveKYC** (in-call OCR, face and NFC
  repeats) is on by default; the switch on the page turns it off. The end-call button over the call screen is the app's own
  native overlay (`lib/services/call_overlay.dart`, `android/app/src/main/kotlin/.../MainActivity.kt`,
  `ios/Runner/AppDelegate.swift`): the SDKs have no end-call button, only the `cancelVideoCall()` / `endVideoCall()` methods.
  It is hidden while a LiveKYC repeat is on screen and shown again when the repeat ends. See "Adding your own end-call button" in `packages/video-call-flutter/USAGE.md`.
- **Android host activity.** `MainActivity` extends `FlutterFragmentActivity`, which the liveness and video-call screens need.
- **Configuration.** Server addresses and demo values are in `lib/models/app_constants.dart`.
