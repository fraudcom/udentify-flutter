# video-call-flutter

Flutter plugin for Udentify video calling. A thin bridge over the native Udentify SDKs: it hands your
values to the SDK and reports what the SDK emits. The call screen, the media connection and the
agent hand-off are the SDK's.

- Start, end and cancel a video call with an agent, with the SDK's own full-screen call UI
- Status, error, participant, microphone, phone-call and screen-lock events
- Microphone control through the SDK's own API
- LiveKYC: the operator can ask for an OCR, face or NFC redo without leaving the call
- Typed errors, including missing camera / microphone permissions

**Usage, events, ending a call, LiveKYC and troubleshooting are in the [usage guide](USAGE.md).**

**Native SDK:** Udentify 26.3.0928 (Android `commons` + `vc` AARs, iOS `UdentifyVC` + `UdentifyLiveKYC`
xcframeworks, both bundled in the plugin except the Android AARs, which the app supplies).
Android `minSdk` 21, iOS 13.0.

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
   - `commons-26.3.0928.aar`
   - `vc-26.3.0928.aar`

2. **Update app-level `build.gradle`**. The plugin already declares the libraries below itself, so an app normally only needs the `fileTree` line that exposes the AARs; the rest is listed for apps that manage these versions explicitly:
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
       implementation 'io.livekit:livekit-android:2.13.0'
       
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
   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
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

5. **Use `FlutterFragmentActivity`** as the host activity. The call screen is an SDK fragment, which needs a `FragmentActivity`; Flutter's template extends `FlutterActivity`, which is not one, and without this the call fails with `NO_ACTIVITY` (the message says the host activity must extend `FlutterFragmentActivity`).
   ```kotlin
   import io.flutter.embedding.android.FlutterFragmentActivity

   class MainActivity : FlutterFragmentActivity()
   ```

   **Request runtime permissions** in your app (the call resolves with `granted` or `denied` once the user answers):
   ```dart
   await VideoCallFlutter.requestPermissions();
   ```

6. (Alternative) **Maven dependency** (requires GitHub Packages access): add the GitHub repo to your project-level `build.gradle` and include the Udentify VC dependency in app-level `build.gradle`. Ensure `GITHUB_ACTOR` and `GITHUB_TOKEN` env vars are set.

7. **ProGuard/R8 rules.** The plugin ships a `consumer-rules.pro` that keeps `io.udentify.**` and `io.livekit.**`, so nothing is needed for those. Flutter enables R8 for release builds by default. Only if you want them, the networking rules:
   ```pro
   
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

`UdentifyVC.xcframework` is bundled with the plugin (`ios/Frameworks/`) and pulled in by CocoaPods; `UdentifyCommons` comes from `udentify_core_flutter`. The LiveKit Swift SDK is compiled into `UdentifyVC`, so the plugin depends on `LiveKitWebRTC` only — do **not** add `LiveKitClient` to your app.

1. **Declare the LiveKit spec repo** in your app's `ios/Podfile`, above the targets:
   ```ruby
   source 'https://cdn.cocoapods.org/'
   source 'https://github.com/livekit/podspecs.git'
   ```
   Then run `pod install` from `ios/`. If Xcode reports stale module errors after an SDK upgrade, clear `ModuleCache.noindex` (Xcode > Product > Clean Build Folder, or delete it from DerivedData).

2. **Update Info.plist** (add these keys for permission descriptions):
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>This app requires access to the camera for video calling.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app requires access to the microphone for audio during video calls.</string>
   ```

3. **Minimum iOS Version**: Requires iOS 13.0 or later

## Quick start

```dart
import 'package:video_call_flutter/video_call_flutter.dart';

VideoCallFlutter.setOnStatusChanged((status) => print('status: $status'));
VideoCallFlutter.setOnError((error) => print('${error.type}: ${error.message}'));

await VideoCallFlutter.requestPermissions();

final result = await VideoCallFlutter.startVideoCall(VideoCallCredentials(
  serverURL: 'https://your-server.com',
  wssURL: 'wss://your-server.com/ws',
  userID: 'user-123',
  transactionID: transactionIdFromYourBackend,
  clientName: 'Flutter Client',
));

// To hang up (also ends the agent's session):
await VideoCallFlutter.cancelVideoCall();
```

Register the callbacks **before** `startVideoCall`. See the [usage guide](USAGE.md) for everything else.

## Tests

```bash
../../scripts/run-tests.sh video-call-flutter
```

These cover the Dart layer (models, channel calls, the events the native side sends). The Kotlin and
Swift code is verified by building `testApplicationFlutter`. A real call needs the native SDKs, a
reachable server and an agent.

## Related packages

`udentify-core-flutter` (required), `ocr-flutter`, `liveness-flutter`, `nfc-flutter`, `mrz-flutter`.

## License

MIT, see the LICENSE file.
