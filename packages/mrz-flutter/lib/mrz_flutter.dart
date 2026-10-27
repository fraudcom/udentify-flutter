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

  /// Start MRZ camera scanning. [uiCustomization] applies on iOS only.
  /// Returns MRZ data on success
  static Future<MrzResult> startMrzCamera({
    MrzReaderMode mode = MrzReaderMode.accurate,
    Function(double progress)? onProgress,
    MrzUICustomization? uiCustomization,
  }) {
    return _platform.startMrzCamera(
      mode: mode,
      onProgress: onProgress,
      uiCustomization: uiCustomization,
    );
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

/// Appearance of the MRZ scan screen. **iOS only**: the Android scanner has its own fixed screen.
/// Every field is optional; an omitted one keeps the plugin's existing look.
class MrzUICustomization {
  /// Focus view border color as a hex code, e.g. `#007AFF`.
  final String? focusViewBorderColor;

  /// Focus view stroke width, `1`-`10`.
  final double? focusViewStrokeWidth;

  /// Instruction text shown above the frame.
  final String? instructionText;

  /// Instruction text color as a hex code.
  final String? instructionTextColor;

  /// Show or hide the cancel button.
  final bool? showCancelButton;

  /// Cancel button text.
  final String? cancelButtonText;

  /// Cancel button color as a hex code.
  final String? cancelButtonColor;

  const MrzUICustomization({
    this.focusViewBorderColor,
    this.focusViewStrokeWidth,
    this.instructionText,
    this.instructionTextColor,
    this.showCancelButton,
    this.cancelButtonText,
    this.cancelButtonColor,
  });

  Map<String, dynamic> toMap() => {
        if (focusViewBorderColor != null)
          'focusViewBorderColor': focusViewBorderColor,
        if (focusViewStrokeWidth != null)
          'focusViewStrokeWidth': focusViewStrokeWidth,
        if (instructionText != null) 'instructionText': instructionText,
        if (instructionTextColor != null)
          'instructionTextColor': instructionTextColor,
        if (showCancelButton != null) 'showCancelButton': showCancelButton,
        if (cancelButtonText != null) 'cancelButtonText': cancelButtonText,
        if (cancelButtonColor != null) 'cancelButtonColor': cancelButtonColor,
      };
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

  /// The code of a failure: the SDK's own `ERR_*` name (`ERR_MRZ_NOT_FOUND`, `ERR_INVALID_DOC_NO`, ...) when
  /// it reported one, otherwise a plugin code (`USER_CANCELLED`, ...). `null` on success.
  final String? errorCode;

  /// [errorCode] as a typed value. `null` on success.
  MrzErrorType? get errorType => errorCode == null ? null : MrzError.typeFromCode(errorCode!);

  // Legacy getters for backward compatibility
  String? get documentNumber => mrzData?.documentNumber;
  String? get dateOfBirth => mrzData?.dateOfBirth;
  String? get dateOfExpiration => mrzData?.dateOfExpiration;

  MrzResult({
    required this.success,
    this.mrzData,
    this.errorMessage,
    this.errorCode,
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
