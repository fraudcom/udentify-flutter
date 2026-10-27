# Liveness Flutter Plugin

A Flutter plugin for Udentify Face Recognition & Liveness detection, providing secure biometric authentication capabilities.

## Features

- **Camera-based Face Recognition**: Registration and authentication using device camera
- **Active Liveness Detection**: Advanced gesture-based liveness verification
- **Photo-based Recognition**: Recognition using provided base64 encoded images
- **Permission Management**: Automatic handling of camera and phone state permissions
- **Configurable Parameters**: Extensive customization options for recognition behavior

## Supported Platforms

- ✅ **Android** (API level 21+)
- ✅ **iOS** (iOS 13.0+)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  liveness_flutter:
    path: ../packages/liveness-flutter
```

## Android Setup

### 1. Add AAR Files

Copy the following AAR files to your `android/app/libs/` folder:
- `commons.aar`
- `face.aar`

### 2. Update build.gradle

Add the following to your app-level `build.gradle`:

```gradle
android {
    aaptOptions {
        noCompress "tflite"
    }
}

dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar', '*.jar'], exclude: [])
    
    // Face recognition dependencies (these are what the plugin itself declares; the plugin brings
    // them in, so an app only needs them when it also compiles the AARs directly)
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
    implementation 'com.otaliastudios:cameraview:2.7.2'
    implementation 'com.google.android.material:material:1.9.0'
    implementation 'com.google.code.gson:gson:2.10.1'
    implementation 'com.google.android.gms:play-services-mlkit-face-detection:17.1.0'
    // The face AAR calls the org.tensorflow.lite classes; these are the versions it runs on.
    // Do not add LiteRT next to them: both publish the same classes and the build fails with
    // duplicate classes.
    implementation 'org.tensorflow:tensorflow-lite:2.13.0'
    implementation 'org.tensorflow:tensorflow-lite-support:0.4.4'
    implementation 'com.airbnb.android:lottie:6.1.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
}
```

#### (Alternative) Maven dependency
If you have access to Udentify GitHub Packages, add the Maven repo to your project-level `build.gradle` and include:
```gradle
implementation 'com.fraud.udentify.android.sdk:commons:26.3.0928'
implementation 'com.fraud.udentify.android.sdk:face:26.3.0928'
```
Set `GITHUB_ACTOR` and `GITHUB_TOKEN` environment variables.

### 3. Add Permissions

Add the following permissions to your `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_PHONE_STATE" />

<!-- Optional permissions -->
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
```

### 4. Configure Activity

**The host activity must extend `FlutterFragmentActivity`**, not the default `FlutterActivity`. The SDK shows its screens as fragments, which need a `FragmentActivity`; Flutter's app template extends `FlutterActivity`, which is not one, so without this change the calls fail with `INVALID_ACTIVITY`.

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

Then add the following to your Activity in `AndroidManifest.xml`:

```xml
<activity
    ...
    android:screenOrientation="portrait"
    android:configChanges="orientation|keyboardHidden">
```

### 5. ProGuard/R8 rules
Nothing to add: the plugin ships a `consumer-rules.pro` that keeps `io.udentify.**`. Flutter turns R8 on for release builds by default; the plugin's rules are applied automatically.

## iOS Setup

### Add Privacy Permissions

Add the following to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access for face recognition</string>
```

## Usage

### Basic Setup

```dart
import 'package:liveness_flutter/liveness_flutter.dart';

// Check permissions
final permissionStatus = await LivenessFlutter.checkPermissions();
if (!permissionStatus.allGranted) {
  await LivenessFlutter.requestPermissions();
}
```

### How results arrive

`startFaceRecognitionRegistration`, `startFaceRecognitionAuthentication`, `startActiveLiveness`, `startHybridLiveness` and
`startSelfieCapture` complete as soon as the SDK's screen is on display (their `FaceRecognitionResult` only says the flow
started). **The outcome arrives through the callbacks, so register them first** and then start the flow.

A result is a success only when its `isFailed` is `false` (`status` is then `FaceRecognitionStatus.success`). A result that
carries no verdict arrives as a failed result (`isFailed` true, `status` `FaceRecognitionStatus.error`), and on Android a
selfie-recognition result that cannot be read arrives on the failure callback.

