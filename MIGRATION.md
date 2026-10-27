# Migrating to 26.3.0928

This guide is for apps that use the `26.3.0814` plugins. Each item says what changed and what you do about it. What is
new is in [RELEASE-NOTES.md](RELEASE-NOTES.md). The per-plugin READMEs and
[`packages/video-call-flutter/USAGE.md`](packages/video-call-flutter/USAGE.md) describe the full API.

## 1. Before you start

- **Flutter 3.38 or newer** (Dart 3.10). All six plugins declare `flutter: ">=3.38.0"`; run `flutter upgrade`, then
  `flutter pub get`. Apple requires the UIScene lifecycle for apps built with Xcode 27, and Flutter supports it from 3.38.
- **Replace all six packages together** (`udentify-core-flutter`, `ocr-flutter`, `liveness-flutter`, `mrz-flutter`,
  `nfc-flutter`, `video-call-flutter`). Do not mix `0814` and `0928` plugins.
- **iOS 13.0 or newer** (liveness and video call require it; the others declare lower minimums). The iOS frameworks are built with Swift 6.2.1 (Xcode 26.x).
- **Android host activity:** `class MainActivity : FlutterFragmentActivity()` (liveness and video call need it).

## 2. Build and setup changes

| Area | What changed | What you do |
|---|---|---|
| Native SDKs | Android `commons`, `ocr`, `nfc`, `face`, `vc`, `mrz` and iOS `Commons`, `OCR`, `NFC`, `FACE`, `MRZ`, `VC` are `26.3.0928`; iOS adds `LiveKYC` | An app that copies the AARs itself uses `mrz-26.3.0928.aar` (the file name changed) |
| iOS video call | `UdentifyVC` is the compiled Udentify framework. The pod depends on `LiveKitWebRTC 144.7559.03` and no longer on `LiveKitClient` | Add `source 'https://github.com/livekit/podspecs.git'` (and the CocoaPods CDN source) to the `Podfile`; remove your own `LiveKitClient` dependency; run `pod install` |
| Android dependencies | TensorFlow Lite 2.13.0 and support 0.4.4 (liveness, OCR), Lottie 6.1.0, Material 1.9.0 / 1.8.0, ConstraintLayout 2.1.4; MRZ uses `cz.adaptech.tesseract4android:tesseract4android:4.9.0` from Maven Central | Remove LiteRT (`com.google.ai.edge.litert:*`) if you declare it next to the plugins; switch old Tesseract coordinates to the new one. JitPack is still needed for `com.github.mhshams:jnbis` (MRZ) |
| Android manifests | The plugins declare `READ_PHONE_STATE` (OCR, video call) and `MODIFY_AUDIO_SETTINGS` (video call) | Keep them if you remove permissions with `tools:node="remove"` |
| Android release builds | Each plugin ships its own `consumer-rules.pro` (keeps `io.udentify.**`, plus LiveKit for video call and jmrtd, scuba and bouncycastle for NFC) | You can delete the `-keep` lines you pasted from older READMEs |
| Android package names | OCR is now `com.ocrflutter`, MRZ is `com.mrzflutter` | Only if you name these packages yourself (manifest overrides, R8 rules, imports): update them and run `flutter clean` |
| iOS `Frameworks/UdentifyVC` | The plugin no longer contains a `Frameworks/UdentifyVC` source folder; the compiled framework replaces it | Nothing, unless you copied or patched files from that folder |

## 3. Code that no longer compiles

