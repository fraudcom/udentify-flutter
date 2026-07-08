# Test Application Setup Notes

This sample app demonstrates the plugins in this monorepo. To run iOS with real SDK functionality, add the required Udentify frameworks and define compile-time flags per plugin.

## iOS SDK Enablement

For each plugin, copy the vendor frameworks into the plugin's `ios/Frameworks/` directory and enable the compile-time flag.

- Liveness (`liveness-flutter`)
  - Add: `Frameworks/UdentifyFace.xcframework`, `Frameworks/UdentifyCommons.xcframework`
  - Define: `UDENTIFY_FACE_AVAILABLE=1` (User Target Build Settings → Other Swift Flags or via Podspec `GCC_PREPROCESSOR_DEFINITIONS`)

- MRZ (`mrz-flutter`)
  - Add: `Frameworks/UdentifyCommons.xcframework`, `Frameworks/UdentifyMRZ.xcframework`, `Frameworks/TesseractOCRSDKiOS.xcframework`, `Frameworks/GPUImage.xcframework`
  - Define: `UDENTIFY_MRZ_AVAILABLE=1`

- NFC (`nfc-flutter`)
  - Add: `Frameworks/UdentifyNFC.xcframework`
  - Define: `UDENTIFY_NFC_AVAILABLE=1`

- OCR (`ocr-flutter`)
  - Add: `Frameworks/UdentifyCommons.xcframework`, `Frameworks/UdentifyOCR.xcframework`
  - Define: `UDENTIFY_OCR_AVAILABLE=1`

- Video Call (`video-call-flutter`)
  - Add: `Frameworks/UdentifyCommons.xcframework`, `Frameworks/UdentifyVC.xcframework`
  - Define: `UDENTIFY_VC_AVAILABLE=1`

You can set these macros via Podspec `user_target_xcconfig` or in Xcode: Build Settings → Other Swift Flags / Preprocessor Macros.

## Android Notes

Android native implementations are pending. Current Gradle files reference required dependencies and local AARs under each plugin's `android/libs/`.

Until Kotlin MethodChannel implementations are added, Android builds will compile but return `SDK_NOT_AVAILABLE` or no-op for most methods.

# test_application_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