```dart
// 1) Callbacks, registered once (for example in initState).
LivenessFlutter.setOnResultCallback((FaceRecognitionResult result) {
  // Register, authenticate and selfie flows.
  final message = result.faceIDMessage;
  if (message == null || message.isFailed != false) return; // only `isFailed == false` is a success

  final face = message.faceIDResult;          // verified, matchScore, userID, transactionID
  final liveness = message.livenessResult;    // assessmentValue, probability, livenessScore, quality
  print('verified: ${face?.verified}, score: ${face?.matchScore}, liveness: ${liveness?.livenessScore}');
});

LivenessFlutter.setOnActiveLivenessResultCallback((FaceRecognitionResult result) {
  // Active and hybrid liveness.
  final gestures = result.faceIDMessage?.activeLivenessResult?.gestureResult;
  // gesture number -> passed (a bool on both platforms), e.g. {'0': true, '2': false}
  print('gestures: $gestures');
});

LivenessFlutter.setOnFailureCallback((FaceRecognitionError error) {
  print('${error.code}: ${error.message} (${error.type})');
});
LivenessFlutter.setOnActiveLivenessFailureCallback((FaceRecognitionError error) {
  print('${error.code}: ${error.message}');
});

// 2) Start a flow.
final credentials = FaceRecognizerCredentials(
  serverURL: 'https://your-server.com',
  transactionID: 'TRX123456789',
  userID: 'user_12345',
  autoTake: true,
  blinkDetectionEnabled: true,
);

await LivenessFlutter.startFaceRecognitionRegistration(credentials);      // camera, register
await LivenessFlutter.startFaceRecognitionAuthentication(credentials);    // camera, authenticate
```

### Active and hybrid liveness

```dart
// isAuthentication: false registers the user, true authenticates.
await LivenessFlutter.startActiveLiveness(credentials, isAuthentication: false);
await LivenessFlutter.startHybridLiveness(credentials, isAuthentication: true);
```

Their results arrive on `setOnActiveLivenessResultCallback` / `setOnActiveLivenessFailureCallback`. While the user
performs the gestures, `setOnActiveLivenessDirectiveChangedCallback` reports what the SDK is asking for, and
`setOnPhotoTakenCallback` / `setOnVideoTakenCallback` fire when the recording ends (see below).

### Selfie capture, then recognition

```dart
LivenessFlutter.setOnSelfieTakenCallback((String base64Image) async {
  // Send the selfie you captured to the server.
  await LivenessFlutter.performFaceRecognitionWithSelfie(credentials, base64Image, false); // false: register
});
await LivenessFlutter.startSelfieCapture(credentials);
```

### Photo-based Recognition

```dart
// Registration with a photo you already have (base64 JPEG)
await LivenessFlutter.registerUserWithPhoto(credentials, base64EncodedImage);

// Authentication with a photo
await LivenessFlutter.authenticateUserWithPhoto(credentials, base64EncodedImage);
```

The results arrive on `setOnResultCallback` / `setOnFailureCallback`, like the camera flows.

On iOS, an error the SDK attaches to a result (`faceIDResult.error`, `livenessResult.error`, `activeLivenessResult.error`) is a `FaceRecognitionError` with the SDK's error name in `code` and its text in `message`, the same fields the failure callbacks give.

### Other callbacks

```dart
// Photo taken callback
LivenessFlutter.setOnPhotoTakenCallback(() {
  print('Photo captured');
});

// Video taken callback (active and hybrid liveness)
LivenessFlutter.setOnVideoTakenCallback(() {
  print('Recording finished, the result is on its way');
});
```

`setOnPhotoTakenCallback` fires when the camera has captured the photo, before the result arrives. For active and hybrid liveness it fires when the recording ends, together with `setOnVideoTakenCallback`, on both platforms. On Android the register and authenticate camera screen closes at that point, so show your own progress indicator until the result.

## Configuration Options