Before and after code for these is in [section 5](#5-before-and-after).

- **Video call.** Removed: `toggleCamera()`, `switchCamera()`, `toggleMicrophone()` and the `VideoCallConfig` fields
  `notificationLabelDefault`, `notificationLabelCountdown`, `notificationLabelTokenFetch`. Delete the calls and the
  arguments; your app behaves the same. Use
  `setMicrophoneEnabled(bool)` / `isMicrophoneEnabled()`; the SDK's in-call button switches the camera. To change the
  waiting-screen text on Android, override the three `udentify_vc_notification_label_*` strings in your `strings.xml`.
- **OCR.** Removed from `OCRUIConfig`: `localizationBundle`, `cardMaskViewStrokeColor`, `cardMaskViewBackgroundColor`,
  `maskCardColor`, `maskBorderStrokeColor`, `idTurBackgroundColor`, `buttonTextColor`, `footerButtonColorSuccess`,
  `footerButtonColorError`, and `OCRButtonStyle.contentAlignment`. Delete the arguments; `localizationTableName` still works.
- **Enums.** `OCRErrorType`, `IQAFeedback` and `VideoCallErrorType` have more values: an exhaustive `switch` needs the new cases.

## 4. Behaviour to check

Section 5 has before and after code for the OCR camera flow, liveness results, permission requests and error handling.

### All plugins

- **Error codes follow the SDKs.** Where an SDK reports an error under its own `ERR_*` name, that name is the code on both
  platforms. Codes the plugins raise before the SDK runs (`INVALID_ARGUMENTS`, `NO_ACTIVITY`, `START_FAILED`, …) keep their names.
  Catch blocks that matched an old constant (`OCR_FAILED`, `IQA_ERROR`, `ERR_SDK`, `ERR_ACTIVE_LIVENESS`,
  `NFC_READ_ERROR`, …) match the new name or switch on the typed enum (`OCRErrorType`, `LivenessErrorType`, `NfcErrorType`,
  `MrzErrorType`, `VideoCallErrorType`). The five `ERR_OCR_*` names exist only on iOS; Android's OCR SDK has its own `ERR_*` names.
- **Colors** are `#RGB`, `#RRGGBB` or `#AARRGGBB` (alpha first) everywhere; anything else is ignored and the SDK keeps its own color.
- **Logs contain events and error names only.** Read scan values from the callbacks.
- **Permission requests wait for the answer.** NFC and MRZ `requestPermissions()` return `"granted"` or `"denied"`
  (they returned `"requested"` at once); a request made while another is open is rejected.
- **iOS screens use the SDK's own look** unless your configuration sets a value: OCR placeholder, footer and labels;
  liveness colors, fonts and `autoTake` (the SDK's default is `false`); video call background, picture-in-picture frame and
  buttons. Set the values you want explicitly. Android is unchanged.
- **Android Turkish and Spanish strings** (MRZ screen, in-call NFC screen, video-call waiting screen, face messages)
  now ship; a device in those languages shows them. Override a string by defining the same name in your `strings.xml`.

### OCR

- **Android camera: capture, then `performOCR()`.** The camera only captures, as on iOS: `onDocumentScan` fires and the
  screen closes. Nothing is uploaded until you call `performOCR()` (from `setOnDocumentScanCallback`), which returns the
  result. `setOnOCRSuccessCallback` is not fired by this flow on either platform. An app that read the result from
  `setOnOCRSuccessCallback` without calling `performOCR()` must now call it.
  `livenessMode` (or `documentLivenessEnabled` in the UI config) keeps the SDK's own upload; the result comes through
  `setOnOCRAndDocumentLivenessResultCallback`.
- **Captured photos are used once.** `performOCR`, `performDocumentLiveness` and `performOCRAndDocumentLiveness` use the
  photos the last `startOCRCamera` captured when you pass none, and clear them when the call ends. Capture again before
  retrying a failed call, or pass the photos yourself. Photos you pass always win.
- **Android passes on only the `OCRUIConfig` options you set.** Left out, `detectionAccuracy` is the SDK's 10 and
  `placeholderTemplate` is `countrySpecificStyle`, as on iOS. To keep the earlier Android look and timing set
  `detectionAccuracy: 7` and `placeholderTemplate: OCRPlaceholderTemplate.defaultStyle`.
- **Android permissions are checked first.** `startOCRCamera` and `startHologramCamera` fail with
  `ERR_CAMERA_PERMISSION_REQUIRED` or `ERR_PHONE_STATE_PERMISSION_REQUIRED`. Request CAMERA and READ_PHONE_STATE before starting.
- **`requestTimeout` is used.** The `requestTimeout` on the `perform…` params (default 30) reaches the SDK in `performOCR` and `performOCRAndDocumentLiveness` on both platforms and in iOS `performDocumentLiveness`; Android's `performDocumentLiveness` keeps the SDK's fixed 30 seconds. Check any value you were passing.
- **Android applies `OCRUIConfig.rawPhotoCropRatio`.** A value you set there for iOS now also sets the crop on Android (the SDK's own
  default is 100%); `OCRCameraParams.rawPhotoCropRatio` still wins when set. Check the value, or set it per platform.
- **iOS `performIQA` uses the `country` you pass** (default `TUR`), as Android does. An app that passed another country now gets
  the quality check for that country.
- **`userID`.** With none passed, Android generates one from the current time; pass yours if the server relies on a stable one.
- **`IQAFeedback`** has one set of 15 values on both platforms (`chipNotDetected`, `signatureNotDetected`,
  `hiddenPhotoNotDetected`, …); the earlier Android spellings read as `other`.
- **Android results.** Driver-licence results carry the licence type, city and district; passports arrive in
  `extractedData`; `performDocumentLiveness` / `performOCRAndDocumentLiveness` return the same structure as the camera flow;
  `OCRCameraParams.manualCapture` is honored. Hologram: call `uploadHologramVideo(params, [])` after `startHologramCamera` to
  get the outcome.

### Liveness

- **Typed results are filled on every flow** (`faceIDResult`, `livenessResult`, `activeLivenessResult`);
  `gestureResult` maps each gesture number to a bool on both platforms. Results arrive on the callbacks; the `start…`
  calls complete when the screen is shown (see the README).
- **Active and hybrid liveness** report `onPhotoTaken` and `onVideoTaken` on Android as on iOS.
- **A result is a success only when it says so.** `onResult` and `onActiveLivenessResult` deliver a failed result (`status`
  `error`, `isFailed` true) when the SDK's response carries no `isFailed` verdict. Check `status` or `isFailed`, not the
  fact that the callback fired.
- **iOS errors inside a result carry the SDK's text.** `faceIDResult.error`, `livenessResult.error` and
  `activeLivenessResult.error` give the SDK's error name in `code` and its text in `message`, like the failure callbacks.
- **Android asks for less.** `RECORD_AUDIO` and `BLUETOOTH_CONNECT` no longer gate the face flows.
- **iOS:** `deleteUserFromList` is available; `addUserToList` and the photo-based register/authenticate calls take the
  same arguments as on Android; `activeLivenessAutoNextEnabled` is applied.

### MRZ

- **Android:** a frame the SDK cannot read does not end the scan; the next frame is scanned. `onProgress` fires once, at 100.
  The scan ends on a screen that shows the values and a **Next** button. `processMrzImage` accepts full-size photos.
- **Android result fields.** The Android MRZ SDK reports the document number, the date of birth and the date of expiration;
  the other `MrzResult` fields are empty strings there, and `bacCredentials` carries the three values for the NFC step. iOS
  reports more fields.
- **Failures carry the SDK's name.** A failed `MrzResult` has `errorCode` and a typed `errorType`; on Android a failed image
  returns the SDK's `ERR_MRZ_*` name and a user cancel stays `USER_CANCELLED`. Code that treated every Android image
  failure as a cancel reads `errorCode`.
- **iOS** `processMrzImage` returns every field the SDK reads.

### NFC

- **More in `NfcPassport`:** `passedCA` (the Chip Authentication verdict under the default `auto` mode), `phoneNumber`,
  `documentCode`, `issuingAuthority`, `dateOfIssue`, `accessControlProtocol`.
- **`chipAnticloneMode`** on `NfcPassportParams` chooses how the chip is authenticated: `none`, `auto` (the default: Chip
  Authentication when the chip has DG14, otherwise Active Authentication), `requireCA` or `requireAA`. Under `auto`, `passedCA`
  is the verdict to read.
- **Android error names:** `ERR_CARD_READING_FAILED` and `ERR_READING_DG<n>_FAILED` are reported as codes
  (`NfcErrorType.readingDataGroupFailed`); other failures keep `NFC_READ_ERROR`.
- **The document photo** is JPEG with unwrapped base64 on both platforms.

### Video call

- **iOS presents the call screen full screen** from the top-most view controller and follows the language chosen with
  `instantiateServerBasedLocalization`. Show your next screen from `setOnVideoCallDismissed` (it fires every time the screen
  goes away); `setOnVideoCallEnded` fires only when the agent ends the session. A second `startVideoCall` while a call
  screen is up fails with `ALREADY_IN_PROGRESS`.
- **Cancel.** `cancelVideoCall()` cancels the transaction on the server and dismisses the screen. On Android a cancel the
  server does not confirm still closes the screen and returns `CANCEL_VIDEO_CALL_FAILED`; treat the call as over. The Android
  status is `completed` when the SDK reported the end of the call and `disconnected` otherwise. `endVideoCall()` ends the call locally only.
- **Statuses and events.** `failed` is reported as a status on iOS, and `onVideoCallEnded {success}` and `onVideoCallDismissed` are emitted.
  A failed start on Android returns `success: false` with the error. An empty permission result (a cancelled request) counts as denied.
- **Errors carry their code.** `VideoCallError.code` is the code the native layer sent (`NO_ACTIVE_CALL`, `ALREADY_IN_PROGRESS`,
  `CANCEL_VIDEO_CALL_FAILED`, `INVALID_ARGUMENTS`, ...). `type` is still `unknown` for codes the enum does not list, so read `code`
  for those; the codes are listed in `USAGE.md`, section 11. `ERR_SDK` has its own value, `VideoCallErrorType.sdk`.
- **Styling.** See [Moving to one `VideoCallConfig` for both platforms](packages/video-call-flutter/USAGE.md#moving-to-one-videocallconfig-for-both-platforms).
- **An end-call button** is not part of the SDKs; [`USAGE.md`](packages/video-call-flutter/USAGE.md#adding-your-own-end-call-button) shows how to add your own.

## 5. Before and after

The Dart snippets below were compiled: "before" against the `26.3.0814` packages and "after" against `26.3.0928`.

### 5.1 Video call: removed members (compile error)

```dart
// Before (26.3.0814)
await VideoCallFlutter.toggleMicrophone();
await VideoCallFlutter.toggleCamera();
await VideoCallFlutter.switchCamera();
await VideoCallFlutter.setVideoCallConfig(const VideoCallConfig(
  backgroundColor: '#101820',
  notificationLabelDefault: 'Waiting for an agent',
  notificationLabelCountdown: 'Connecting in a moment',
  notificationLabelTokenFetch: 'Preparing your call',
));

// After (26.3.0928)
final enabled = await VideoCallFlutter.isMicrophoneEnabled();
await VideoCallFlutter.setMicrophoneEnabled(!enabled); // replaces toggleMicrophone()
// No camera methods: the SDK's in-call button switches the camera.
await VideoCallFlutter.setVideoCallConfig(const VideoCallConfig(
  backgroundColor: '#101820',
));
```

The waiting-screen text is not a `VideoCallConfig` field any more. On Android, set it with the SDK's string resources in your
app's `android/app/src/main/res/values/strings.xml` (iOS shows the SDK's own localized text):

```xml
<resources>
    <string name="udentify_vc_notification_label_default">Waiting for an agent</string>
    <string name="udentify_vc_notification_label_countdown">Connecting in a moment</string>
    <string name="udentify_vc_notification_label_token_fetch">Preparing your call</string>
</resources>
```

### 5.2 OCR: removed `OCRUIConfig` fields (compile error)

```dart
// Before (26.3.0814)
await OcrFlutter.setOCRUIConfig(OCRUIConfig(
  localizationBundle: 'OCR',
  localizationTableName: 'OCRLocalizable',
  cardMaskViewStrokeColor: '#FFFFFF',
  maskCardColor: '#FFFFFF',
  buttonTextColor: '#FFFFFF',
  footerButtonColorSuccess: '#00AA00',
  footerButtonColorError: '#CC0000',
));

// After (26.3.0928): delete the removed arguments; every other field is unchanged
await OcrFlutter.setOCRUIConfig(OCRUIConfig(
  localizationTableName: 'OCRLocalizable',
  buttonBackColor: '#844EE3',
));
```

### 5.3 OCR on Android: capture, then `performOCR()`

```dart
// Before (26.3.0814): the Android camera delivered the result itself
OcrFlutter.setOnOCRSuccessCallback((OCRResponse response) {
  final id = response.idCardResponse;
  print('Name: ${id?.firstName} ${id?.lastName}');
});
await OcrFlutter.startOCRCamera(OCRCameraParams(
  serverURL: 'https://your-udentify-server.com',
  transactionID: 'TX_123',
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.turkey,
  documentSide: OCRDocumentSide.bothSides,
));

// After (26.3.0928): the camera captures, performOCR() sends the images and returns the result
Future<void> runOcr() async {
  // Leave the photos out: performOCR() uses the images the camera captured.
  final response = await OcrFlutter.performOCR(OCRProcessParams(
    serverURL: 'https://your-udentify-server.com',
    transactionID: 'TX_123',
    documentType: OCRDocumentType.idCard,
    country: OCRCountry.turkey,
  ));
  final id = response.idCardResponse;
  print('Name: ${id?.firstName} ${id?.lastName}');
}

OcrFlutter.setOnDocumentScanCallback((documentSide, frontPhoto, backPhoto) {
  runOcr(); // the camera has captured; nothing is uploaded yet
});
OcrFlutter.setOnOCRFailureCallback((error) => print('OCR failed: $error'));
await OcrFlutter.startOCRCamera(OCRCameraParams(
  serverURL: 'https://your-udentify-server.com',
  transactionID: 'TX_123',
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.turkey,
  documentSide: OCRDocumentSide.bothSides,
));
```

### 5.4 Liveness: read the outcome from the callbacks

```dart
// Before (26.3.0814): the outcome was read from the result of the awaited call
final result = await LivenessFlutter.startFaceRecognitionRegistration(credentials);
if (result.status == FaceRecognitionStatus.success) {
  print('Recognition successful: ${result.faceIDMessage?.success}');
}

// After (26.3.0928): register the callbacks first; only isFailed == false is a success
LivenessFlutter.setOnResultCallback((FaceRecognitionResult result) {
  final message = result.faceIDMessage;
  if (message == null || message.isFailed != false) return;
  print('verified: ${message.faceIDResult?.verified}');
});
LivenessFlutter.setOnFailureCallback((FaceRecognitionError error) {
  print('${error.code}: ${error.message}');
});
await LivenessFlutter.startFaceRecognitionRegistration(credentials); // completes when the screen is shown
```

### 5.5 NFC and MRZ: `requestPermissions()` waits for the answer

```dart
// Before (26.3.0814): "requested" came back at once
final result = await NfcFlutter().requestPermissions();
if (result == 'requested') {
  print('ask again later');
}

// After (26.3.0928): the call completes when the user answers
final result = await NfcFlutter().requestPermissions();
if (result == 'granted') {
  print('continue');
} else {
  print('denied or error: $result');
}
```

### 5.6 Errors: match the SDK's names

```dart
// Before (26.3.0814)
try {
  await NfcFlutter().readPassport(params);
} on PlatformException catch (e) {
  if (e.code == 'NFC_READ_ERROR') print(e.message);
}

// After (26.3.0928): the SDK's own name is the code; the typed enum reads it
try {
  await NfcFlutter().readPassport(params);
} on PlatformException catch (e) {
  switch (NfcErrorType.fromException(e)) {
    case NfcErrorType.tagLost:
      print('hold the document still');
    case NfcErrorType.bacFailed:
      print('check the MRZ values');
    default:
      print('${e.code}: ${e.message}'); // other failures keep NFC_READ_ERROR
  }
}
```

### 5.7 Project setup

Android host activity (liveness and video call), `android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
// Before
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

```kotlin
// After
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

iOS `Podfile`, for the video-call plugin (then run `pod install`):

```ruby
# Before
source 'https://cdn.cocoapods.org/'

# After
source 'https://cdn.cocoapods.org/'
source 'https://github.com/livekit/podspecs.git'
```

## 6. Checklist

1. Flutter 3.38+, all six packages replaced, `flutter clean`, `flutter pub get`, `pod install` (with the LiveKit source; section 5.7).
2. Android host activity is a `FlutterFragmentActivity` (section 5.7); permissions requested before OCR and video call.
3. Compile errors fixed (section 3, code in 5.1 and 5.2); `switch` statements over the enums that grew.
4. OCR on Android: `performOCR()` called after `onDocumentScan` (section 5.3).
5. Error handling matched on the SDKs' names or the typed enums (section 5.6).
6. Liveness outcomes read from the callbacks (section 5.4); permission results handled as `granted` or `denied` (section 5.5).
7. Screens on iOS set explicitly where you want the earlier look.
