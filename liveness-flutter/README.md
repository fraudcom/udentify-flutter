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
- ✅ **iOS** (iOS 11.0+)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  liveness_flutter:
    path: ../liveness-flutter
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
    
    // Face recognition dependencies
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
    implementation 'com.otaliastudios:cameraview:2.7.2'
    implementation 'com.google.android.material:material:1.4.0'
    implementation 'com.google.code.gson:gson:2.8.7'
    implementation 'com.google.mlkit:face-detection:16.1.2'
    implementation 'org.tensorflow:tensorflow-lite:2.9.0'
    implementation 'org.tensorflow:tensorflow-lite-gpu:2.9.0'
    implementation 'org.tensorflow:tensorflow-lite-support:0.4.0'
    implementation 'com.airbnb.android:lottie:5.2.0'
}
```

#### (Alternative) Maven dependency
If you have access to Udentify GitHub Packages, add the Maven repo to your project-level `build.gradle` and include:
```gradle
implementation 'com.fraud.udentify.android.sdk:commons:25.3.0'
implementation 'com.fraud.udentify.android.sdk:face:25.3.0'
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

Add the following to your Activity in `AndroidManifest.xml`:

```xml
<activity
    ...
    android:screenOrientation="portrait"
    android:configChanges="orientation|keyboardHidden">
```

### 5. ProGuard/R8 rules
Add the following to your app's `proguard-rules.pro`:
```pro
-keep public class io.udentify.** { *; }
```

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

### Face Recognition with Camera

```dart
// Create credentials
final credentials = FaceRecognizerCredentials(
  serverURL: 'https://your-server.com',
  transactionID: 'TRX123456789',
  userID: 'user_12345',
  autoTake: true,
  blinkDetectionEnabled: true,
);

// Registration
final registrationResult = await LivenessFlutter.startFaceRecognitionRegistration(credentials);

// Authentication
final authResult = await LivenessFlutter.startFaceRecognitionAuthentication(credentials);
```

### Active Liveness Detection

```dart
final livenessResult = await LivenessFlutter.startActiveLiveness(credentials);
```

### Photo-based Recognition

```dart
// Registration with photo
final photoRegistrationResult = await LivenessFlutter.registerUserWithPhoto(
  credentials,
  base64EncodedImage,
);

// Authentication with photo
final photoAuthResult = await LivenessFlutter.authenticateUserWithPhoto(
  credentials,
  base64EncodedImage,
);
```

### Callbacks

Set up callbacks to handle real-time events:

```dart
// Result callback
LivenessFlutter.setOnResultCallback((result) {
  if (result.status == FaceRecognitionStatus.success) {
    print('Recognition successful: ${result.faceIDMessage?.success}');
  }
});

// Failure callback
LivenessFlutter.setOnFailureCallback((error) {
  print('Recognition failed: ${error.message}');
});

// Photo taken callback
LivenessFlutter.setOnPhotoTakenCallback(() {
  print('Photo captured');
});

// Selfie taken callback
LivenessFlutter.setOnSelfieTakenCallback((base64Image) {
  print('Selfie captured: ${base64Image.length} characters');
});
```

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

```dart
try {
  final result = await LivenessFlutter.startFaceRecognitionRegistration(credentials);
  
  switch (result.status) {
    case FaceRecognitionStatus.success:
      // Handle success
      break;
    case FaceRecognitionStatus.failure:
    case FaceRecognitionStatus.error:
      // Handle error
      print('Error: ${result.error?.message}');
      break;
  }
} catch (e) {
  print('Exception: $e');
}
```

## Common Error Codes

| Code | Description |
|------|-------------|
| `ERR_PERMISSIONS` | Required permissions not granted |
| `ERR_INVALID_CREDENTIALS` | Invalid server credentials |
| `ERR_NETWORK` | Network connection error |
| `ERR_TIMEOUT` | Server response timeout |
| `ERR_FACE_NOT_DETECTED` | No face detected in image |
| `ERR_MULTIPLE_FACES` | Multiple faces detected |
| `ERR_POOR_IMAGE_QUALITY` | Image quality too low |

## Example

See the complete example in the `testApplicationFlutter` project, which demonstrates:

- Permission management
- Camera-based registration and authentication
- Active liveness detection
- Photo-based recognition
- Real-time callback handling
- Error handling

## Requirements

### Android
- Android API level 21 (Android 5.0) or higher
- Camera permission
- Internet permission
- Phone state permission (recommended)

### iOS
- iOS 11.0 or higher
- Camera permission

## License

This plugin is part of the Udentify SDK integration suite.

## Support

For technical support and documentation, please contact the Udentify team.
