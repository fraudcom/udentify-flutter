# Video Call Flutter - Complete Flutter Video Call Plugin

A comprehensive Flutter plugin for video calling using Udentify's SDK. Supports real-time video communication with identity verification capabilities.

## 🎉 Features

- ✅ **Complete Android Implementation** - Full video call functionality with Udentify SDK integration
- ✅ **iOS Implementation Ready** - Structure in place, ready for Udentify SDK integration  
- ✅ **Dart Type Safety** - Full type definitions and code completion
- ✅ **Real-time Communication** - WebSocket-based video calling
- ✅ **Camera Controls** - Toggle camera on/off, switch between front/back cameras
- ✅ **Microphone Controls** - Toggle microphone on/off during calls
- ✅ **Status Tracking** - Real-time call status updates and callbacks
- ✅ **Error Handling** - Comprehensive error handling and user feedback
- ✅ **UI Customization** - Customizable colors, text, and notification messages
- ✅ **Permission Management** - Automatic permission checking and requesting
- ✅ **Cross-Platform** - Identical API for iOS and Android

## 📋 Current Status

- **Android**: ✅ Production Ready - Full video call functionality with Udentify SDK
- **iOS**: ✅ Implementation Complete - Ready for real video calling with Udentify frameworks

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  video_call_flutter:
    path: ../packages/video-call-flutter  # For local development
    # git:
    #   url: https://github.com/your-repo/video-call-flutter
    #   ref: main
```

Then run:
```bash
flutter pub get
```

### Android Setup

1. **Add AAR Files** to `android/app/libs/`:
   - `commons-26.1.3.aar`
   - `vc-26.1.3.aar`

2. **Update app-level `build.gradle`**:
   ```groovy
   dependencies {
       // Video Call dependencies
       implementation 'com.squareup.okhttp3:okhttp:4.12.0'
       implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
       implementation 'com.otaliastudios:cameraview:2.7.2'
       implementation 'com.google.android.material:material:1.4.0'
       implementation 'androidx.activity:activity:1.7.2'
       implementation 'androidx.navigation:navigation-fragment:2.8.3'
       implementation 'com.google.code.gson:gson:2.8.7'
       implementation 'io.livekit:livekit-android:2.12.1'
       
       // Local AAR files
       implementation fileTree(dir: 'libs', include: ['*.aar', '*.jar'], exclude: [])
   }

   android {
       aaptOptions {
           noCompress "tflite"
       }
   }
   ```

3. **Update AndroidManifest.xml** (top-level manifest):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.CAMERA"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.READ_PHONE_STATE"/>
   <uses-feature android:name="android.hardware.camera" android:required="false" />
   <!-- Optional: wifi state if your UI shows network info -->
   <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
   ```

4. **Configure Activity** (only supports Portrait mode):
   ```xml
   <activity
           ...
           android:screenOrientation="portrait"
           android:configChanges="orientation|keyboardHidden">
   ```

5. **Request runtime permissions** in your app:
   ```dart
   await VideoCallFlutter.requestPermissions();
   ```

6. (Alternative) **Maven dependency** (requires GitHub Packages access): add the GitHub repo to your project-level `build.gradle` and include the Udentify VC dependency in app-level `build.gradle`. Ensure `GITHUB_ACTOR` and `GITHUB_TOKEN` env vars are set.

7. **ProGuard/R8 rules** in host app `proguard-rules.pro`:
   ```pro
   # Udentify SDK
   -keep public class io.udentify.** { *; }
   
   # LiveKit (if you experience issues with video calling)
   -keep class io.livekit.** { *; }
   
   # OkHttp3 (networking)
   -dontwarn okhttp3.**
   -dontwarn okio.**
   -keep class okhttp3.** { *; }
   -keep interface okhttp3.** { *; }
   
   # Gson (JSON serialization)
   -keep class com.google.gson.** { *; }
   -keep class * implements com.google.gson.TypeAdapterFactory
   -keep class * implements com.google.gson.JsonSerializer
   -keep class * implements com.google.gson.JsonDeserializer
   
   # CameraView
   -keep class com.otaliastudios.cameraview.** { *; }
   
   # Keep Parcelable classes (for VideoCallOperatorImpl)
   -keep class * implements android.os.Parcelable {
       public static final android.os.Parcelable$Creator *;
   }
   ```