### FaceRecognizerCredentials

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `serverURL` | String | Required | Server endpoint URL |
| `transactionID` | String | Required | Unique transaction identifier |
| `userID` | String | Required | User identifier |
| `autoTake` | bool | true | Automatically capture when face is positioned correctly |
| `errorDelay` | double | 0.10 | Delay in seconds before changing error type |
| `successDelay` | double | 0.75 | Delay in seconds after error before marking success |
| `runInBackground` | bool | false | Close camera view before server response |
| `blinkDetectionEnabled` | bool | false | Enable blink detection |
| `requestTimeout` | int | 10 | Server response timeout in seconds |
| `eyesOpenThreshold` | double | 0.75 | Threshold for determining if eyes are open (0-1) |
| `maskConfidence` | double | 0.95 | Confidence threshold for mask detection |
| `invertedAnimation` | bool | false | Interchange near and far animations |
| `activeLivenessAutoNextEnabled` | bool | true | Auto-proceed in active liveness |

## Error Handling

Failures arrive on the failure callbacks (above) as a `FaceRecognitionError` with the SDK's `ERR_*` name in `code`
and a typed `type`. A flow that cannot start (no `FlutterFragmentActivity`, no camera permission, an argument the
plugin rejects) throws a `PlatformException` from the `start*` call instead.

```dart
try {
  await LivenessFlutter.startFaceRecognitionRegistration(credentials);
} on PlatformException catch (e) {
  // INVALID_ACTIVITY, NO_ACTIVITY, START_FAILED, ... (codes the plugin raises before the SDK runs)
  print('${e.code}: ${e.message}');
}

LivenessFlutter.setOnFailureCallback((error) {
  switch (error.type) {
    case LivenessErrorType.cameraPermissionRequired:
      // ask for the permission again
      break;
    default:
      print('Recognition failed: ${error.code}');
  }
});
```

## Error Codes

A failure carries the face SDK's own `ERR_*` name as its code where the SDK reports one, and `FaceRecognitionError.type` maps it to the typed `LivenessErrorType` enum (see `lib/src/models/liveness_models.dart` for the full list), for example:

| Code | Description |
|------|-------------|
| `ERR_CAMERA_PERMISSION_REQUIRED` | Camera permission has not been granted |
| `ERR_FACE_PHOTO_MISSING` | No face photo was provided or captured |
| `ERR_FACEKEY_NOT_ALIVE` | The liveness check did not pass |
| `ERR_ACTIVE_LIVENESS_FAILED` | The active liveness check failed |
| `ERR_SERVER_TIMEOUT_EXCEPTION` | The server did not answer in time |

Codes the plugin raises itself before the SDK runs (`INVALID_ARGUMENTS`, `NO_ACTIVITY`, `INVALID_ACTIVITY`, …) keep their names. Android needs a `FlutterFragmentActivity` (see Android setup).

## Example

See the complete example in the `testApplicationFlutter` project, which demonstrates:

- Permission management
- Camera-based registration and authentication
- Active liveness detection
- Photo-based recognition
- Real-time callback handling
- Error handling

## Requirements

### Flutter
- Flutter 3.38.0 or higher (Dart 3.10 or higher)

### Android
- Android API level 21 (Android 5.0) or higher
- Camera permission
- Internet permission
- Phone state permission (recommended)

### iOS
- iOS 13.0 or higher
- Camera permission

## License

This plugin is part of the Udentify SDK integration suite.

## Support

For technical support and documentation, please contact the Udentify team.

## In-call LiveKYC repeat

`LivenessFlutter.setRepeatConfig(FaceRepeatConfig)` opts this app into in-call face repeats: the video call operator asks the customer to redo a face capture without leaving the call. **Android only and off by default** (on iOS, enable LiveKYC through the video call's `liveKYCOptions`); it returns `false` where it does not apply, and `null` opts back out. Call it before starting the video call. See the [video-call README](../video-call-flutter/README.md#-livekyc-in-call-ocr--face--nfc-repeats) for the full flow and the settings that fail quietly.

## Active liveness backdrop (Android)

`FaceRecognizerCredentials.activeLivenessOpacity` (`0`-`1`) sets the opacity of the backdrop drawn over the camera preview during active liveness. Left `null`, the plugin's existing default of `0.95` applies; pass `0` to show the preview fully.

