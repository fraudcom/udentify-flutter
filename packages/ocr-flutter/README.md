# ocr_flutter

Flutter plugin for ID document OCR with the Udentify SDK — scans ID cards, passports and driver's licences, extracts the holder's data and photo, runs Image Quality Analysis (IQA), and supports hologram verification and document liveness.

- **Version:** 26.3.0814
- **Platforms:** Android (API 21+) · iOS (11.0+; 13.0 recommended)
- **Requires:** a valid Udentify SDK licence, a camera-capable device, and the shared [`udentify_core_flutter`](../udentify-core-flutter) plugin.

---

## Table of contents

1. [Requirements](#requirements)
2. [Installation](#installation)
3. [Android setup](#android-setup)
4. [iOS setup](#ios-setup)
5. [Two ways to run OCR](#two-ways-to-run-ocr)
6. [Usage — camera capture flow](#usage--camera-capture-flow)
7. [Usage — provided photos flow](#usage--provided-photos-flow)
8. [Image formats (frontSidePhoto / backSidePhoto)](#image-formats-frontsidephoto--backsidephoto)
9. [Hologram verification](#hologram-verification)
10. [Document liveness](#document-liveness)
11. [UI customization](#ui-customization)
12. [API reference](#api-reference)
13. [Troubleshooting](#troubleshooting)

---

## Requirements

| | Minimum |
|---|---|
| Flutter | 3.3.0 |
| Dart | 3.2.3 |
| Android | API 21 (compile SDK 34) |
| iOS | 11.0 (13.0 recommended to match the other Udentify plugins) |
| Licence | Valid Udentify SDK licence |

`ocr_flutter` depends on `udentify_core_flutter`, which supplies the shared `UdentifyCommons` framework (iOS) and `commons` AAR (Android). Always add the core plugin alongside this one.

---

## Installation

```yaml
dependencies:
  ocr_flutter:
    git:
      url: https://github.com/fraudcom/udentify-flutter.git
      path: packages/ocr-flutter
  udentify_core_flutter:
    git:
      url: https://github.com/fraudcom/udentify-flutter.git
      path: packages/udentify-core-flutter
```

Or, for local development against a checkout of this repo:

```yaml
dependencies:
  ocr_flutter:
    path: ../packages/ocr-flutter
  udentify_core_flutter:
    path: ../packages/udentify-core-flutter
```

Then `flutter pub get`.

---

## Android setup

The plugin bundles `ocr-26.3.0814.aar` and declares the Udentify SDK as `compileOnly`, so **the host app must make the native SDK available at runtime**. Pick one option, then add the third-party dependencies and permissions.

### Native SDK — Option A: Maven / GitHub Packages (recommended)

Project-level `android/build.gradle`:

```groovy
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/fraudcom/mobile")
            credentials {
                username = System.getenv("GITHUB_ACTOR")
                password = System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
```

App-level `android/app/build.gradle`:

```groovy
implementation 'com.fraud.udentify.android.sdk:commons:26.3.0814'
implementation 'com.fraud.udentify.android.sdk:ocr:26.3.0814'
```

`GITHUB_ACTOR` / `GITHUB_TOKEN` are a GitHub username and a `read:packages` Personal Access Token. **Contact Udentify support** for repository access and the exact coordinates for your licence.

### Native SDK — Option B: Bundled AAR files (manual)

Copy into your app's `android/app/libs/`:

- `commons-26.3.0814.aar` (from `packages/udentify-core-flutter/android/libs/`)
- `ocr-26.3.0814.aar` (from `packages/ocr-flutter/android/libs/`)

…and reference them:

```groovy
implementation fileTree(dir: 'libs', include: ['*.aar'])
```

### Required third-party dependencies (both options)

```groovy
implementation 'com.squareup.okhttp3:okhttp:4.12.0'
implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
implementation 'com.otaliastudios:cameraview:2.7.2'
implementation 'com.google.android.material:material:1.4.0'
implementation 'com.google.code.gson:gson:2.8.7'
implementation 'com.google.android.gms:play-services-mlkit-face-detection:17.1.0'
implementation 'com.google.mlkit:object-detection:17.0.0'
```

> **v26.1.3 note:** face detection moved to `play-services-mlkit-face-detection:17.1.0` (previously `com.google.mlkit:face-detection`). Update this line if you are upgrading from an older version.

### Permissions & Activity

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.VIBRATE" />   <!-- IQA haptic feedback (26.1.3) -->
```

The OCR and hologram fragments are portrait-only. On the host Activity:

```xml
android:screenOrientation="portrait"
android:configChanges="orientation|keyboardHidden"
```

### ProGuard / R8

```pro
-keep public class io.udentify.** { *; }
```

---

## iOS setup

The plugin **vendors `UdentifyOCR.xcframework`** and depends on `udentify_core_flutter` for `UdentifyCommons.xcframework`. CocoaPods pulls both in automatically — **no** manual XCFramework drag-and-drop or Swift Package Manager step is needed. Run `pod install` (via `flutter run`) and add the Info.plist keys:

```xml
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to scan identity documents.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app saves scanned documents to your photo library.</string>
```

System frameworks (`AVFoundation`, `Photos`, `PhotosUI`) are linked by the podspec.

---

## Two ways to run OCR

There are two independent ways to obtain an OCR result:

| Flow | How | Use when |
|---|---|---|
| **Camera capture** | `startOCRCamera()` opens the SDK camera UI (with IQA). The captured images are held natively; you then call `performOCR()` to get the result. | You want the guided Udentify capture UI + quality checks. |
| **Provided photos** | You already have the document images as base64 and pass them straight to `performOCR()` (or the liveness APIs). | You capture/obtain the images yourself. |

Both call `performOCR()` — the difference is only whether you pass real base64 images or let the native layer use the ones captured by the camera.

---

## Usage — camera capture flow

Register the callbacks **once** (e.g. in `initState`), then start the camera. The result arrives through `setOnOCRSuccessCallback`.

```dart
import 'package:ocr_flutter/ocr_flutter.dart';

// 1) Register callbacks.
OcrFlutter.setOnDocumentScanCallback((documentSide, frontPhoto, backPhoto) {
  // Fired when the camera finishes capturing. In the camera flow the images are
  // stored natively, so frontPhoto/backPhoto is the sentinel "IMAGE_PATH_STORED".
  // Trigger processing — performOCR will use the natively-stored captures.
  _runOcr();
});

OcrFlutter.setOnOCRSuccessCallback((OCRResponse response) {
  final id = response.idCardResponse;
  debugPrint('Name: ${id?.firstName} ${id?.lastName}');
  debugPrint('ID No: ${id?.identityNo}');
  // id?.faceImage is a base64 JPEG of the holder's photo.
});

OcrFlutter.setOnOCRFailureCallback((error) => debugPrint('OCR failed: $error'));
OcrFlutter.setOnBackButtonPressedCallback(() => debugPrint('User cancelled'));

// Optional live feedback while the camera is open:
OcrFlutter.setOnIQAResultCallback((IQAResult iqa) {
  // e.g. IQAFeedback.glareDetected -> ask the user to reduce glare
  debugPrint('IQA: ${iqa.feedback.value} (qualified: ${iqa.qualified})');
});
OcrFlutter.setOnOCRDirectiveChangedCallback((directive, ts) {
  debugPrint('Directive: $directive'); // takeFrontSidePhoto, onReviewScreen, ...
});

// 2) Start the camera.
Future<void> startScan() async {
  await OcrFlutter.startOCRCamera(OCRCameraParams(
    serverURL: 'https://your-udentify-server.com',
    transactionID: 'TX_123',
    documentType: OCRDocumentType.idCard,
    country: OCRCountry.turkey,
    documentSide: OCRDocumentSide.bothSides,
  ));
}

// 3) Process the natively-captured images.
Future<void> _runOcr() async {
  final response = await OcrFlutter.performOCR(OCRProcessParams(
    serverURL: 'https://your-udentify-server.com',
    transactionID: 'TX_123',
    documentType: OCRDocumentType.idCard,
    country: OCRCountry.turkey,
    // Leave frontSidePhoto/backSidePhoto null: the native layer uses the camera captures.
  ));
  // Result also arrives via setOnOCRSuccessCallback.
}
```

Remember to `OcrFlutter.clearOCRCallbacks()` in `dispose()`.

---

## Usage — provided photos flow

If you already have the images, pass them directly. `performOCR()` uses your images and skips the camera.

```dart
final response = await OcrFlutter.performOCR(OCRProcessParams(
  serverURL: 'https://your-udentify-server.com',
  transactionID: 'TX_123',
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.turkey,
  frontSidePhoto: frontBase64,   // raw base64 JPEG — see below
  backSidePhoto: backBase64,
  requestTimeout: 30,
));

if (response.responseType == 'idCard') {
  final id = response.idCardResponse!;
  print('${id.firstName} ${id.lastName} — ${id.identityNo}');
}
```

---

## Image formats (frontSidePhoto / backSidePhoto)

- **Format:** a **base64-encoded JPEG**, passed as a plain `String`.
- **No data-URI prefix required.** Pass the raw base64. A `data:image/jpeg;base64,` prefix is tolerated (stripped automatically) but not needed.
- **Both sides optional, at least one required.** For a passport you typically send only `frontSidePhoto`.
- **Camera flow:** leave both `null` — the native layer uses the images captured by `startOCRCamera()`. (Internally the scan callback reports the sentinel `"IMAGE_PATH_STORED"`; the plugin recognises it and falls back to the stored captures, so you never pass it yourself.)

```dart
// Producing base64 from a file:
final bytes = await File(path).readAsBytes();
final frontBase64 = base64Encode(bytes); // no prefix
```

---

## Hologram verification

```dart
OcrFlutter.setOnHologramVideoRecordedCallback((videoUrls) { /* iOS: real file URLs */ });
OcrFlutter.setOnHologramFailureCallback((e) => debugPrint('Hologram failed: $e'));

await OcrFlutter.startHologramCamera(HologramParams(
  serverURL: 'https://your-udentify-server.com',
  transactionID: 'TX_123',
  noFlashDuration: 2,   // seconds recorded without flash (SDK default 2)
  flashDuration: 3,     // seconds recorded with flash (SDK default 3)
  totalDuration: 5,     // total video length (SDK default 5)
));

// iOS: upload the recorded videos returned by the callback.
final result = await OcrFlutter.uploadHologramVideo(params, videoUrls);
print('Hologram exists: ${result.hologramExists}');
print('ID match: ${result.ocrIdAndHologramIdMatch}');
print('Face match: ${result.ocrFaceAndHologramFaceMatch}');
```

> **Platform difference:** On **Android** the SDK records, uploads and verifies the hologram internally and returns the outcome directly, so you do **not** call `uploadHologramVideo()`. On **iOS** the SDK returns the recorded video file URLs, which you pass to `uploadHologramVideo()`.

---

## Document liveness

Document liveness checks whether the captured document is a genuine, physically-present document (anti-spoofing).

```dart
final response = await OcrFlutter.performDocumentLiveness(DocumentLivenessParams(
  serverURL: 'https://your-udentify-server.com',
  transactionID: 'TX_123',
  frontSidePhoto: frontBase64,   // base64 JPEG (real images required)
  backSidePhoto: backBase64,
  requestTimeout: 30,
));

final front = response.documentLivenessDataFront?.documentLivenessResponse;
final probability = double.tryParse(front?.aggregateDocumentLivenessProbability ?? '0') ?? 0;
print('Front liveness probability: $probability');
```

`performDocumentLiveness()` runs the liveness check on the images you provide. `performOCRAndDocumentLiveness()` combines OCR and the liveness check in a single call. Document liveness must be enabled for your transaction/licence on the Udentify server — confirm availability with Udentify.

---

## UI customization

You can restyle the camera, review and IQA (image quality) screens. **The two platforms work completely differently under the hood**, so read the section for the platform you're customizing rather than assuming a property that works on one also works on the other. `ui_types.dart` and `iqa_types.dart` define one shared Dart API for both, but only some of it is actually wired up per platform today — the tables below say exactly what does something and what doesn't.

- **iOS** is fully dynamic: everything you pass to `setOCRUIConfig()` is read live, right before the camera opens. No rebuild needed.
- **Android** is split in two: a handful of on/off and numeric settings *are* read live from `setOCRUIConfig()`, but every color and font is a **compile-time resource**, baked into your app when you build it. There's no dynamic Android color API today — see [Android: colors, text and fonts](#android-colors-text-and-fonts) below for the real mechanism.

This Flutter plugin wraps Udentify's native iOS and Android SDKs, and their official docs go deeper than this README on the underlying styling types and resource names — worth a look if you need something not covered here:

- [iOS SDK — OCR ID Verification (UI Customisation)](https://docs.fraud.com/fraudcom/udentify/udentify-api-and-sdk/ios-sdk/ocr-id-verification) — full property tables for `UdentifyButtonStyle`, `UdentifyTextStyle`, `UdentifyViewStyle`, `UdentifyProgressBarStyle`, `UdentifyImageStyle` and IQA screen styling, i.e. the native types `footerViewStyle`, `titleLabelStyle`, `progressBarStyle`, `iqaScreenStyle`, etc. map onto.
- [Android SDK — OCR ID Verification (UI Customisation)](https://docs.fraud.com/fraudcom/udentify/udentify-api-and-sdk/android-sdk/ocr-id-verification) — the native resource-override reference: Strings, Colors, **Dimens** (button height, corner radius, border width) and **Styles** (fonts, alignment). This plugin only ships `colors.xml`/`strings.xml` overrides itself (see below) — the Dimens/Styles resource names from this doc aren't mirrored in this repo, but the same app-level override trick should apply to them too, since Android resolves by resource name against whatever the SDK's `.aar` bakes in, not against what this plugin happens to ship.

Call `setOCRUIConfig()` once, **before** `startOCRCamera()` (or before `performOCR()` if you're skipping the camera). It stays in effect for later camera sessions until you call it again:

```dart
await OcrFlutter.setOCRUIConfig(OCRUIConfig(
  blurCoefficient: 0.0,                 // -1..1, higher = stricter sharpness
  detectionAccuracy: 15,                // iOS: 0..200, Android: passed to hardwareSupport
  reviewScreenEnabled: true,
  iqaEnabled: true,                     // Image Quality Analysis
  placeholderTemplate: OCRPlaceholderTemplate.countrySpecificStyle,
  orientation: OCROrientation.horizontal,
  maskLayerColor: '#80000000',          // works on both platforms
  footerViewStyle: OCRButtonStyle(backgroundColor: '#844EE3', textColor: '#FFFFFF', cornerRadius: 8),
  titleLabelStyle: OCRTextStyle(fontSize: 22, fontBold: true, textColor: '#FFFFFF'),
));
```

`footerViewStyle` and `titleLabelStyle` above only take visual effect on **iOS**; on Android, see the resource-override section instead.

### Behavior settings (numbers & on/off switches)

These aren't colors — they tune how the camera behaves. Both platforms read them straight out of `setOCRUIConfig()`, but not the same set of them:

| Property | What it does | iOS | Android |
|---|---|:--:|:--:|
| `blurCoefficient` | How strict the sharpness check is before a photo is accepted (-1..1) | ✅ | ✅ |
| `detectionAccuracy` | How confidently a document edge must be detected before auto-capture | ✅ (clamped 0-200) | ✅ (also accepts the older name `hardwareSupport`) |
| `reviewScreenEnabled` | Show a review/confirm screen after capture | ✅ | ✅ |
| `footerViewHidden` | Hide the bottom instruction/button bar | ✅ | ✅ |
| `placeholderTemplate` | Style of the on-screen document outline | ✅ | ✅ |
| `orientation` | Portrait vs. landscape document framing | ✅ | ✅ |
| `requestTimeout` | Network timeout, in seconds | ✅ | ✅ |
| `iqaEnabled` | Turn Image Quality Analysis on/off | ✅ | ✅ |
| `backButtonEnabled` | Show a back button on the camera screen | ✅ | not read |
| `rawPhotoCropRatio` | Crop margin around the detected document edges | ✅ | not read here — set it on `OCRCameraParams.rawPhotoCropRatio` instead, which both platforms honor |
| `manualCapture` | Let the user tap to capture instead of auto-capture | not read here — set it on `OCRCameraParams.manualCapture` instead, which both platforms honor | ✅ |
| `faceDetection` | Detect a face in frame during capture | not read | ✅ |
| `documentLivenessEnabled` | Run the document-liveness check as part of the camera flow | not read | ✅ |
| `successDelay` | Seconds to pause on a success state before continuing | not read | ✅ |
| `iqaSuccessAutoDismissDelay` | Seconds before the IQA success screen auto-closes | use `iqaScreenStyle.dismissAfterSuccessInSeconds` instead | ✅ |
| `localizationTableName` | Which `.strings` table to translate from | ✅ | not applicable — Android picks strings by device locale automatically, see below |

### iOS: full dynamic styling

On iOS, every nested style object in `OCRUIConfig` is applied live. This covers colors, fonts, sizes, corner radius, borders and spacing for:

- `placeholderContainerStyle` — the floating placeholder shown before a document is detected
- `footerViewStyle`, `buttonUseStyle`, `buttonRetakeStyle` — the footer bar and its buttons
- `titleLabelStyle`, `instructionLabelStyle` — the screen's title/instruction text (only used when `footerViewHidden: true`, since otherwise that text lives inside the footer bar)
- `reviewTitleLabelStyle`, `reviewInstructionLabelStyle` — text on the review screen
- `progressBarStyle` — the upload/processing progress bar
- `reviewBackgroundColor` / `reviewBackgroundStyle` — a solid color or a full background image behind the review screen
- `iqaScreenStyle` — a deep style object for the IQA screen: banners, buttons, the overlay/photo frames, and where the pass/fail result is positioned

Each of these is a nested object, e.g.:

```dart
await OcrFlutter.setOCRUIConfig(OCRUIConfig(
  footerViewStyle: OCRButtonStyle(
    backgroundColor: '#844EE3',
    textColor: '#FFFFFF',
    cornerRadius: 8,
    fontSize: 18,
    fontBold: true,
  ),
  buttonUseStyle: OCRButtonStyle(backgroundColor: '#4CD964', textColor: '#FFFFFF'),
  buttonRetakeStyle: OCRButtonStyle(backgroundColor: '#FF3B30', textColor: '#FFFFFF'),
  progressBarStyle: OCRProgressBarStyle(
    progressColor: '#844EE3',
    textStyle: OCRTextStyle(fontSize: 20, fontBold: true, textColor: '#FFFFFF'),
  ),
));
```

Two plain colors also apply directly, without a wrapper object: `buttonBackColor` (a generic button background) and `maskLayerColor` (the dimmed area outside the document frame).

Colors are hex strings (`#RRGGBB` or `#AARRGGBB` for transparency) or one of a small set of names: `purple`, `blue`, `green`, `red`, `black`, `white`, `gray`/`grey`, `clear`, `label`.

### Android: colors, text and fonts

Android's OCR screens ship as a compiled native module (an AAR), so they can't be repainted at runtime the way iOS can. Instead, Android uses the standard Android trick for skinning a library: **your app defines a resource with the exact same name as the library's, and your app's copy wins.** This is a build-time change — you edit an XML file in your Flutter app's `android/app/src/main/res/` folder and rebuild; it isn't something you call from Dart.

To override a color, add it to (or create) `android/app/src/main/res/values/colors.xml` in your **app**, using one of the resource names below:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="udentify_ocr_footer_btn_background_color">#844EE3</color>
    <color name="udentify_ocr_footer_btn_text_color">#FFFFFF</color>
</resources>
```

| Resource name | Default | What it colors |
|---|---|---|
| `udentify_ocr_card_mask_view_stroke_color` | `#CCFFFFFF` | Border of the document outline on the camera screen |
| `udentify_ocr_card_mask_view_background_color` | `#844EE3` | Fill behind the document outline |
| `udentify_ocr_mask_layer_background_color` | `#CC000000` | Dimmed area outside the document frame |
| `udentify_ocr_mask_card_color` | `#00000000` | Inside the card-shaped cutout |
| `udentify_ocr_mask_border_stroke_color` | `#00ACACAC` | Border around the cutout |
| `udentify_ocr_id_tur_background_color` | `#D1D4DA` | Background behind the captured card preview |
| `udentify_ocr_btn_text_color` | `#FFFFFF` | Generic button text |
| `udentify_ocr_footer_btn_background_color` | `#844EE3` | Footer bar button background |
| `udentify_ocr_footer_btn_border_stroke_color` | transparent | Footer bar button border |
| `udentify_ocr_footer_btn_text_color` | `#FFFFFF` | Footer bar button text |
| `udentify_ocr_footer_btn_color_success` | `#4CD964` | Footer bar button color on success |
| `udentify_ocr_footer_btn_color_error` | `#FF3B30` | Footer bar button color on error |
| `udentify_ocr_use_btn_background_color` | `#844EE3` | "Use" button background (review screen) |
| `udentify_ocr_use_btn_border_stroke_color` | transparent | "Use" button border |
| `udentify_ocr_use_btn_text_color` | `#FFFFFF` | "Use" button text |
| `udentify_ocr_retake_btn_background_color` | transparent | "Retake" button background |
| `udentify_ocr_retake_btn_border_stroke_color` | `#844EE3` | "Retake" button border |
| `udentify_ocr_retake_btn_text_color` | `#FFFFFF` | "Retake" button text |

Button/label text works the same way, through `android/app/src/main/res/values/strings.xml` (and `values-tr/strings.xml` for Turkish — add another `values-<locale>/strings.xml` for any other language you support; Android picks the right one from the device's locale automatically, no code needed):

```xml
<resources>
    <string name="udentify_ocr_button_use_title">Confirm</string>
    <string name="udentify_ocr_instruction_text_front_side">Fit the front of your ID in the frame</string>
</resources>
```

See [strings.xml](android/src/main/res/values/strings.xml) for the full list of overridable string names.

**Current limits on Android:**
- This plugin ships color and string overrides only — the table above and the strings file linked below are what's verified against this repo. Fonts, sizes, corner radius, border widths and spacing aren't exposed here today.
- The native Android SDK itself does support that finer styling, through the same resource-override trick applied to `dimens.xml` (button height, corner radius, border width, ...) and `styles.xml` (font family, alignment, ...) resource names — see the [Android SDK docs](https://docs.fraud.com/fraudcom/udentify/udentify-api-and-sdk/android-sdk/ocr-id-verification) linked above for those names. This plugin doesn't currently ship its own `dimens.xml`/`styles.xml`, so you'd be relying on resource names baked into the underlying `.aar` rather than something documented in this repo — treat it as unverified until you've tried it.
- It's build-wide, not per-session: you can't show different colors for different transactions the way iOS's runtime API allows, since the value is baked in when your app is compiled.
- The color/style objects on `OCRUIConfig` (`footerViewStyle`, `buttonUseStyle`, `buttonRetakeStyle`, `progressBarStyle`, `iqaScreenStyle`, etc.) currently have **no effect** on Android — only `blurCoefficient` and the other behavior settings above are read live. Use the resource-override method for anything visual on Android.

---

## API reference

`OcrFlutter` exposes **static** methods.

### Methods

| Method | Returns |
|---|---|
| `startOCRCamera(OCRCameraParams)` | `Future<bool>` |
| `performOCR(OCRProcessParams)` | `Future<OCRResponse>` |
| `performDocumentLiveness(DocumentLivenessParams)` | `Future<OCRAndDocumentLivenessResponse>` |
| `performOCRAndDocumentLiveness(OCRAndDocumentLivenessParams)` | `Future<OCRAndDocumentLivenessResponse>` |
| `startHologramCamera(HologramParams)` | `Future<bool>` |
| `uploadHologramVideo(HologramParams, List<String>)` | `Future<HologramResponse>` |
| `performIQA({serverURL, transactionID, imageBase64, documentType, documentSide, country})` | `Future<Map<String, dynamic>>` |
| `takePhoto()` | `Future<String>` (base64 JPEG) |
| `setOCRUIConfig(OCRUIConfig)` | `Future<void>` |
| `dismissOCRCamera()` / `dismissHologramCamera()` | `Future<void>` |

### Callbacks (register before starting the camera)

`setOnOCRSuccessCallback`, `setOnOCRFailureCallback`, `setOnDocumentScanCallback(documentSide, frontPhoto?, backPhoto?)`, `setOnBackButtonPressedCallback`, `setOnOCRAndDocumentLivenessResultCallback`, `setOnHologramVideoRecordedCallback`, `setOnHologramFailureCallback`, `setOnHologramBackButtonPressedCallback`, `setOnOCRDirectiveChangedCallback(directive, ts)`, `setOnHologramDirectiveChangedCallback`, `setOnIQAResultCallback(IQAResult)`, and `clearOCRCallbacks()`.

### `OCRCameraParams`

| Field | Type | Notes |
|---|---|---|
| `serverURL` | `String` | required |
| `transactionID` | `String` | required |
| `documentType` | `OCRDocumentType` | required |
| `userID` | `String?` | |
| `country` | `OCRCountry?` | not needed for passports |
| `documentSide` | `OCRDocumentSide?` | default `bothSides` |
| `manualCapture` | `bool?` | default `false` |
| `livenessMode` | `bool?` | run OCR + document liveness (see [Document liveness](#document-liveness)) |
| `rawPhotoCropRatio` | `double?` | crop extension around the card, `0.0`–`1.0`; SDK default `0.35` |

### `OCRProcessParams`

`serverURL`, `transactionID` (required), `documentType` (required), `userID?`, `frontSidePhoto?`, `backSidePhoto?`, `country?`, `requestTimeout?` (default 30).

### `HologramParams`

`serverURL`, `transactionID` (required), `userID?`, `country?`, `logLevel?`, `noFlashDuration?` (2), `flashDuration?` (3), `totalDuration?` (5), `bitrate?`.

### Enums

- **`OCRDocumentType`** — `idCard` (`ID_CARD`), `passport` (`PASSPORT`), `driverLicense` (`DRIVER_LICENSE`).
- **`OCRDocumentSide`** — `bothSides`, `frontSide`, `backSide`.
- **`OCRCountry`** — `turkey` (TUR), `unitedKingdom` (GBR), `colombia` (COL), `spain` (ESP), `brazil` (BRA), `usa` (USA), `peru` (PER), `ecuador` (ECU).
- **`OCRPlaceholderTemplate`** — `defaultStyle`, `hidden`, `countrySpecificStyle`.
- **`OCROrientation`** — `horizontal`, `vertical`.
- **`IQAFeedback`** — `success`, `blurDetected`, `glareDetected`, `hologramGlare`, `cardNotDetected`, `cardClassificationMismatch`, `cardNotIntact`, `other`.

### Response types

- **`OCRResponse`** — `responseType` (`'idCard'` / `'driverLicense'`), `idCardResponse` (`IDCardOCRResponse`), `driverLicenseResponse`, `success`, `transactionID`, `extractedData`.
- **`IDCardOCRResponse`** — `firstName`, `lastName`, `identityNo`, `birthDate`, `expiryDate`, `documentID`, `countryCode`, `faceImage` (base64), `gender`, `nationality`, `mrzString`, plus MRZ fields and checksum-verification flags. Full list in [ocr_types.dart](lib/src/types/ocr_types.dart).
- **`HologramResponse`** — `hologramExists`, `ocrIdAndHologramIdMatch`, `ocrFaceAndHologramFaceMatch`, `hologramFaceImage`, `idNumber`, `transactionID`.
- **`OCRAndDocumentLivenessResponse`** — `isFailed`, `ocrData`, `documentLivenessDataFront`, `documentLivenessDataBack`.
- **`DocumentLivenessResponse`** — `aggregateDocumentLivenessProbability` (String), `pipelineResults`, `aggregateDocumentImageQualityWarnings`.

---

## Troubleshooting

### IQA (image quality) feedback — not an error

During capture the SDK runs Image Quality Analysis and may reject a frame with, for example, `ERR_IQA_GLARE_DETECTED`. This is **expected quality gating**, surfaced via `setOnIQAResultCallback` (`IQAFeedback.glareDetected`, `.blurDetected`, `.cardNotDetected`, …). Guide the user to fix the condition (reduce glare, hold steady, fill the frame) and re-capture. You can disable IQA with `OCRUIConfig(iqaEnabled: false)`.

### Errors returned by `performOCR` / liveness

| `code` | Cause / fix |
|---|---|
| `MISSING_IMAGES` (Android) / `NO_IMAGES` (iOS) | No provided images **and** no camera capture stored. In the camera flow, call `performOCR()` only after the scan callback fires; in the provided-photos flow, pass a valid base64 JPEG. |
| `INVALID_ARGUMENTS` (iOS) | A required parameter is missing (`serverURL`, `transactionID`, `documentType`). |
| `INVALID_DOCUMENT_TYPE` (iOS) | `documentType` is not one of `ID_CARD` / `PASSPORT` / `DRIVER_LICENSE`. |
| `ERR_OCR_UNKNOWN_EXCEPTION` (server) | The OCR backend rejected the request — usually an expired/invalid `transactionID` (get a fresh one per attempt) or unsupported document/config. Also seen if a non-image string reaches the SDK (see the image-format notes above). |
| `ACTIVITY_ERROR` / `NO_ACTIVITY` (Android) | Call from a resumed `FragmentActivity`. |
| `PERFORM_OCR_ERROR` / `OCR_FAILED` | Wraps an SDK/network failure — inspect the message. |
| `TAKE_PHOTO_ERROR` | Camera unavailable or capture cancelled. |

`PlatformException`s are surfaced in Dart as `OCRException` with a typed `OCRErrorType` (see [ui_types.dart](lib/src/types/ui_types.dart) for the full `ERR_*` list — camera permissions, transaction states, server responses, document-liveness errors, …).

### Common integration issues

| Symptom | Fix |
|---|---|
| Build fails: `UdentifyCommons` not found (iOS) | Add `udentify_core_flutter`; the OCR plugin does not vendor Commons itself. |
| Runtime `ClassNotFoundException: io.udentify…` (Android) | Add the native SDK via Maven **or** copy the AARs into `android/app/libs/` (the plugin ships the AAR as `compileOnly`). |
| Camera opens then closes immediately | Missing `NSCameraUsageDescription` (iOS) or `CAMERA` permission not granted at runtime (Android). |
| The OCR screen is landscape / distorted | Set the host Activity to `screenOrientation="portrait"`. |

---

## Notes

- OCR / hologram fragments are **portrait-only**.
- `performIQA()` and `takePhoto()` both return a **base64 JPEG** string (no data-URI prefix).

## Related plugins

- [`udentify-core-flutter`](../udentify-core-flutter) — shared core (SSL pinning, remote localization). **Required.**
- [`nfc-flutter`](../nfc-flutter) — NFC passport / eID reading.
- [`mrz-flutter`](../mrz-flutter) — MRZ scanning.
