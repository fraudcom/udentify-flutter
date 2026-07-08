# Udentify Flutter SDK

Official Flutter SDK wrappers for Udentify’s native identity verification solutions.  
This repository contains multiple Flutter plugins and an example application that demonstrate integration with Udentify’s native iOS and Android SDKs.

## 🚀 Overview

The repository provides Flutter plugins covering essential identity verification workflows, including face liveness, document scanning, MRZ extraction, NFC passport reading, and video calling.  
These plugins act as bridges to Udentify’s native SDKs and require valid Udentify SDK binaries and licenses.

## 📦 Included Plugins

| Plugin | Description |
|--------|-------------|
| **[liveness-flutter](./packages/liveness-flutter/)** | Face recognition & liveness detection |
| **[mrz-flutter](./packages/mrz-flutter/)** | Machine Readable Zone (MRZ) scanning |
| **[nfc-flutter](./packages/nfc-flutter/)** | NFC passport & document reading |
| **[ocr-flutter](./packages/ocr-flutter/)** | OCR document scanning & verification |
| **[video-call-flutter](./packages/video-call-flutter/)** | Video calling with identity verification |

> **Note:** Version numbers and stability status depend on the underlying native SDK release.  
> Please refer to official Udentify documentation or contact support for production readiness details.

## 📦 Distribution

Plugins are distributed as `.tar.gz` package archives (similar to `.tgz` in npm). The `udentify-core-flutter` package provides shared components required by feature plugins.

### Available Package Archives

```bash
# Core (required)
packages/udentify-core-flutter-26.1.3.tar.gz

# Feature plugins
packages/ocr-flutter-26.1.3.tar.gz
packages/liveness-flutter-26.1.3.tar.gz
packages/mrz-flutter-26.1.3.tar.gz
packages/nfc-flutter-26.1.3.tar.gz
packages/video-call-flutter-26.1.3.tar.gz
```

### Building Package Archives

```bash
./scripts/pack-flutter.sh
```

Outputs `.tar.gz` files to `packages/`.

### Installing from Package Archives

Flutter uses `path:` dependencies. Extract archives to `packages/` before use:

```bash
# Extract all archives (run from repo root)
for f in packages/*.tar.gz; do
  tar -xzf "$f" -C packages/
done

# Then in your app pubspec.yaml
cd your_app
flutter pub get
```

Or extract individually:

```bash
tar -xzf packages/udentify-core-flutter-26.1.3.tar.gz -C packages/
tar -xzf packages/liveness-flutter-26.1.3.tar.gz -C packages/
# ... etc
```

### Peer Dependency Architecture

- **udentify-core-flutter** provides shared components (SSL pinning, remote language pack) used by feature plugins
- Feature plugins can depend on udentify-core-flutter
- Install only the plugins you need

## 🏗️ Repository Structure

```
udentify-flutter/
├── packages/
│   ├── liveness-flutter/        # Liveness detection plugin
│   ├── mrz-flutter/             # MRZ scanning plugin
│   ├── nfc-flutter/             # NFC passport reading plugin
│   ├── ocr-flutter/             # OCR document verification plugin
│   ├── video-call-flutter/      # Video calling plugin
│   └── udentify-core-flutter/   # Core shared components (SSL pinning)
└── testApplicationFlutter/     # Test & demo application
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
    path: ../packages/liveness-flutter
  mrz_flutter:
    path: ../packages/mrz-flutter
  nfc_flutter:
    path: ../packages/nfc-flutter
  ocr_flutter:
    path: ../packages/ocr-flutter
  video_call_flutter:
    path: ../packages/video-call-flutter
  udentify_core_flutter:
    path: ../packages/udentify-core-flutter
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
cd packages/liveness-flutter && flutter test
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
