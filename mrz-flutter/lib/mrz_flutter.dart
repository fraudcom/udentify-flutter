library mrz_flutter;

import 'mrz_flutter_platform_interface.dart';
import 'src/models/mrz_models.dart';
export 'src/models/mrz_models.dart'
    show MrzData, BACCredentials, MrzError, MrzErrorType;

class MrzFlutter {
  static MrzFlutterPlatform get _platform => MrzFlutterPlatform.instance;

  /// Check if camera permissions are granted
  static Future<bool> checkPermissions() {
    return _platform.checkPermissions();
  }

  /// Request camera permissions
  static Future<String> requestPermissions() {
    return _platform.requestPermissions();
  }

  /// Start MRZ camera scanning
  /// Returns MRZ data on success
  static Future<MrzResult> startMrzCamera({
    MrzReaderMode mode = MrzReaderMode.accurate,
    Function(double progress)? onProgress,
  }) {
    return _platform.startMrzCamera(mode: mode, onProgress: onProgress);
  }

  /// Process MRZ from a provided image (Base64 encoded)
  static Future<MrzResult> processMrzImage({
    required String imageBase64,
    MrzReaderMode mode = MrzReaderMode.accurate,
  }) {
    return _platform.processMrzImage(imageBase64: imageBase64, mode: mode);
  }

  /// Cancel ongoing MRZ scanning
  static Future<void> cancelMrzScanning() {
    return _platform.cancelMrzScanning();
  }
}

/// MRZ Reader modes
enum MrzReaderMode {
  fast, // Fast but less accurate
  accurate // Slower but more accurate
}

/// MRZ scanning result
class MrzResult {
  final bool success;
  final MrzData? mrzData;
  final String? errorMessage;

  // Legacy getters for backward compatibility
  String? get documentNumber => mrzData?.documentNumber;
  String? get dateOfBirth => mrzData?.dateOfBirth;
  String? get dateOfExpiration => mrzData?.dateOfExpiration;

  MrzResult({
    required this.success,
    this.mrzData,
    this.errorMessage,
  });

  /// Create success result with MRZ data
  factory MrzResult.success(MrzData mrzData) {
    return MrzResult(
      success: true,
      mrzData: mrzData,
    );
  }

  /// Create failure result with error message
  factory MrzResult.failure(String errorMessage) {
    return MrzResult(
      success: false,
      errorMessage: errorMessage,
    );
  }

  /// Legacy constructor for backward compatibility
  factory MrzResult.legacy({
    required bool success,
    String? documentNumber,
    String? dateOfBirth,
    String? dateOfExpiration,
    String? errorMessage,
  }) {
    if (success &&
        documentNumber != null &&
        dateOfBirth != null &&
        dateOfExpiration != null) {
      final mrzData = MrzData(
        documentType: '',
        issuingCountry: '',
        documentNumber: documentNumber,
        dateOfBirth: dateOfBirth,
        gender: '',
        dateOfExpiration: dateOfExpiration,
        nationality: '',
        surname: '',
        givenNames: '',
      );
      return MrzResult.success(mrzData);
    }
    return MrzResult.failure(errorMessage ?? 'Unknown error');
  }

  factory MrzResult.fromMap(Map<String, dynamic> map) {
    final success = map['success'] ?? false;

    if (success) {
      // Try to parse full MRZ data first
      if (map.containsKey('mrzData')) {
        final mrzData =
            MrzData.fromMap(Map<String, dynamic>.from(map['mrzData']));
        return MrzResult.success(mrzData);
      }

      // Fallback to legacy format
      if (map.containsKey('documentNumber')) {
        return MrzResult.legacy(
          success: success,
          documentNumber: map['documentNumber'],
          dateOfBirth: map['dateOfBirth'],
          dateOfExpiration: map['dateOfExpiration'],
          errorMessage: map['errorMessage'],
        );
      }
    }

    return MrzResult.failure(map['errorMessage'] ?? 'Unknown error');
  }

  Map<String, dynamic> toMap() {
    if (success && mrzData != null) {
      return {
        'success': success,
        'mrzData': mrzData!.toMap(),
        // Include legacy fields for backward compatibility
        'documentNumber': mrzData!.documentNumber,
        'dateOfBirth': mrzData!.dateOfBirth,
        'dateOfExpiration': mrzData!.dateOfExpiration,
      };
    }
    return {
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  /// Get BAC credentials for NFC reading
  BACCredentials? get bacCredentials {
    return mrzData != null ? BACCredentials.fromMrzData(mrzData!) : null;
  }
}
