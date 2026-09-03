# Udentify Core Flutter

Core shared components for Udentify Flutter libraries, including SSL certificate pinning and remote language pack functionality.

## Overview

`udentify-core-flutter` provides:
1. **SSL Certificate Pinning** - Secure SSL/TLS communication
2. **Remote Language Pack** - Dynamic localization updates from server
3. **Shared UdentifyCommons Framework** - Required by all Udentify libraries:
   - **OCR Library** (`ocr-flutter`)
   - **NFC Library** (`nfc-flutter`) 
   - **Liveness Library** (`liveness-flutter`)

## Architecture

```
udentify-core-flutter (Provides UdentifyCommons + SSL Pinning + Remote Language Pack)
├── OCR Library (Uses UdentifyOCR + UdentifyCommons)
├── NFC Library (Uses UdentifyNFC + UdentifyCommons)  
└── Liveness Library (Uses UdentifyFACE + UdentifyCommons)
```

## SSL Certificate Pinning

SSL pinning is a security technique that allows your application to verify if the server certificate is the one it expects.

### Important

**SSL pinning and Remote Language Pack should be configured BEFORE using any Udentify modules** to ensure the configurations are applied correctly from the start of the application's lifecycle.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  udentify_core_flutter: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Load Certificate from App Bundle/Assets (Recommended)

Place your certificate file (`.cer` or `.der` format, DER-encoded) in:
- **iOS**: Add to your Xcode project bundle
- **Android**: Place in `android/app/src/main/assets/`

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

// Load and set certificate
try {
  await UdentifyCoreFlutter.loadCertificateFromAssets('MyServerCertificate', 'cer');
  print('SSL Pinning configured successfully');
} catch (error) {
  print('Failed to setup SSL pinning: $error');
}
```

### Set Certificate from Base64 String

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

const base64Cert = "MIIDXTCCAkWgAwIBAgIJAK...";
try {
  await UdentifyCoreFlutter.setSSLCertificateBase64(base64Cert);
  print('SSL certificate set successfully');
} catch (error) {
  print('Failed to set SSL certificate: $error');
}
```

### Check SSL Pinning Status

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

final isEnabled = await UdentifyCoreFlutter.isSSLPinningEnabled();
print('SSL Pinning enabled: $isEnabled');
```

### Remove Certificate

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

try {
  await UdentifyCoreFlutter.removeSSLCertificate();
  print('SSL certificate removed');
} catch (error) {
  print('Failed to remove SSL certificate: $error');
}
```

### Get Certificate as Base64

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

final cert = await UdentifyCoreFlutter.getSSLCertificateBase64();
if (cert != null) {
  print('Certificate is set');
} else {
  print('No certificate configured');
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Configure SSL pinning BEFORE using any Udentify modules
    setupSSLPinning();
  }

  Future<void> setupSSLPinning() async {
    try {
      await UdentifyCoreFlutter.loadCertificateFromAssets('MyServerCertificate', 'cer');
      print('SSL Pinning configured successfully');
      
      // Verify SSL pinning is enabled
      final isEnabled = await UdentifyCoreFlutter.isSSLPinningEnabled();
      print('SSL Pinning enabled: $isEnabled');
    } catch (error) {
      print('Failed to setup SSL pinning: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Udentify Core Example'),
        ),
        body: const Center(
          child: Text('SSL Pinning Configured'),
        ),
      ),
    );
  }
}
```

## Certificate Format

- **Format**: DER (Distinguished Encoding Rules)
- **Extensions**: `.cer` or `.der`
- **Type**: X.509 certificate

### Convert PEM to DER format

If you have a PEM certificate, convert it to DER format:

```bash
openssl x509 -in certificate.pem -outform der -out certificate.cer
```

## API Reference

### `loadCertificateFromAssets(String certificateName, String extension)`

Load a certificate from the app bundle/assets and set it for SSL pinning.

- **certificateName**: Name of the certificate file without extension
- **extension**: File extension ('cer' or 'der')
- **Returns**: `Future<bool>` - true if successful

### `setSSLCertificateBase64(String certificateBase64)`

Set SSL certificate using base64 encoded data.

- **certificateBase64**: Base64 encoded certificate data (DER format)
- **Returns**: `Future<bool>` - true if successful

### `removeSSLCertificate()`

Remove the currently set SSL certificate, disabling SSL pinning.

- **Returns**: `Future<bool>` - true if successful

### `getSSLCertificateBase64()`

Get the currently set SSL certificate as base64 string.

- **Returns**: `Future<String?>` - base64 string or null if not set

### `isSSLPinningEnabled()`

Check if SSL pinning is currently enabled.

- **Returns**: `Future<bool>` - true if enabled

## Remote Language Pack

The Remote Language Pack feature allows you to update localization values in real-time without needing to update the mobile app itself. This enables you to modify localization values through the Udentify Dashboard.

### Important Notes

- It is crucial to retain default localization key-values in your localization files as a fallback
- Remote language pack should be configured before using other Udentify modules
- The SDK uses the localization map automatically in the background
- If the remote language pack cannot be retrieved, the app falls back to default values

### Usage

#### Instantiate Server-Based Localization

Download and apply localization from the server:

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

// Get system language or use default
final systemLanguage = await UdentifyCoreFlutter.mapSystemLanguageToEnum();
final language = systemLanguage ?? 'EN';

// Instantiate localization
await UdentifyCoreFlutter.instantiateServerBasedLocalization(
  language,
  'https://api.udentify.com',
  'transaction-id-123',
  requestTimeout: 30.0,
);
```

