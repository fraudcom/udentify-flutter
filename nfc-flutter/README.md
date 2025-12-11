# NFC Flutter - Complete Flutter NFC Plugin

A production-ready Flutter plugin for NFC passport reading using Udentify's SDK.

## 🎉 Features

- ✅ **Complete iOS Implementation** - Full NFC reading with UdentifyNFC framework
- ✅ **Android Implementation Ready** - Compiles successfully, ready for Udentify SDK integration  
- ✅ **Dart Type Safety** - Full type definitions and code completion
- ✅ **Progress Tracking** - Real-time progress updates during NFC reading
- ✅ **Error Handling** - Comprehensive error handling and user feedback
- ✅ **Authentication Support** - Passive Authentication (PA) and Active Authentication (AA)
- ✅ **NFC Location Detection** - Automatic NFC antenna position detection
- ✅ **Cross-Platform** - Identical API for iOS and Android

## 📋 Current Status

- **iOS**: ✅ Production Ready - Full NFC functionality
- **Android**: ✅ Implementation Complete - Ready for real NFC reading with Udentify AAR files

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  nfc_flutter:
    path: ../nfc-flutter  # For local development
    # git:
    #   url: https://github.com/your-repo/nfc-flutter
    #   ref: main
```

Then run:
```bash
flutter pub get
```

### iOS Setup

1. **Add UdentifyNFC frameworks** to `ios/Frameworks/`:
   - `UdentifyCommons.xcframework`
   - `UdentifyNFC.xcframework`

2. **Add NFC capability** in Xcode:
   - Go to your app target → **Signing & Capabilities**
   - Click **+ Capability** and add **"Near Field Communication Tag Reading"**

3. **Update Info.plist**:
   ```xml
   <key>NFCReaderUsageDescription</key>
   <string>This app uses NFC to scan passports and ID documents</string>
   <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
   <array>
      <string>A0000002471001</string>
   </array>
   ```

### Android Setup  

1. **Add AAR Files** to `android/app/libs/`:
   - `commons-25.3.0.aar`
   - `nfc-25.3.0.aar`

2. **Update AndroidManifest.xml** (top-level manifest):
   ```xml
   <uses-permission android:name="android.permission.NFC" />
   <uses-permission android:name="android.permission.READ_PHONE_STATE" />
   
   <uses-feature
       android:name="android.hardware.nfc"
       android:required="true" />
   ```

3. (Alternative) **Maven dependency** (requires GitHub Packages access): add to project-level `build.gradle` and app-level dependencies per docs, with `GITHUB_ACTOR` and `GITHUB_TOKEN` env vars.

4. **ProGuard/R8 rules** in host app `proguard-rules.pro`:
   ```pro
   -keep public class io.udentify.** { *; }
   -keep public class org.bouncycastle.** { *; }
   -keep public class net.sf.scuba.** { *; }
   ```

5. **Request runtime permissions** in your app:
   ```dart
   await nfcFlutter.requestPermissions();
   ```

## 🚀 Usage

```dart
import 'package:nfc_flutter/nfc_flutter.dart';

class NfcExample extends StatefulWidget {
  @override
  _NfcExampleState createState() => _NfcExampleState();
}

class _NfcExampleState extends State<NfcExample> {
  final NfcFlutter _nfcFlutter = NfcFlutter();

  Future<void> readPassport() async {
    // Create parameters
    final params = NfcPassportParams(
      documentNumber: "123456789",
      dateOfBirth: "900101",      // YYMMDD format
      expiryDate: "300101",       // YYMMDD format
      transactionID: "TX_123",
      serverURL: "https://your-server.com",
      requestTimeout: 10,
      isActiveAuthenticationEnabled: true,
      isPassiveAuthenticationEnabled: true,
    );

    try {
      // Read passport with progress tracking
      final passport = await _nfcFlutter.readPassport(
        params,
        onProgress: (progress) {
          print('Reading progress: ${(progress * 100).toInt()}%');
        },
      );

      if (passport != null) {
        print('First Name: ${passport.firstName}');
        print('Last Name: ${passport.lastName}');
        print('Passive Auth: ${passport.passedPA}');
        print('Active Auth: ${passport.passedAA}');
        
        if (passport.image != null) {
          // Display base64 encoded image
          print('Photo available');
        }
      }
    } catch (e) {
      print('Error reading passport: $e');
    }
  }

