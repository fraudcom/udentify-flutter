# OCR Flutter - Complete Flutter OCR Plugin

A comprehensive Flutter plugin for OCR ID verification using Udentify's SDK.

## 🎉 Features

- ✅ **Complete iOS Implementation** - Full OCR functionality with UdentifyOCR framework
- ✅ **Android Implementation Ready** - Structure in place, uses same AAR files as React Native
- ✅ **Dart API** - Full type safety and Flutter integration
- ✅ **Document Scanning** - ID Cards, Passports, Driver Licenses
- ✅ **Hologram Verification** - Video recording and verification
- ✅ **Document Liveness** - Anti-spoofing document verification
- ✅ **OCR + Liveness** - Combined OCR and document liveness checks
- ✅ **UI Customization** - Comprehensive UI styling options
- ✅ **Cross-Platform** - Identical API for iOS and Android

## 📋 Current Status

- **iOS**: ✅ Production Ready - Full OCR functionality based on iOS SDK
- **Android**: ✅ Production Ready - Uses same AAR files as OCR Turbo React Native

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  ocr_flutter:
    path: ../ocr-flutter
```

## 🚀 Usage

### Basic OCR Scanning

```dart
import 'package:ocr_flutter/ocr_flutter.dart';

// Start OCR camera for document scanning
final params = OCRCameraParams(
  serverURL: "https://your-server.com",
  transactionID: "TX_123",
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.usa,
  documentSide: OCRDocumentSide.bothSides,
  manualCapture: false,
);

try {
  final success = await OcrFlutter.startOCRCamera(params);
  if (success) {
    print('OCR camera started successfully');
  }
} catch (e) {
  print('Failed to start OCR camera: $e');
}

// Process OCR on captured images
final processParams = OCRProcessParams(
  serverURL: "https://your-server.com",
  transactionID: "TX_123",
  frontSidePhoto: frontImageBase64, // Base64 encoded image
  backSidePhoto: backImageBase64,   // Base64 encoded image
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.usa,
  requestTimeout: 30,
);

try {
  final response = await OcrFlutter.performOCR(processParams);
  print('OCR Response: ${response.responseType}');
  
  if (response.responseType == 'idCard' && response.idCardResponse != null) {
    final idCard = response.idCardResponse!;
    print('Name: ${idCard.firstName} ${idCard.lastName}');
    print('ID Number: ${idCard.identityNo}');
    print('Birth Date: ${idCard.birthDate}');
    print('Expiry Date: ${idCard.expiryDate}');
    
    if (idCard.faceImage != null) {
      // Display the extracted face image
      print('Face image available');
    }
  }
} catch (e) {
  print('OCR failed: $e');
}
```

### Hologram Verification

```dart
// Start hologram camera
final hologramParams = HologramParams(
  serverURL: "https://your-server.com",
  transactionID: "TX_123",
);

try {
  final success = await OcrFlutter.startHologramCamera(hologramParams);
  if (success) {
    print('Hologram camera started');
  }
} catch (e) {
  print('Failed to start hologram camera: $e');
}

// Upload recorded hologram videos
// Note: On iOS, this method uploads videos to the server
// On Android, hologram upload happens automatically through SDK callbacks
try {
  final response = await OcrFlutter.uploadHologramVideo(
    hologramParams, 
    ['file:///path/to/video1.mp4', 'file:///path/to/video2.mp4']
  );
  
  print('Hologram verification: ${response.hologramExists}');
  print('ID match: ${response.ocrIdAndHologramIdMatch}');
  print('Face match: ${response.ocrFaceAndHologramFaceMatch}');
} catch (e) {
  print('Hologram upload failed: $e');
}
```

### Document Liveness Check

```dart
// Document liveness only
final livenessParams = DocumentLivenessParams(
  serverURL: "https://your-server.com",
  transactionID: "TX_123",
  frontSidePhoto: frontImageBase64,
  backSidePhoto: backImageBase64,
  requestTimeout: 30,
);