### iOS Setup

**🚀 UdentifyVC is now distributed via Swift Package Manager (SPM) - no manual framework installation required!**

See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for detailed iOS setup guide.

**Quick Setup:**

1. **Add Swift Package Manager Dependency**:
   - Open your iOS project in Xcode (`ios/Runner.xcworkspace`)
   - Go to **File > Swift Packages > Add Package Dependency**
   - Enter URL: `https://github.com/FraudcomMobile/UdentifyVC.git`
   - Add both `UdentifyVC` and `UdentifyCommons` to your app target

2. **Update Info.plist** (add these keys for permission descriptions):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app requires access to the camera for video calling.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app requires access to the microphone for audio during video calls.</string>
   ```

3. **Minimum iOS Version**: Requires iOS 12.0 or later

4. **Access Requirements**: Contact Udentify support team for access to the private UdentifyVC repository

## 🚀 Usage

```dart
import 'package:video_call_flutter/video_call_flutter.dart';

class VideoCallExample extends StatefulWidget {
  @override
  _VideoCallExampleState createState() => _VideoCallExampleState();
}

class _VideoCallExampleState extends State<VideoCallExample> {
  VideoCallStatus _currentStatus = VideoCallStatus.idle;
  bool _isInCall = false;

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    // Set up status change callback
    VideoCallFlutter.setOnStatusChanged((status) {
      setState(() {
        _currentStatus = status;
        _isInCall = status == VideoCallStatus.connected;
      });
    });

