# ocr_flutter

Flutter plugin for ID document OCR with the Udentify SDK — scans ID cards, passports and driver's licences, extracts the holder's data and photo, runs Image Quality Analysis (IQA), and supports hologram verification and document liveness.

- **Version:** 26.1.3
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

The plugin bundles `ocr-26.1.3.aar` and declares the Udentify SDK as `compileOnly`, so **the host app must make the native SDK available at runtime**. Pick one option, then add the third-party dependencies and permissions.

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
implementation 'com.fraud.udentify.android.sdk:commons:26.1.3'
implementation 'com.fraud.udentify.android.sdk:ocr:26.1.3'
```

`GITHUB_ACTOR` / `GITHUB_TOKEN` are a GitHub username and a `read:packages` Personal Access Token. **Contact Udentify support** for repository access and the exact coordinates for your licence.

### Native SDK — Option B: Bundled AAR files (manual)

Copy into your app's `android/app/libs/`:

- `commons-26.1.3.aar` (from `packages/udentify-core-flutter/android/libs/`)
- `ocr-26.1.3.aar` (from `packages/ocr-flutter/android/libs/`)

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

`setOCRUIConfig(OCRUIConfig)` styles the camera, review and IQA screens. Colours are hex strings.

```dart
await OcrFlutter.setOCRUIConfig(OCRUIConfig(
  blurCoefficient: 0.0,                 // -1..1, higher = stricter sharpness
  detectionAccuracy: 15,                // 0..100
  reviewScreenEnabled: true,
  iqaEnabled: true,                     // Image Quality Analysis
  placeholderTemplate: OCRPlaceholderTemplate.countrySpecificStyle,
  orientation: OCROrientation.horizontal,
  maskLayerColor: '#80000000',
  footerViewStyle: OCRButtonStyle(backgroundColor: '#844EE3', textColor: '#FFFFFF', cornerRadius: 8),
  titleLabelStyle: OCRTextStyle(fontSize: 22, fontBold: true, textColor: '#FFFFFF'),
));
```

Call it **before** `startOCRCamera()`. `OCRUIConfig` exposes ~40 properties (banner/button/progress styles, Android card-mask colours, localization bundle/table, etc.) — see [ui_types.dart](lib/src/types/ui_types.dart) and [iqa_types.dart](lib/src/types/iqa_types.dart) for the full set.

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