  Future<void> checkPermissions() async {
    try {
      final permissions = await _nfcFlutter.checkPermissions();
      print('Phone State Permission: ${permissions.hasPhoneStatePermission}');
      print('NFC Permission: ${permissions.hasNfcPermission}');
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> getNfcLocation() async {
    try {
      final location = await _nfcFlutter.getNfcLocation('https://your-server.com');
      print('NFC Location: $location');
    } catch (e) {
      print('Error getting NFC location: $e');
    }
  }

  Future<void> cancelReading() async {
    try {
      await _nfcFlutter.cancelReading();
      print('Reading cancelled');
    } catch (e) {
      print('Error cancelling: $e');
    }
  }
}
```

## 📱 API Reference

### Classes

#### `NfcFlutter`
Main plugin class for NFC operations.

#### `NfcPassportParams`
Parameters for passport reading:
- `documentNumber`: Document number from passport
- `dateOfBirth`: Birth date in YYMMDD format
- `expiryDate`: Expiry date in YYMMDD format
- `transactionID`: Transaction identifier
- `serverURL`: Udentify server URL
- `requestTimeout`: Timeout in seconds (optional, default: 10)
- `isActiveAuthenticationEnabled`: Enable AA (optional, default: true)
- `isPassiveAuthenticationEnabled`: Enable PA (optional, default: true)

#### `NfcPassport`
Passport data returned from reading:
- `image`: Base64 encoded photo (optional)
- `firstName`: First name (optional)
- `lastName`: Last name (optional)
- `passedPA`: Passive Authentication result
- `passedAA`: Active Authentication result

#### `PermissionStatus`
Permission status:
- `hasPhoneStatePermission`: READ_PHONE_STATE permission status
- `hasNfcPermission`: NFC permission status

### Enums

#### `AuthenticationResult`
- `disabled`: Authentication was disabled
- `success`: Authentication passed
- `failed`: Authentication failed
- `notSupported`: Authentication not supported

#### `NfcLocation`
- `unknown`: Location unknown
- `frontTop`, `frontCenter`, `frontBottom`: Front positions
- `rearTop`, `rearCenter`, `rearBottom`: Rear positions

## 🧪 Testing

A complete test application is available in the `testApplicationFlutter` directory. To run it:

```bash
cd testApplicationFlutter
flutter run
```

The test app includes:
- Permission checking and requesting
- Form for entering passport parameters
- NFC reading with progress tracking
- Cancel functionality
- NFC location detection
- Results display

## 🔧 Development

### Project Structure

```
nfc-flutter/
├── lib/                          # Dart code
│   ├── nfc_flutter.dart         # Main plugin API
│   ├── nfc_flutter_platform_interface.dart
│   └── nfc_flutter_method_channel.dart
├── ios/                         # iOS implementation
│   ├── Classes/
│   │   └── NfcFlutterPlugin.swift
│   ├── Frameworks/              # UdentifyNFC frameworks
│   └── nfc_flutter.podspec
├── android/                     # Android implementation
│   ├── src/main/kotlin/com/nfcflutter/
│   │   └── NfcFlutterPlugin.kt
│   ├── libs/                    # Udentify AAR files
│   └── build.gradle
└── example/                     # Example app (use testApplicationFlutter instead)
```

### Building

To build the plugin:

```bash
# iOS
cd ios && pod install

# Android
cd android && ./gradlew build

# Flutter
flutter pub get
flutter analyze
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### iOS Issues
- **Framework not found**: Ensure UdentifyNFC frameworks are in `ios/Frameworks/`
- **NFC capability missing**: Add NFC capability in Xcode project settings
- **Info.plist missing**: Add NFCReaderUsageDescription and NFC identifiers

### Android Issues  
- **AAR files not found**: Place AAR files in `android/app/libs/`
- **Permission denied**: Request READ_PHONE_STATE permission at runtime
- **NFC not available**: Check device has NFC hardware and it's enabled

### Common Issues
- **Plugin not found**: Run `flutter pub get` and restart your IDE
- **Build errors**: Clean and rebuild: `flutter clean && flutter pub get`
- **Hot reload issues**: Use hot restart instead of hot reload after plugin changes

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Search existing issues in the repository  
3. Create a new issue with detailed information
4. Include device information, Flutter version, and error logs