    // Set up error callback
    VideoCallFlutter.setOnError((error) {
      print('Video call error: ${error.message}');
    });
  }

  Future<void> _startVideoCall() async {
    // Create credentials
    final credentials = VideoCallCredentials(
      serverURL: "https://your-server.com",
      wssURL: "wss://your-server.com/ws",
      userID: "user_${DateTime.now().millisecondsSinceEpoch}",
      transactionID: "TRX_${DateTime.now().millisecondsSinceEpoch}",
      clientName: "Flutter Client",
      idleTimeout: "30",
    );

    try {
      // Start video call
      final result = await VideoCallFlutter.startVideoCall(credentials);

      if (result.success) {
        print('Video call started successfully');
        print('Transaction ID: ${result.transactionID}');
      } else {
        print('Video call failed: ${result.error?.message}');
      }
    } catch (e) {
      print('Error starting video call: $e');
    }
  }

  Future<void> _endVideoCall() async {
    try {
      final result = await VideoCallFlutter.endVideoCall();
      
      if (result.success) {
        print('Video call ended successfully');
      } else {
        print('Failed to end video call: ${result.error?.message}');
      }
    } catch (e) {
      print('Error ending video call: $e');
    }
  }

  Future<void> _toggleCamera() async {
    try {
      final isEnabled = await VideoCallFlutter.toggleCamera();
      print('Camera ${isEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('Error toggling camera: $e');
    }
  }

  Future<void> _toggleMicrophone() async {
    try {
      final isEnabled = await VideoCallFlutter.toggleMicrophone();
      print('Microphone ${isEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      print('Error toggling microphone: $e');
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await VideoCallFlutter.checkPermissions();
      print('Camera Permission: ${permissions.hasCameraPermission}');
      print('Phone State Permission: ${permissions.hasPhoneStatePermission}');
      print('Internet Permission: ${permissions.hasInternetPermission}');
      print('Microphone Permission: ${permissions.hasRecordAudioPermission}');
    } catch (e) {
      print('Error checking permissions: $e');
    }
  }

  Future<void> _setVideoCallConfig() async {
    try {
      final config = VideoCallConfig(
        backgroundColor: "#FF000000",
        textColor: "#FFFFFFFF",
        pipViewBorderColor: "#FFFFFFFF",
        notificationLabelDefault: "Video Call will be starting, please wait...",
        notificationLabelCountdown: "Video Call will be started in %d sec/s.",
        notificationLabelTokenFetch: "Authorizing the user...",
      );

      await VideoCallFlutter.setVideoCallConfig(config);
      print('Video call configuration set');
    } catch (e) {
      print('Error setting configuration: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Video Call Example')),
      body: Column(
        children: [
          Text('Status: $_currentStatus'),
          
          ElevatedButton(
            onPressed: _isInCall ? null : _startVideoCall,
            child: Text('Start Video Call'),
          ),
          
          ElevatedButton(
            onPressed: _isInCall ? _endVideoCall : null,
            child: Text('End Video Call'),
          ),
          
          if (_isInCall) ...[
            ElevatedButton(
              onPressed: _toggleCamera,
              child: Text('Toggle Camera'),
            ),
            ElevatedButton(
              onPressed: _toggleMicrophone,
              child: Text('Toggle Microphone'),
            ),
          ],
          
          ElevatedButton(
            onPressed: _checkPermissions,
            child: Text('Check Permissions'),
          ),
          
          ElevatedButton(
            onPressed: _setVideoCallConfig,
            child: Text('Set Config'),
          ),
        ],
      ),
    );
  }
}
```

## 📱 API Reference

### Classes

#### `VideoCallFlutter`
Main plugin class for video call operations.

#### `VideoCallCredentials`
Credentials for video call authentication:
- `serverURL`: Server URL for video call service
- `wssURL`: WebSocket URL for real-time communication
- `userID`: Unique user identifier
- `transactionID`: Transaction identifier
- `clientName`: Client application name
- `idleTimeout`: Timeout in seconds (optional, default: "30")

#### `VideoCallResult`
Result returned from video call operations:
- `success`: Whether the operation was successful
- `status`: Current video call status (optional)
- `transactionID`: Transaction identifier (optional)
- `error`: Error information if failed (optional)
- `metadata`: Additional metadata (optional)

#### `VideoCallPermissionStatus`
Permission status:
- `hasCameraPermission`: Camera permission status
- `hasPhoneStatePermission`: Phone state permission status
- `hasInternetPermission`: Internet permission status
- `hasRecordAudioPermission`: Microphone/record audio permission status

#### `VideoCallConfig`
UI configuration options:
- `backgroundColor`: Background color (hex string)
- `textColor`: Text color (hex string)
- `pipViewBorderColor`: Picture-in-picture border color (hex string)
- `notificationLabelDefault`: Default notification message
- `notificationLabelCountdown`: Countdown notification message
- `notificationLabelTokenFetch`: Token fetch notification message

### Enums

#### `VideoCallStatus`
- `idle`: No active call
- `connecting`: Connecting to call
- `connected`: Call is active
- `disconnected`: Call disconnected
- `failed`: Call failed
- `completed`: Call completed successfully

#### `VideoCallErrorType`
- `unknown`: Unknown error
- `credentialsMissing`: Required credentials missing
- `serverTimeout`: Server timeout
- `transactionNotFound`: Transaction not found
- `transactionFailed`: Transaction failed
- `transactionExpired`: Transaction expired
- `transactionAlreadyCompleted`: Transaction already completed
- `sdkNotAvailable`: Udentify SDK not available or properly integrated

### Methods

#### Core Methods
- `startVideoCall(credentials)` → `Future<VideoCallResult>` - Start video call
- `endVideoCall()` → `Future<VideoCallResult>` - End video call
- `getVideoCallStatus()` → `Future<VideoCallStatus>` - Get current status

#### Permission Methods
- `checkPermissions()` → `Future<VideoCallPermissionStatus>` - Check permissions
- `requestPermissions()` → `Future<String>` - Request permissions

#### Control Methods
- `toggleCamera()` → `Future<bool>` - Toggle camera on/off
- `switchCamera()` → `Future<bool>` - Switch between front/back cameras
- `toggleMicrophone()` → `Future<bool>` - Toggle microphone on/off

#### Configuration Methods
- `setVideoCallConfig(config)` → `Future<void>` - Set UI configuration
- `dismissVideoCall()` → `Future<void>` - Dismiss video call UI

#### Callback Methods
- `setOnStatusChanged(callback)` → `void` - Set status change callback
- `setOnError(callback)` → `void` - Set error callback

## 🧪 Testing

To test the plugin functionality, you need to have the Udentify SDK properly integrated as described in the setup sections above. The plugin **requires** the actual Udentify SDK frameworks to function - no simulation mode is available.

**Prerequisites for Testing:**
- Android: AAR files (`commons-26.1.3.aar`, `vc-26.1.3.aar`) properly placed in `android/app/libs/`
- iOS: UdentifyVC frameworks (`UdentifyCommons.xcframework`, `UdentifyVC.xcframework`) in `ios/Frameworks/`
- All required permissions granted
- Valid server URLs and credentials

**What you can test:**
- Permission checking and requesting
- Video call configuration settings  
- Real video call start/end functionality with Udentify SDK
- Camera and microphone control APIs
- Status tracking and error handling callbacks
- UI customization options

**Note:** If the SDK is not properly integrated, the plugin will return `ERR_SDK_NOT_AVAILABLE` error instead of falling back to simulation.

## 🔧 Development

### Project Structure

```
video-call-flutter/
├── lib/
│   ├── video_call_flutter.dart         # Main plugin API
│   └── src/
│       ├── video_call_flutter_platform_interface.dart
│       ├── video_call_flutter_method_channel.dart
│       └── models/
│           └── video_call_models.dart   # Data models
├── android/                             # Android implementation
│   ├── src/main/kotlin/com/videocallflutter/
│   │   ├── VideoCallFlutterPlugin.kt
│   │   └── VideoCallOperatorImpl.kt
│   ├── libs/                            # Udentify AAR files
│   └── build.gradle
├── ios/                                 # iOS implementation
│   ├── Classes/
│   │   └── VideoCallFlutterPlugin.swift
│   ├── Frameworks/                      # UdentifyVC frameworks
│   └── video_call_flutter.podspec
└── example/                             # Example app (use testApplicationFlutter instead)
```

### Building

To build the plugin:

```bash
# Android
cd android && ./gradlew build

