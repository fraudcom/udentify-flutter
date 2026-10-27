# MRZ Flutter Plugin

A Flutter plugin for reading MRZ (Machine Readable Zone) from documents using the Udentify SDK.

## Features

- 📱 Camera-based MRZ scanning
- 🖼️ Image-based MRZ processing
- 🔍 Fast and Accurate modes
- 📊 Real-time progress tracking
- 🔒 Secure document verification

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  mrz_flutter:
    path: ../packages/mrz-flutter
```

## Setup

### Android Setup

1. **Add MRZ AAR files** to `android/libs/` directory:
   - `mrz-26.3.0928.aar` (from Udentify SDK; the plugin already bundles it)

2. **Add dependencies** to your app-level `build.gradle`:

```gradle
dependencies {
    // MRZ dependencies
    implementation 'cz.adaptech.tesseract4android:tesseract4android:4.9.0'
    implementation 'org.jmrtd:jmrtd:0.7.17'
    implementation 'edu.ucar:jj2000:5.2'
    implementation 'com.github.mhshams:jnbis:1.1.0'
    
    // Local AAR files
    implementation fileTree(dir: '../../../packages/mrz-flutter/android/libs', include: ['*.aar'])
}
```

3. (Alternative) **Maven dependency** (requires GitHub Packages access). Project-level `android/build.gradle`:

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
implementation 'com.fraud.udentify.android.sdk:mrz:26.3.0928'
```

`GITHUB_ACTOR` / `GITHUB_TOKEN` are a GitHub username and a `read:packages` Personal Access Token. **Contact Udentify support** for repository access. With this option, leave out the bundled AAR line above.

4. **Add permissions** to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

5. **Configure Activity** in `AndroidManifest.xml`:

```xml
android:screenOrientation="portrait"
android:configChanges="orientation|keyboardHidden"
```

6. **ProGuard/R8 rules.** Nothing to add: the plugin ships a `consumer-rules.pro` that keeps `io.udentify.**`. Flutter enables R8 for release builds by default. If you minify other libraries used alongside Udentify, you may also need `-keep class org.jmrtd.** { *; }` and `-keep class edu.ucar.** { *; }`.

### iOS Setup

1. **Add frameworks** to your iOS project's `Frameworks` folder:
   - `UdentifyCommons.xcframework`
   - `UdentifyMRZ.xcframework`
   - `TesseractOCRSDKiOS.xcframework`
   - `GPUImage.xcframework`

2. **Add permissions** to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>For scanning document MRZ</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Please allow access to save photos in your photo library</string>
```

## Usage

### Basic Example

```dart
import 'package:mrz_flutter/mrz_flutter.dart';

// Check camera permissions
bool hasPermission = await MrzFlutter.checkPermissions();
if (!hasPermission) {
  String result = await MrzFlutter.requestPermissions();
  if (result != 'granted') {
    // Handle permission denied
    return;
  }
}

// Start MRZ camera scanning
try {
  MrzResult result = await MrzFlutter.startMrzCamera(
    mode: MrzReaderMode.accurate,
    onProgress: (progress) {
      print('MRZ scanning progress: $progress%');
    },
  );
  
  if (result.success) {
    // Access complete MRZ data
    MrzData? mrzData = result.mrzData;
    if (mrzData != null) {
      print('Document Type: ${mrzData.documentType}');
      print('Document Number: ${mrzData.documentNumber}');
      print('Full Name: ${mrzData.fullName}');
      print('Nationality: ${mrzData.nationality}');
      print('Gender: ${mrzData.gender}');
      print('Date of Birth: ${mrzData.dateOfBirth}');
      print('Date of Expiration: ${mrzData.dateOfExpiration}');
      
      // Get BAC credentials for NFC reading
      BACCredentials? bacCredentials = result.bacCredentials;
      if (bacCredentials != null) {
        print('BAC Credentials for NFC: ${bacCredentials.toString()}');
      }
    }
    
    // Legacy access (still supported for backward compatibility)
    print('Legacy - Document Number: ${result.documentNumber}');
    print('Legacy - Date of Birth: ${result.dateOfBirth}');
    print('Legacy - Date of Expiration: ${result.dateOfExpiration}');
  } else {
    print('MRZ scanning failed: ${result.errorMessage}');
  }
} catch (e) {
  print('Error: $e');
}
```

### Process Image

```dart
// Process MRZ from a Base64 encoded image
String imageBase64 = "..."; // Your Base64 image data

MrzResult result = await MrzFlutter.processMrzImage(
  imageBase64: imageBase64,
  mode: MrzReaderMode.fast,
);