try {
  final response = await OcrFlutter.performDocumentLiveness(livenessParams);
  print('Document liveness response: ${response.isFailed}');
  
  if (response.documentLivenessDataFront?.documentLivenessResponse != null) {
    final frontLiveness = response.documentLivenessDataFront!.documentLivenessResponse!;
    print('Front liveness probability: ${frontLiveness.aggregateDocumentLivenessProbability}');
    
    // A document is considered "live" if probability > 0.5
    final probability = double.tryParse(frontLiveness.aggregateDocumentLivenessProbability ?? '0') ?? 0.0;
    final isLive = probability > 0.5;
    print('Document is live: $isLive');
  }
} catch (e) {
  print('Document liveness failed: $e');
}

// OCR + Document liveness combined
final combinedParams = OCRAndDocumentLivenessParams(
  serverURL: "https://your-server.com",
  transactionID: "TX_123",
  frontSidePhoto: frontImageBase64,
  backSidePhoto: backImageBase64,
  documentType: OCRDocumentType.idCard,
  country: OCRCountry.usa,
  requestTimeout: 30,
);

try {
  final response = await OcrFlutter.performOCRAndDocumentLiveness(combinedParams);
  
  // Process OCR data
  if (response.ocrData?.ocrResponse != null) {
    print('OCR data: ${response.ocrData!.ocrResponse}');
  }
  
  // Process liveness data
  if (response.documentLivenessDataFront?.documentLivenessResponse != null) {
    print('Front liveness: ${response.documentLivenessDataFront!.documentLivenessResponse}');
  }
  
  if (response.documentLivenessDataBack?.documentLivenessResponse != null) {
    print('Back liveness: ${response.documentLivenessDataBack!.documentLivenessResponse}');
  }
} catch (e) {
  print('OCR and liveness failed: $e');
}
```

### UI Customization

The OCR Flutter plugin provides comprehensive UI customization capabilities that map to native SDK features on both iOS and Android platforms.

#### Basic Configuration

```dart
final config = OCRUIConfig(
  // Detection and Behavior
  blurCoefficient: 0.2,        // -1 to 1, blur detection threshold
  requestTimeout: 30,          // Request timeout in seconds
  detectionAccuracy: 15,       // 0-100, focus accuracy level
  successDelay: 0.5,           // Delay before success (seconds)
  hardwareSupport: 12,         // Hardware support duration (seconds)
  
  // UI Controls
  backButtonEnabled: true,     // Enable back button
  reviewScreenEnabled: true,   // Enable review screen
  footerViewHidden: false,     // Hide footer view
  manualCapture: false,        // Enable manual capture mode
  faceDetection: false,        // Enable face detection
  documentLivenessEnabled: false, // Enable document liveness
);

await OcrFlutter.setOCRUIConfig(config);
```

#### Advanced UI Customization

```dart
final config = OCRUIConfig(
  // Placeholder Container Styling
  placeholderContainerStyle: OCRViewStyle(
    backgroundColor: '#844EE3',
    borderColor: '#FFFFFF',
    cornerRadius: 12.0,
    borderWidth: 3.0,
  ),
  
  // Template and Layout
  placeholderTemplate: OCRPlaceholderTemplate.countrySpecificStyle,
  orientation: OCROrientation.horizontal,
  
  // Colors
  buttonBackColor: '#844EE3',
  maskLayerColor: '#80000000',
  
  // Button Styling
  footerViewStyle: OCRButtonStyle(
    backgroundColor: '#844EE3',
    borderColor: '#FFFFFF',
    cornerRadius: 8.0,
    borderWidth: 2.0,
    height: 60.0,
    fontFamily: 'System',
    fontSize: 18.0,
    fontBold: true,
    textColor: '#FFFFFF',
    textAlignment: 'center',
  ),
  
  // Text Styling
  titleLabelStyle: OCRTextStyle(
    fontFamily: 'System',
    fontSize: 22.0,
    fontBold: true,
    textColor: '#FFFFFF',
    textAlignment: 'center',
  ),
  
  // Progress Bar (for hologram)
  progressBarStyle: OCRProgressBarStyle(
    backgroundColor: '#E0E0E0',
    progressColor: '#4CAF50',
    completionColor: '#2196F3',
    cornerRadius: 10.0,
  ),
  
  // Localization
  localizationBundle: 'main',
  localizationTableName: 'OCRLocalizable',
);