# iOS
cd ios && pod install

# Flutter
flutter pub get
flutter analyze
```

## 🎨 UI Customization

### Colors

Customize video call UI colors:

```dart
final config = VideoCallConfig(
  backgroundColor: "#FF000000",        // Black background
  textColor: "#FFFFFFFF",             // White text
  pipViewBorderColor: "#FFFFFFFF",    // White border for PiP view
);

await VideoCallFlutter.setVideoCallConfig(config);
```

### Notification Messages

Customize notification messages:

```dart
final config = VideoCallConfig(
  notificationLabelDefault: "Video Call will be starting, please wait...",
  notificationLabelCountdown: "Video Call will be started in %d sec/s.",
  notificationLabelTokenFetch: "Authorizing the user...",
);

await VideoCallFlutter.setVideoCallConfig(config);
```

## 🆘 Troubleshooting

### Android Issues
- **AAR files not found**: Place AAR files in `android/app/libs/`
- **Permission denied**: Request camera and phone state permissions at runtime
- **Build errors**: Ensure all video call dependencies are included
- **Portrait mode issues**: Configure activity orientation in AndroidManifest.xml
 - **Callbacks**: Status updates are delivered via `onStatusChanged` and errors via `onError` from the native layer. Ensure you register callbacks before starting a call.

### iOS Issues  
- **Framework not found**: Add UdentifyVC frameworks to `ios/Frameworks/`
- **Camera permission**: Add NSCameraUsageDescription to Info.plist
- **Build errors**: Clean and rebuild after adding frameworks

### Common Issues
- **Plugin not found**: Run `flutter pub get` and restart your IDE
- **Build errors**: Clean and rebuild: `flutter clean && flutter pub get`
- **Hot reload issues**: Use hot restart instead of hot reload after plugin changes
- **WebSocket connection**: Ensure WSS URL is correct and server is running

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Verify framework/AAR installation
3. Check device camera and microphone permissions
4. Review server and WebSocket URLs
5. Create issue with device info, logs, and error details

## 🔗 Related Projects

- **nfc-flutter** - Flutter NFC library for passport reading
- **ocr-flutter** - Flutter OCR library for document scanning
- **mrz-flutter** - Flutter MRZ library for document parsing

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
