# nfc_flutter

Flutter plugin for reading NFC-enabled identity documents (e-passports and eID cards) with the Udentify SDK. It performs Basic Access Control (BAC/PACE), reads the passport data groups, and runs **Passive Authentication (PA)** and **Active Authentication (AA)**.

- **Version:** 26.1.3
- **Platforms:** Android (API 21+) · iOS (13.0+)
- **Requires:** a valid Udentify SDK licence, a physical NFC-capable device, and the shared [`udentify_core_flutter`](../udentify-core-flutter) plugin.

> NFC cannot be tested on a simulator/emulator. A real device with an NFC antenna is required.

---

## Table of contents

1. [How it works](#how-it-works)
2. [Requirements](#requirements)
3. [Installation](#installation)
4. [Android setup](#android-setup)
5. [iOS setup](#ios-setup)
6. [Usage](#usage)
7. [API reference](#api-reference)
8. [Parameter formats](#parameter-formats)
9. [Troubleshooting](#troubleshooting)

---

## How it works

The MRZ fields — **document number**, **date of birth**, **date of expiry** — are the key that unlocks the chip. You obtain them first (typically from the [`mrz_flutter`](../mrz-flutter) scanner or an OCR result) and pass them to `readPassport()`. The plugin then:

1. Opens the platform NFC reader session.
2. Derives the BAC/PACE key from the three MRZ fields and establishes a secure channel with the chip.
3. Reads the data groups (photo, name, …) while reporting progress.
4. Runs Passive Authentication (data integrity) and, if the chip supports it, Active Authentication (anti-cloning).
5. Returns an [`NfcPassport`](#nfcpassport).

---

## Requirements

| | Minimum |
|---|---|
| Flutter | 3.3.0 |
| Dart | 3.5.4 |
| Android | API 21 (compile/target SDK 34) |
| iOS | **13.0** (CoreNFC ISO 7816 tag reading) |
| Device | Physical device with NFC hardware |
| Licence | Valid Udentify SDK licence |

`nfc_flutter` depends on `udentify_core_flutter`, which supplies the shared `UdentifyCommons` framework (iOS) and `commons` AAR (Android). Always add the core plugin alongside this one.

---

## Installation

Add both the NFC plugin and the shared core plugin to your app's `pubspec.yaml`:

```yaml
dependencies:
  nfc_flutter:
    git:
      url: https://github.com/fraudcom/udentify-flutter.git
      path: packages/nfc-flutter
  udentify_core_flutter:
    git:
      url: https://github.com/fraudcom/udentify-flutter.git
      path: packages/udentify-core-flutter
```

Or, for local development against a checkout of this repo:

```yaml
dependencies:
  nfc_flutter:
    path: ../packages/nfc-flutter
  udentify_core_flutter:
    path: ../packages/udentify-core-flutter
```

Then:

```bash
flutter pub get
```

---

## Android setup

The plugin bundles `nfc-26.1.3.aar` and declares the Udentify SDK as `compileOnly`, so **the host app must make the native SDK available at runtime**. Choose one of the two options below, then add the third-party dependencies and permissions.

### Native SDK — Option A: Maven / GitHub Packages (recommended for production)

In your **project-level** `android/build.gradle` (or `settings.gradle` `dependencyResolutionManagement`):

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

In your **app-level** `android/app/build.gradle`:

```groovy
implementation 'com.fraud.udentify.android.sdk:commons:26.1.3'
implementation 'com.fraud.udentify.android.sdk:nfc:26.1.3'
```

`GITHUB_ACTOR` / `GITHUB_TOKEN` are a GitHub username and a Personal Access Token with `read:packages` scope. **Contact Udentify support** to be granted access — the exact repository URL and credentials are provided with your licence.

### Native SDK — Option B: Bundled AAR files (manual)

The AAR files ship inside the plugins. Copy them into your app's `android/app/libs/` folder…

- `commons-26.1.3.aar` (from `packages/udentify-core-flutter/android/libs/`)
- `nfc-26.1.3.aar` (from `packages/nfc-flutter/android/libs/`)

…and reference them in `android/app/build.gradle`:

```groovy
implementation fileTree(dir: 'libs', include: ['*.aar'])
```

### Required third-party dependencies (both options)

Add these to `android/app/build.gradle` — they are transitive dependencies of the NFC SDK and are **not** pulled in automatically:

```groovy
implementation 'org.jmrtd:jmrtd:0.7.17'                 // ICAO 9303 / passport reading
implementation 'net.sf.scuba:scuba-sc-android:0.0.19'   // smartcard I/O
implementation 'edu.ucar:jj2000:5.2'                    // JPEG2000 decoding of the DG2 photo
implementation 'com.squareup.okhttp3:okhttp:4.12.0'
implementation 'com.squareup.okhttp3:okhttp-tls:4.12.0'
implementation 'com.google.code.gson:gson:2.8.7'
implementation 'com.google.android.material:material:1.4.0'
```

### Permissions

The plugin's manifest already declares `NFC`, `INTERNET` and `READ_PHONE_STATE`. Set `android.hardware.nfc` to `required="true"` in your **app** manifest if NFC is mandatory:

```xml
<uses-feature android:name="android.hardware.nfc" android:required="true" />
```

`READ_PHONE_STATE` is a runtime permission — request it before reading (see [`requestPermissions()`](#permissions)).

### ProGuard / R8 (release builds)

```pro
-keep public class io.udentify.** { *; }
-keep public class org.jmrtd.** { *; }
-keep public class net.sf.scuba.** { *; }
-keep public class org.bouncycastle.** { *; }
```

---

## iOS setup

The plugin **vendors `UdentifyNFC.xcframework`** and depends on `udentify_core_flutter` for `UdentifyCommons.xcframework`. CocoaPods pulls both in automatically — there is **no** manual framework drag-and-drop or Swift Package Manager step for the plugin. Just run `pod install` (via `flutter run`) and configure the following.

### 1. Deployment target

Set the iOS deployment target to **13.0 or higher** (required for CoreNFC ISO 7816 tag reading). In `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

### 2. Capability

In Xcode → your app target → **Signing & Capabilities** → **+ Capability** → add **Near Field Communication Tag Reading**.

### 3. Info.plist

```xml
<key>NFCReaderUsageDescription</key>
<string>This app uses NFC to read information from NFC-enabled identity documents.</string>

<key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
<array>
    <string>A0000002471001</string>
</array>
```

`A0000002471001` is the ICAO ePassport application identifier (AID). It must be present or the read session cannot select the passport applet.

---

## Usage

```dart
import 'package:nfc_flutter/nfc_flutter.dart';

final nfc = NfcFlutter();

Future<void> readDocument() async {
  // 1) Ensure permissions (Android: READ_PHONE_STATE + NFC enabled).
  final permissions = await nfc.checkPermissions();
  if (!permissions.hasPhoneStatePermission) {
    await nfc.requestPermissions();
  }

  // 2) MRZ key fields — obtain these from mrz_flutter or your OCR result.
  final params = NfcPassportParams(
    documentNumber: 'A12345678',
    dateOfBirth: '900101',   // YYMMDD
    expiryDate: '300101',    // YYMMDD
    transactionID: 'TX_123',
    serverURL: 'https://your-udentify-server.com',
    requestTimeout: 20,                      // seconds (iOS only)
    isActiveAuthenticationEnabled: true,
    isPassiveAuthenticationEnabled: true,
  );

  try {
    // 3) Read. onProgress reports 0..100 (a percentage), NOT 0..1.
    final passport = await nfc.readPassport(
      params,
      onProgress: (progress) {
        debugPrint('NFC reading: ${progress.toStringAsFixed(0)}%');
      },
    );

    if (passport != null) {
      debugPrint('Name: ${passport.firstName} ${passport.lastName}');
      debugPrint('Passive Authentication: ${passport.passedPA}');   // e.g. AuthenticationResult.success
      debugPrint('Active Authentication:  ${passport.passedAA}');
      // passport.image is a base64-encoded photo (DG2), or null.
    }
  } catch (e) {
    debugPrint('NFC read failed: $e');
  }
}
```

> **Progress is a percentage (0–100).** Bind it to a progress bar with `value: progress / 100`. Do **not** multiply by 100.

### Detecting the NFC antenna position (Android)

Some Android phones place the NFC antenna in an unhelpful spot. `getNfcLocation()` asks the server where this device's antenna is so you can guide the user:

```dart
final NfcLocation location = await nfc.getNfcLocation('https://your-udentify-server.com');
// e.g. NfcLocation.rearCenter -> "hold the document to the back-centre of your phone"
```

On Android only `unknown`, `rearTop`, `rearCenter`, and `rearBottom` are returned. On iOS the antenna is always at the top, so this call is generally unnecessary.

### Cancelling

```dart
await nfc.cancelReading();
```

---

## API reference

All methods are **instance** methods on `NfcFlutter` (`final nfc = NfcFlutter();`).

| Method | Returns | Description |
|---|---|---|
| `readPassport(NfcPassportParams params, {Function(double progress)? onProgress})` | `Future<NfcPassport?>` | Reads the chip. `onProgress` reports **0–100**. Throws a `PlatformException` on failure. |
| `cancelReading()` | `Future<void>` | Cancels an in-flight read. |
| `getNfcLocation(String serverURL)` | `Future<NfcLocation>` | Antenna position as an enum. Falls back to `NfcLocation.unknown` on error. |
| `getNfcLocationRaw(String serverURL)` | `Future<String>` | The raw JSON antenna-location response, if you need the full payload. |
| `checkPermissions()` | `Future<PermissionStatus>` | Current permission state. |
| `requestPermissions()` | `Future<String>` | Requests `READ_PHONE_STATE` (Android). Returns `"granted"`, `"requested"`, or `"error"`. |

### `NfcPassportParams`

| Field | Type | Required | Notes |
|---|---|---|---|
| `documentNumber` | `String` | ✅ | MRZ document number. |
| `dateOfBirth` | `String` | ✅ | **`YYMMDD`** format. |
| `expiryDate` | `String` | ✅ | **`YYMMDD`** format. |
| `transactionID` | `String` | ✅ | Transaction id from your Udentify server. |
| `serverURL` | `String` | ✅ | Udentify server base URL. |
| `requestTimeout` | `int?` | — | Server timeout in seconds. Default 10. **iOS only** — Android ignores this. |
| `isActiveAuthenticationEnabled` | `bool?` | — | Default `true`. |
| `isPassiveAuthenticationEnabled` | `bool?` | — | Default `true`. |

### `NfcPassport`

Returned by `readPassport()`. The Dart model surfaces these fields:

| Field | Type | Notes |
|---|---|---|
| `image` | `String?` | Base64-encoded document photo (DG2). iOS encodes JPEG; Android encodes PNG. |
| `firstName` | `String?` | |
| `lastName` | `String?` | |
| `passedPA` | `AuthenticationResult?` | Passive Authentication result. |
| `passedAA` | `AuthenticationResult?` | Active Authentication result. |

### `PermissionStatus`

| Field | Type |
|---|---|
| `hasPhoneStatePermission` | `bool` |
| `hasNfcPermission` | `bool` |

### Enums

**`AuthenticationResult`** — `disabled`, `success`, `failed`, `notSupported`. `success` means the check passed; `notSupported` means the chip does not support it (common for AA); `disabled` means you turned the check off in the params.

**`NfcLocation`** — `unknown`, `frontTop`, `frontCenter`, `frontBottom`, `rearTop`, `rearCenter`, `rearBottom`. Android emits only `unknown` / `rearTop` / `rearCenter` / `rearBottom`.

---

## Parameter formats

- **`dateOfBirth` / `expiryDate` → `YYMMDD`.** Six digits, zero-padded. `1 January 1990` → `900101`; `1 January 2030` → `300101`. These come straight from the MRZ; do not reformat them.
- **`documentNumber`** — exactly as printed in the MRZ (letters uppercase, no spaces). If any of the three MRZ fields is wrong, BAC/PACE key derivation fails and the chip refuses the connection (see [`NFC_READ_ERROR`](#troubleshooting)).
- **`image` (returned)** — base64 string with **no** `data:` URI prefix. Decode with `base64Decode(passport.image!)` and render via `Image.memory(...)`.

---

## Troubleshooting

### Errors thrown by `readPassport()` (via `PlatformException`)

| `code` | Cause / fix |
|---|---|
| `MISSING_PARAMETERS` / `INVALID_ARGUMENTS` (iOS) | A required field (`documentNumber`, `dateOfBirth`, `expiryDate`, `transactionID`, `serverURL`) is missing or malformed. |
| `NFC_READ_ERROR` (Android) / `NFC_ERROR` (iOS) | The read failed — most often **wrong MRZ key** (check the three fields are `YYMMDD` / exact document number), the document was moved away too early, or a weak antenna contact. |
| `NFC_DISABLED` (Android) | NFC is turned off in system settings. Ask the user to enable it. |
| `CANCELLED` (Android) | `cancelReading()` was called (or the user cancelled). |
| `FRAMEWORK_NOT_AVAILABLE` (iOS) | `UdentifyNFC` / `UdentifyCommons` not linked — ensure `udentify_core_flutter` is added and run `pod install`. |
| `NO_ACTIVITY` (Android) | The plugin had no foreground Activity — call `readPassport()` from a resumed screen. |

### Errors from `getNfcLocation()`

`NETWORK_ERROR`, `TIMEOUT_ERROR` (30 s), `SDK_ERROR`, `NFC_LOCATION_ERROR` — all indicate the antenna-location lookup could not reach the server. `getNfcLocation()` itself returns `NfcLocation.unknown` rather than throwing.

### Common integration issues

| Symptom | Fix |
|---|---|
| Build fails: `UdentifyCommons` not found (iOS) | Add `udentify_core_flutter` to `pubspec.yaml`; the NFC plugin does not vendor Commons itself. |
| Runtime `ClassNotFoundException: io.udentify…` (Android) | The native SDK AAR is not on the app classpath — add the Maven dependency **or** copy the AARs into `android/app/libs/`. The plugin ships the AAR as `compileOnly`. |
| `NoClassDefFoundError: org.jmrtd…` / `net.sf.scuba…` / `jj2000` (Android) | You are missing the third-party dependencies — add them all (see above). `jj2000` is required to decode the DG2 photo. |
| NFC session never starts (iOS) | Deployment target below 13.0, missing **Near Field Communication Tag Reading** capability, or missing `NFCReaderUsageDescription` / the `A0000002471001` AID in Info.plist. |
| Reading a device with a rear antenna is unreliable | Use `getNfcLocation()` to guide the user, and tell them to hold the document still for several seconds. |
| The progress bar jumps to thousands of percent | `onProgress` reports 0–100. Use `value: progress / 100` and do not multiply by 100. |

---

## Notes

- The Android SDK reads additional MRZ/personal fields internally, but the current Dart `NfcPassport` model surfaces only `image`, `firstName`, `lastName`, `passedPA` and `passedAA`. If you need more fields exposed, open an issue.
- `requestTimeout` is honoured on iOS only; the Android SDK manages its own timeout.

## Related plugins

- [`udentify-core-flutter`](../udentify-core-flutter) — shared core (SSL pinning, remote localization). **Required.**
- [`mrz-flutter`](../mrz-flutter) — scans the MRZ to obtain the key fields for `readPassport()`.
- [`ocr-flutter`](../ocr-flutter) — document OCR / liveness.