if (result.success && result.mrzData != null) {
  print('MRZ data extracted successfully');
  MrzData mrzData = result.mrzData!;
  
  print('Complete MRZ Information:');
  print('  Document Type: ${mrzData.documentType}');
  print('  Issuing Country: ${mrzData.issuingCountry}');
  print('  Document Number: ${mrzData.documentNumber}');
  print('  Full Name: ${mrzData.fullName}');
  print('  Nationality: ${mrzData.nationality}');
  print('  Gender: ${mrzData.gender}');
  print('  Date of Birth: ${mrzData.dateOfBirth}');
  print('  Date of Expiration: ${mrzData.dateOfExpiration}');
} else {
  print('Failed to extract MRZ: ${result.errorMessage}');
}
```

### Cancel Scanning

```dart
// Cancel ongoing MRZ scanning
await MrzFlutter.cancelMrzScanning();
```

## API Reference

### Methods

- `checkPermissions()` → `Future<bool>` - Check camera permissions
- `requestPermissions()` → `Future<String>` - Request camera permissions
- `startMrzCamera({mode, onProgress})` → `Future<MrzResult>` - Start camera scanning
- `processMrzImage({imageBase64, mode})` → `Future<MrzResult>` - Process image
- `cancelMrzScanning()` → `Future<void>` - Cancel scanning

### Models

#### MrzResult
- `success`: `bool` - Whether the operation was successful
- `mrzData`: `MrzData?` - Complete MRZ data extracted from document
- `errorMessage`: `String?` - Error message if failed
- `bacCredentials`: `BACCredentials?` - BAC credentials for NFC reading (derived from MRZ data)

**Legacy Properties (for backward compatibility):**
- `documentNumber`: `String?` - Document number from MRZ
- `dateOfBirth`: `String?` - Date of birth (YYMMDD format)  
- `dateOfExpiration`: `String?` - Expiration date (YYMMDD format)

#### MrzData
Complete MRZ information extracted from document:
- `documentType`: `String` - Document type (P for passport, I for ID card, etc.)
- `issuingCountry`: `String` - Country code that issued the document (3 letters)
- `documentNumber`: `String` - Document/passport number
- `optionalData1`: `String?` - Optional data field 1
- `dateOfBirth`: `String` - Date of birth in YYMMDD format
- `gender`: `String` - Gender (M/F/X)
- `dateOfExpiration`: `String` - Expiration date in YYMMDD format
- `nationality`: `String` - Nationality code (3 letters)
- `optionalData2`: `String?` - Optional data field 2
- `surname`: `String` - Family name/surname
- `givenNames`: `String` - Given names/first names
- `fullName`: `String` - Full name (computed property: givenNames + surname)

**Confirmation screen (Android).** The scan ends on a screen that shows the document number and the two dates with a **Next** button, so the user can check them by eye before the NFC step, as the SDK advises. Tapping Next returns the result.

**Which fields are filled.** The Android MRZ SDK reports the document number, the date of birth and the date of expiration; the other fields are empty strings on Android. The iOS SDK reports more. Use `bacCredentials` (document number, date of birth, expiration), which both platforms fill, to continue with NFC.

#### BACCredentials
BAC (Basic Access Control) credentials needed for NFC chip reading:
- `documentNumber`: `String` - Document number
- `dateOfBirth`: `String` - Date of birth (YYMMDD)
- `dateOfExpiration`: `String` - Expiration date (YYMMDD)

#### MrzReaderMode
- `MrzReaderMode.fast` - Fast but less accurate
- `MrzReaderMode.accurate` - Slower but more accurate

## Error Handling

A failed `MrzResult` carries `errorMessage`, the code in `errorCode` and the typed `errorType` (`MrzErrorType`). When the SDK reports an error it keeps its own name as the code, for example when `processMrzImage` cannot read the image on Android:

- `ERR_MRZ_NOT_FOUND` - MRZ field not found in image
- `ERR_INVALID_DATE_OF_BIRTH` - Invalid date of birth format
- `ERR_INVALID_DATE_OF_EXPIRE` - Invalid expiration date format
- `ERR_INVALID_DOC_NO` - Invalid document number format
- `PERMISSION_DENIED` - Camera permission not granted
- `CAMERA_ERROR` - Camera initialization failed
- `USER_CANCELLED` - The user cancelled the scan

### Callbacks and Progress

- Native layer emits progress updates via a channel method named `onProgress` with an `Int` payload (0–100). The Dart side converts this into `double` and forwards it to the `onProgress` callback you pass to `startMrzCamera`.
- On success, the method call returns a map that converts to `MrzResult` with `success: true` and complete `MrzData` containing all extracted MRZ fields.
- Legacy fields (`documentNumber`, `dateOfBirth`, `dateOfExpiration`) are still included for backward compatibility.
- On failure, the method returns `success: false` and `errorMessage` describing the issue. Transient camera-frame failures do not immediately finish; only terminal errors complete the call.

### NFC Integration

The plugin now provides BAC credentials needed for NFC chip reading:

```dart
MrzResult result = await MrzFlutter.startMrzCamera();
if (result.success) {
  BACCredentials? bacCredentials = result.bacCredentials;
  if (bacCredentials != null) {
    // Use these credentials for NFC chip reading
    // Pass to your NFC reading library
    print('BAC Credentials: ${bacCredentials.toString()}');
  }
}
```

### Image Processing Notes

- The `processMrzImage` method uses the Udentify MRZ SDK directly to parse MRZ from bitmap images.
- `processMrzImage` reads one image; a failure is final. `startMrzCamera` keeps scanning frames until the SDK reads one or the user cancels.
- Camera-based scanning (`startMrzCamera`) is the primary and most reliable method supported by all SDK versions.

## Notes

⚠️ **Important**: This plugin requires the official Udentify SDK files:
- For Android: `mrz.aar` file
- For iOS: `UdentifyMRZ.xcframework` and related frameworks

Without these files, the plugin will return appropriate SDK_NOT_AVAILABLE errors.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Scan screen appearance (iOS)

`MrzFlutter.startMrzCamera(uiCustomization: MrzUICustomization(...))` sets the focus border color and width, the instruction text and color, and the cancel button's visibility, text and color on iOS: `focusViewBorderColor` and `instructionTextColor` and `cancelButtonColor` (hex codes such as `#007AFF`), `focusViewStrokeWidth` (1 to 10), `instructionText`, `showCancelButton` and `cancelButtonText`. Omitted fields keep the default look. The Android scanner has its own fixed screen and ignores it. On Android, scanning reports no progress while it runs: `onProgress` fires once, at 100, when the read succeeds; iOS reports real progress.