await OcrFlutter.setOCRUIConfig(config);
```

#### Platform-Specific Customization

**Android Resource Colors:**
```dart
final config = OCRUIConfig(
  // Android-specific color resources
  cardMaskViewStrokeColor: '#CCFFFFFF',
  cardMaskViewBackgroundColor: '#844EE3',
  maskCardColor: '#00000000',
  buttonTextColor: '#FFFFFF',
  footerButtonColorSuccess: '#4CAF50',
  footerButtonColorError: '#F44336',
);
```

**iOS OCRSettings Integration:**
The plugin automatically creates and applies `OCRSettings` conforming structs that integrate with `OCRSettingsProvider.getInstance().currentSettings` on iOS.

#### UI Customization Options

| Property | Type | Description | Platform |
|----------|------|-------------|----------|
| `blurCoefficient` | `double?` | Blur detection threshold (-1 to 1) | Both |
| `detectionAccuracy` | `int?` | Focus accuracy level (0-100) | Both |
| `placeholderTemplate` | `OCRPlaceholderTemplate?` | Placeholder style (default, hidden, country-specific) | Both |
| `orientation` | `OCROrientation?` | Document orientation (horizontal, vertical) | Both |
| `buttonBackColor` | `String?` | Back button color (hex) | Both |
| `maskLayerColor` | `String?` | Mask overlay color (hex) | Both |
| `footerViewStyle` | `OCRButtonStyle?` | Footer button styling | Both |
| `titleLabelStyle` | `OCRTextStyle?` | Title text styling | Both |
| `progressBarStyle` | `OCRProgressBarStyle?` | Progress bar styling | Both |
| `cardMaskViewStrokeColor` | `String?` | Card mask border color (hex) | Android |
| `faceDetection` | `bool?` | Enable face detection | Both |
| `documentLivenessEnabled` | `bool?` | Enable document liveness | Both |

See the [UI Customization Example](example/lib/ui_customization_example.dart) for complete implementation examples.

### Camera Control

```dart
// Dismiss OCR camera
await OcrFlutter.dismissOCRCamera();
print('OCR camera dismissed');

// Dismiss hologram camera
await OcrFlutter.dismissHologramCamera();
print('Hologram camera dismissed');
```

## 📱 Setup

### iOS Setup

1. **Add Framework Files**
   - Create `ios/Frameworks/` directory
   - Add `UdentifyCommons.xcframework` and `UdentifyOCR.xcframework`

2. **Update Info.plist**
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app uses the camera to scan documents</string>
   <key>NSPhotoLibraryAddUsageDescription</key>
   <string>This app saves scanned documents to your photo library</string>
   ```

### Android Setup

1. **Add AAR Files**
   - Create `android/libs/` directory
   - Add `commons.aar` and `ocr.aar` files

2. **Add Dependencies**
   Add these to your app-level `build.gradle`:
   ```gradle
   dependencies {
       // OCR dependencies
       implementation 'com.squareup.okhttp3:okhttp:4.12.0'
       implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
       implementation 'com.otaliastudios:cameraview:2.7.2'
       implementation 'com.google.android.material:material:1.4.0'
       implementation 'com.google.code.gson:gson:2.8.7'
       implementation 'com.google.mlkit:face-detection:16.1.5'
       implementation 'com.google.mlkit:object-detection:17.0.0'
   }
   ```

3. **Update Permissions**
   ```xml
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.READ_PHONE_STATE" />
   ```

4. **Configure Activity**
   Add to activities using OCR (portrait mode only):
   ```xml
   android:screenOrientation="portrait"
   android:configChanges="orientation|keyboardHidden"
   ```

5. (Alternative) **Maven dependency** (requires GitHub Packages access): add the GitHub repo to your project-level `build.gradle` and include:
   ```gradle
   implementation 'com.fraud.udentify.android.sdk:commons:25.3.0'
   implementation 'com.fraud.udentify.android.sdk:ocr:25.3.0'
   ```
   Ensure `GITHUB_ACTOR` and `GITHUB_TOKEN` env vars are set.

6. **ProGuard/R8 rules** in host app `proguard-rules.pro`:
   ```pro
   -keep public class io.udentify.** { *; }
   ```

## 🎯 API Reference

### Document Types
- `OCRDocumentType.idCard` - National ID cards
- `OCRDocumentType.passport` - Passports
- `OCRDocumentType.driverLicense` - Driver licenses

