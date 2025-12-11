# Udentify Flutter SDK

Official Flutter SDK wrappers for Udentify’s native identity verification solutions.  
This repository contains multiple Flutter plugins and an example application that demonstrate integration with Udentify’s native iOS and Android SDKs.

## 🚀 Overview

The repository provides Flutter plugins covering essential identity verification workflows, including face liveness, document scanning, MRZ extraction, NFC passport reading, and video calling.  
These plugins act as bridges to Udentify’s native SDKs and require valid Udentify SDK binaries and licenses.

## 📦 Included Plugins

| Plugin | Description |
|--------|-------------|
| **[liveness-flutter](./liveness-flutter/)** | Face recognition & liveness detection |
| **[mrz-flutter](./mrz-flutter/)** | Machine Readable Zone (MRZ) scanning |
| **[nfc-flutter](./nfc-flutter/)** | NFC passport & document reading |
| **[ocr-flutter](./ocr-flutter/)** | OCR document scanning & verification |
| **[video-call-flutter](./video-call-flutter/)** | Video calling with identity verification |

> **Note:** Version numbers and stability status depend on the underlying native SDK release.  
> Please refer to official Udentify documentation or contact support for production readiness details.

## 🏗️ Repository Structure

```
udentify-flutter/
├── liveness-flutter/        # Liveness detection plugin
├── mrz-flutter/             # MRZ scanning plugin
├── nfc-flutter/             # NFC passport reading plugin
├── ocr-flutter/             # OCR document verification plugin
├── video-call-flutter/      # Video calling plugin
└── testApplicationFlutter/  # Test & demo application
```

## 🎯 Key Features

- **Face Recognition & Liveness**  
- **Document OCR Scanning**  
- **MRZ Reading**  
- **NFC Passport Reading**  
- **Video Calling (with identity workflows)**  
  
> Availability in Flutter depends on plugin coverage and native SDK licensing.

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK**: 3.3.0+  
- **Dart SDK**: 3.0.0+  
- **iOS**: 11.0+ (12.0+ for some features)  
- **Android**: API level 21+  
- **Native SDK Binaries & License**: Required for each plugin  

### Test Application

The included test app demonstrates all plugins:

```bash
cd testApplicationFlutter
flutter pub get
flutter run
```

### Individual Plugin Integration

Plugins can be integrated via local paths:

```yaml
dependencies:
  liveness_flutter:
    path: ../liveness-flutter
  mrz_flutter:
    path: ../mrz-flutter
  nfc_flutter:
    path: ../nfc-flutter
  ocr_flutter:
    path: ../ocr-flutter
  video_call_flutter:
    path: ../video-call-flutter
```

## 🔧 Platform Setup

### iOS
- Add required Udentify frameworks  
- Configure **Info.plist** for camera/microphone/NFC permissions  
- Enable **NFC capability** if using NFC plugin  
- Minimum iOS: 11.0+  

### Android
- Include Udentify SDK AAR dependencies  
- Configure **AndroidManifest.xml** with required permissions  
- Apply ProGuard rules if minifying  
- Minimum API level: 21+  

## 🧪 Development & Testing

```bash
# Install dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run tests
cd liveness-flutter && flutter test
# repeat for other plugins
```

> **Physical devices required** for NFC and camera-based features.  

## 📚 Documentation

Each plugin contains:
- **README.md** – Setup & usage instructions  
- **Example Code** – Integration samples  
- **CHANGELOG.md** – Updates (if available)  

## 🛠️ Troubleshooting

- **Plugin Not Found** → Run `flutter clean && flutter pub get`  
- **Native SDK Errors** → Verify Udentify SDK frameworks/AARs are installed correctly  
- **Permissions Denied** → Check iOS `Info.plist` / Android `AndroidManifest.xml`  

## 🏢 Organization

**Developed by**: Fraud.com International LTD  
**SDK Provider**: Udentify  
**Support**: Contact Udentify support team  

## 📄 Licensing

- Requires a valid Udentify SDK license  
- Plugin wrappers: see individual plugin LICENSE files (if provided)  
- Third-party dependencies: subject to their own licenses  

---

**Note:** This repository does not bundle Udentify’s proprietary native SDKs.  
To obtain access, licensing, and production readiness details, please contact Udentify support.