#### Get Localization Map (Debugging)

Retrieve the current localization map:

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

final localizationMap = await UdentifyCoreFlutter.getLocalizationMap();
if (localizationMap != null) {
  print('Total entries: ${localizationMap.length}');
  print('Sample entry: ${localizationMap['key']}');
}
```

#### Clear Localization Cache

Remove cached localization for a specific language:

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

await UdentifyCoreFlutter.clearLocalizationCache('EN');
```

#### Map System Language

Detect the user's system language:

```dart
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

final systemLanguage = await UdentifyCoreFlutter.mapSystemLanguageToEnum();
print('System language: $systemLanguage');
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Configure SSL and localization BEFORE using Udentify modules
    initializeUdentify();
  }

  Future<void> initializeUdentify() async {
    try {
      // 1. Setup SSL Pinning
      await UdentifyCoreFlutter.loadCertificateFromAssets('MyServerCertificate', 'cer');
      print('SSL Pinning configured');

      // 2. Setup Remote Localization
      final language = await UdentifyCoreFlutter.mapSystemLanguageToEnum() ?? 'EN';
      await UdentifyCoreFlutter.instantiateServerBasedLocalization(
        language,
        'https://api.udentify.com',
        'your-transaction-id',
      );
      print('Localization configured');

      // 3. Now safe to use other Udentify modules
    } catch (error) {
      print('Failed to initialize Udentify: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Udentify Core Example'),
        ),
        body: const Center(
          child: Text('SSL Pinning & Localization Configured'),
        ),
      ),
    );
  }
}
```

### Supported Languages

The SDK supports the following language codes:
- `EN` - English
- `TR` - Turkish
- `FR` - French
- `DE` - German
- `ES` - Spanish
- `IT` - Italian
- `PT` - Portuguese
- `RU` - Russian
- `AR` - Arabic
- `ZH` - Chinese
- `JA` - Japanese
- `KO` - Korean
- `HI` - Hindi
- `BN` - Bengali
- `PA` - Punjabi
- `UR` - Urdu
- `ID` - Indonesian
- `MS` - Malay
- `SW` - Swahili
- `TA` - Tamil

### Error Handling

```dart
try {
  await UdentifyCoreFlutter.instantiateServerBasedLocalization(
    'EN',
    serverUrl,
    transactionId,
  );
} catch (error) {
  // Handle errors:
  // - Invalid language or network error
  // - Network timeout or server unavailable
  print('Localization error: $error');
  // App will fall back to default localization strings
}
```

## API Reference (Remote Language Pack)

### `instantiateServerBasedLocalization(String language, String serverUrl, String transactionId, {double requestTimeout = 30.0})`

Download and instantiate server-based localization.

- **language**: Language code (e.g., 'EN', 'FR', 'TR')
- **serverUrl**: URL of the Udentify API Server
- **transactionId**: Transaction ID from Udentify API Server
- **requestTimeout**: Timeout in seconds (default: 30.0)
- **Returns**: `Future<void>` - completes when localization is instantiated

### `getLocalizationMap()`

Get the current localization map (for debugging).

- **Returns**: `Future<Map<String, String>?>` - localization map or null if not available

### `clearLocalizationCache(String language)`

Clear cached localization for a specific language.

- **language**: Language code to clear
- **Returns**: `Future<void>` - completes when cache is cleared

### `mapSystemLanguageToEnum()`

Map system language to SDK language code.

- **Returns**: `Future<String?>` - language code or null if not supported

## Platform Support

### iOS
- **Framework**: `UdentifyCommons.xcframework`
- **Location**: `ios/Frameworks/UdentifyCommons.xcframework`
- **Min Version**: iOS 11.0+

### Android
- **Library**: `commons-25.2.1.aar`
- **Location**: `android/libs/commons-25.2.1.aar`
- **Min Version**: Android API Level 21+

## Troubleshooting

### iOS: Certificate not found

Make sure the certificate file is added to your Xcode project:
1. Open your iOS project in Xcode
2. Right-click on the project and select "Add Files to..."
3. Select your certificate file
4. Ensure "Copy items if needed" is checked
5. Ensure the file is added to your app target

### Android: Certificate not found

Make sure the certificate file is placed in `android/app/src/main/assets/`:

```bash
mkdir -p android/app/src/main/assets
cp your-certificate.cer android/app/src/main/assets/
```

### SSL Pinning not working

Ensure you configure SSL pinning BEFORE using any other Udentify modules. The best place is in your app's initialization code (e.g., `main()` or app widget's `initState()`).

## Version

Current version: **1.0.0**

Compatible with:
- Flutter >= 3.3.0
- Dart >= 3.5.4

## License

MIT

## Support

For issues, questions, or feature requests, please contact Udentify support.