### Document Sides
- `OCRDocumentSide.bothSides` - Capture both front and back
- `OCRDocumentSide.frontSide` - Front side only
- `OCRDocumentSide.backSide` - Back side only

### Countries
- `OCRCountry.turkey`, `OCRCountry.unitedKingdom`, `OCRCountry.colombia`, `OCRCountry.spain`, `OCRCountry.brazil`, `OCRCountry.usa`, `OCRCountry.peru`, `OCRCountry.ecuador`

### Methods

#### OCR Methods
- `startOCRCamera(params)` → `Future<bool>` - Start OCR camera interface
- `performOCR(params)` → `Future<OCRResponse>` - Process OCR on images
- `dismissOCRCamera()` → `Future<void>` - Dismiss OCR camera

#### Hologram Methods
- `startHologramCamera(params)` → `Future<bool>` - Start hologram recording
- `uploadHologramVideo(params, videoUrls)` → `Future<HologramResponse>` - Upload hologram videos
- `dismissHologramCamera()` → `Future<void>` - Dismiss hologram camera

#### Document Liveness Methods
- `performDocumentLiveness(params)` → `Future<OCRAndDocumentLivenessResponse>` - Check document liveness
- `performOCRAndDocumentLiveness(params)` → `Future<OCRAndDocumentLivenessResponse>` - OCR + liveness combined

#### Configuration
- `setOCRUIConfig(config)` → `Future<void>` - Configure UI settings

### Response Types

#### OCRResponse
```dart
class OCRResponse {
  final String responseType; // 'idCard' or 'driverLicense'
  final IDCardOCRResponse? idCardResponse;
  final DriverLicenseOCRResponse? driverLicenseResponse;
}
```

#### IDCardOCRResponse
Contains comprehensive ID card data including:
- Personal information (firstName, lastName, birthDate, etc.)
- Document details (identityNo, expiryDate, etc.)
- MRZ data and validation
- Face image extraction (Base64)
- Security features validation

#### HologramResponse
```dart
class HologramResponse {
  final String? transactionID;
  final bool? hologramExists;
  final bool? ocrIdAndHologramIdMatch;
  final bool? ocrFaceAndHologramFaceMatch;
  final String? hologramFaceImage; // Base64
}
```

#### DocumentLivenessResponse
```dart
class DocumentLivenessResponse {
  final String? aggregateDocumentLivenessProbability; // 0-1 range
  final List<DocumentLivenessPipelineResult>? pipelineResults;
  final String? aggregateDocumentImageQualityWarnings;
}
```

## 🔧 Development

### Project Structure

```
ocr_flutter/
├── lib/
│   ├── ocr_flutter.dart              # Main export
│   └── src/
│       ├── models/ocr_models.dart    # Data models
│       ├── ocr_flutter_platform_interface.dart
│       └── ocr_flutter_method_channel.dart
├── ios/
│   ├── Classes/OcrFlutterPlugin.swift # iOS implementation
│   ├── ocr_flutter.podspec           # CocoaPods spec
│   └── Frameworks/                   # UdentifyOCR frameworks
├── android/
│   ├── build.gradle                  # Android build config
│   ├── libs/                         # AAR files
│   └── src/main/kotlin/com/ocrflutter/
└── pubspec.yaml                      # Package configuration
```

## 🆘 Troubleshooting

### iOS Issues
- **Framework not found**: Add frameworks to `ios/Frameworks/` and rebuild
- **Camera permission**: Add `NSCameraUsageDescription` to Info.plist
- **Build errors**: Clean and rebuild after adding frameworks

### Android Issues
- **AAR files missing**: Add `commons.aar` and `ocr.aar` to `android/libs/`
- **Permission denied**: Request camera permissions at runtime
- **Build errors**: Check that all OCR dependencies are included

### Common Issues
- **Plugin not found**: Run `flutter pub get` after adding dependency
- **Hot reload issues**: Use full restart after native changes
- **Permission errors**: Check camera permissions on device

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Verify framework/AAR installation
3. Check device camera permissions
4. Review Flutter plugin documentation
5. Create issue with device info and logs

## 🔗 Related Projects

- **ocr-turbo** - React Native OCR library
- **ocr-expo** - Expo OCR library
- **nfc-flutter** - Flutter NFC library