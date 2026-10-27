# Release notes

## 26.3.0928

Udentify SDK **26.3.0928** on both platforms, with LiveKYC (in-call repeats), a video-call styler that works the same on
iOS and Android, and results and errors that follow the native SDKs. All six packages move together. What to change in your
app is in [MIGRATION.md](MIGRATION.md).

### SDK updates

- Android `commons`, `ocr`, `nfc`, `face`, `vc` and `mrz`, and iOS `Commons`, `OCR`, `NFC`, `FACE`, `MRZ`, `VC` and the
  new `LiveKYC`, are `26.3.0928`.
- iOS video call uses the compiled `UdentifyVC` framework.
- Android dependencies match the set the SDKs run on: TensorFlow Lite 2.13.0 (liveness, OCR), Lottie 6.1.0, Tesseract4Android 4.9.0 (MRZ).
- Flutter 3.38 (Dart 3.10) or newer, iOS 13.0 or newer; Android release builds need no keep rules from you, each plugin ships its own.

### Video call

- **Error codes.** `VideoCallError.code` carries the code the native layer sent (`NO_ACTIVE_CALL`, `ALREADY_IN_PROGRESS`,
  `CANCEL_VIDEO_CALL_FAILED`, ...); `USAGE.md` lists them.
- **LiveKYC.** During a call the operator can ask the customer to redo a document scan, a face check or an NFC read without
  leaving the call. Android: opt in with `OcrFlutter` / `LivenessFlutter` / `NfcFlutter().setRepeatConfig`. iOS:
  `VideoCallCredentials.liveKYCOptions`. Events: `setOnRepeatStarted`, `setOnRepeatResult`, `setOnRepeatEnded`,
  `setOnNfcProgress` (iOS); `observationMode` chooses what the operator sees while a step runs.
- **One styler for both platforms.** `VideoCallConfig` styles the background, the picture-in-picture view, the mute,
  camera-switch and torch buttons and the waiting-screen label, with the same fields on iOS and Android.
- **Ending a call.** `cancelVideoCall()` cancels the transaction on the server and dismisses the screen. `setOnVideoCallDismissed`
  fires every time the screen goes away. A guide to adding your own end-call button is in `USAGE.md`.
- **Microphone and phone state.** `setMicrophoneEnabled` / `isMicrophoneEnabled`, `onMicrophoneStateChanged`,
  `onPhoneCallStateChanged`, `onScreenLocked` / `onScreenUnlocked`; `cameraFeedFrameRate` and `logLevel` options.
- Typed errors (`VideoCallErrorType`), a failed start that returns the error, and an iOS call screen presented full screen
  from the top-most view controller.

### OCR

- Typed errors (`OCRFailure`, `OCRErrorType`) with the SDK's own `ERR_*` names, and the full set of 15 `IQAFeedback` values
  on both platforms.
- The camera captures and `performOCR()` returns the result, the same on iOS and Android; the document-liveness calls use
  the camera's captures when you pass no photos.
- Android results include driver-licence details, passports and the hologram outcome; `manualCapture` and
  `rawPhotoCropRatio` can be set on the camera call, and anything you leave out of `OCRUIConfig` keeps the SDK's own default.
- `OCRUIConfig.documentDetectionConfig`, and `setRepeatConfig` for in-call document scans (Android).
- iOS: `performIQA` checks the image for the `country` you pass.
- Android: `OCRUIConfig.rawPhotoCropRatio` sets the crop, as on iOS; the camera call's own value wins.

### Liveness

- Typed face results on every flow (`faceIDResult`, `livenessResult`, `activeLivenessResult` with a `gestureResult` of bools),
  typed errors (`LivenessErrorType`) and `activeLivenessOpacity`.
- `onPhotoTaken` and `onVideoTaken` on both platforms for active and hybrid liveness.
- `isFailed: false` is the only success: a liveness result without a verdict is reported as a failure.
- iOS: an error inside a result (`faceIDResult.error`, `livenessResult.error`) carries the SDK's error name and text in `code` and `message`.
- `setRepeatConfig` for in-call face checks (Android).

### MRZ

- Failures carry `errorCode` and a typed `errorType`; the SDK's `ERR_MRZ_*` names come through.
- Android: an unreadable frame does not end the scan, and the screen is localized (English, Turkish, Spanish).
- iOS: `processMrzImage` returns every field the SDK reads, and `MrzUICustomization` styles the scan screen.

### NFC

- `chipAnticloneMode` (`none`, `auto`, `requireCA`, `requireAA`) chooses how the chip is authenticated; `passedCA` (the Chip Authentication verdict), `phoneNumber`, `documentCode`, `issuingAuthority`, `dateOfIssue` and
  `accessControlProtocol` in `NfcPassport`; typed errors (`NfcErrorType`); `isNfcAvailable()` / `isNfcEnabled()`;
  `setRepeatConfig` for in-call NFC reads (Android).

### Everywhere

- Turkish strings for the Android screens and messages the plugins ship; override any of them in your `strings.xml`.
- `getDeviceInfoSubPath()`, transaction properties on iOS that wait for the SDK's cache, and logs that contain events and
  error names only.
- Permission requests for NFC and MRZ complete when the user answers.
