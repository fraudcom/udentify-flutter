import 'iqa_types.dart';

/// OCR Orientation Types
enum OCROrientation {
  horizontal('horizontal'),
  vertical('vertical');

  const OCROrientation(this.value);
  final String value;
}

/// Placeholder Template Types
enum OCRPlaceholderTemplate {
  defaultStyle('defaultStyle'),
  hidden('hidden'),
  countrySpecificStyle('countrySpecificStyle');

  const OCRPlaceholderTemplate(this.value);
  final String value;
}

/// UI Button Style Configuration
class OCRButtonStyle {
  final String? backgroundColor;
  final String? borderColor;
  final double? cornerRadius;
  final double? borderWidth;
  final double? height;
  final double? leading;
  final double? trailing;
  final String? fontFamily;
  final double? fontSize;
  final bool? fontBold;
  final String? textColor;
  final String? textAlignment;
  final int? numberOfLines;

  OCRButtonStyle({
    this.backgroundColor,
    this.borderColor,
    this.cornerRadius,
    this.borderWidth,
    this.height,
    this.leading,
    this.trailing,
    this.fontFamily,
    this.fontSize,
    this.fontBold,
    this.textColor,
    this.textAlignment,
    this.numberOfLines,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'borderColor': borderColor,
      'cornerRadius': cornerRadius,
      'borderWidth': borderWidth,
      'height': height,
      'leading': leading,
      'trailing': trailing,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontBold': fontBold,
      'textColor': textColor,
      'textAlignment': textAlignment,
      'numberOfLines': numberOfLines,
    };
  }
}

/// UI Text Style Configuration
class OCRTextStyle {
  final String? fontFamily;
  final double? fontSize;
  final bool? fontBold;
  final String? textColor;
  final String? textAlignment;
  final int? numberOfLines;
  final double? leading;
  final double? trailing;

  OCRTextStyle({
    this.fontFamily,
    this.fontSize,
    this.fontBold,
    this.textColor,
    this.textAlignment,
    this.numberOfLines,
    this.leading,
    this.trailing,
  });

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontBold': fontBold,
      'textColor': textColor,
      'textAlignment': textAlignment,
      'numberOfLines': numberOfLines,
      'leading': leading,
      'trailing': trailing,
    };
  }
}

/// UI View Style Configuration
class OCRViewStyle {
  final String? backgroundColor;
  final String? borderColor;
  final double? cornerRadius;
  final double? borderWidth;

  /// Opacity applied to [backgroundColor], from 0.0 (fully transparent) to
  /// 1.0 (fully opaque). It is encoded into the alpha channel of an 8-digit
  /// `#AARRGGBB` hex string sent to the native side, which already parses
  /// that format with correct alpha on both iOS and Android. Works with
  /// hex colors directly, and with the small set of named colors also
  /// recognized natively (`purple`, `blue`, `green`, `red`, `black`,
  /// `white`, `gray`/`grey`) by resolving them to their RGB hex first. Any
  /// other named color (e.g. `"clear"`, `"label"`) cannot carry opacity and
  /// is passed through unchanged.
  final double? opacity;

  OCRViewStyle({
    this.backgroundColor,
    this.borderColor,
    this.cornerRadius,
    this.borderWidth,
    this.opacity,
  });

  /// RGB hex for the named colors natively recognized on iOS
  /// (`CustomOCRSettings.parseColor`), used to resolve opacity onto them.
  static const Map<String, String> _namedColorHex = {
    'purple': '800080',
    'blue': '0000ff',
    'green': '00ff00',
    'red': 'ff0000',
    'black': '000000',
    'white': 'ffffff',
    'gray': '808080',
    'grey': '808080',
  };

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': _resolvedBackgroundColor,
      'borderColor': borderColor,
      'cornerRadius': cornerRadius,
      'borderWidth': borderWidth,
    };
  }

  String? get _resolvedBackgroundColor {
    final color = backgroundColor;
    final alpha = opacity;
    if (color == null || alpha == null) return color;

    String? rgb;
    if (color.startsWith('#')) {
      final hex = color.substring(1);
      rgb = hex.length == 8 ? hex.substring(2) : (hex.length == 6 ? hex : null);
    } else {
      rgb = _namedColorHex[color.toLowerCase()];
    }
    if (rgb == null) return color;

    final alphaHex =
        (alpha.clamp(0.0, 1.0) * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$alphaHex$rgb';
  }
}

/// Progress Bar Style Configuration
class OCRProgressBarStyle {
  final String? backgroundColor;
  final String? progressColor;
  final String? completionColor;
  final OCRTextStyle? textStyle;
  final double? cornerRadius;

  OCRProgressBarStyle({
    this.backgroundColor,
    this.progressColor,
    this.completionColor,
    this.textStyle,
    this.cornerRadius,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'progressColor': progressColor,
      'completionColor': completionColor,
      'textStyle': textStyle?.toMap(),
      'cornerRadius': cornerRadius,
    };
  }
}

/// Document Detection Visual Feedback Configuration.
///
/// iOS only — feeds `OCRConfigs.documentDetectionConfig`
/// (`UdentifyOCR.OCRDocumentDetectionConfig`), which colors the document's
/// detection border while scanning. No Android counterpart exists in the
/// vendored SDK (`CardRecognizerCredentials.Builder` has no matching
/// method).
class OCRDocumentDetectionConfig {
  final String? borderColorOnSuccess;
  final String? borderColorOnFailure;

  OCRDocumentDetectionConfig({
    this.borderColorOnSuccess,
    this.borderColorOnFailure,
  });

  Map<String, dynamic> toMap() {
    return {
      'borderColorOnSuccess': borderColorOnSuccess,
      'borderColorOnFailure': borderColorOnFailure,
    };
  }
}

/// UI Customization Types - Comprehensive Configuration
class OCRUIConfig {
  final double? blurCoefficient;
  final int? requestTimeout;
  final int? detectionAccuracy;
  final bool? backButtonEnabled;
  final bool? reviewScreenEnabled;
  final bool? footerViewHidden;
  final bool? manualCapture;
  final OCRViewStyle? placeholderContainerStyle;
  final OCRPlaceholderTemplate? placeholderTemplate;
  final String? buttonBackColor;
  final String? maskLayerColor;
  final OCRButtonStyle? footerViewStyle;
  final OCRButtonStyle? buttonUseStyle;
  final OCRButtonStyle? buttonRetakeStyle;
  final OCROrientation? orientation;
  final String? localizationTableName;
  final OCRTextStyle? titleLabelStyle;
  final OCRTextStyle? instructionLabelStyle;
  final OCRTextStyle? reviewTitleLabelStyle;
  final OCRTextStyle? reviewInstructionLabelStyle;
  final OCRProgressBarStyle? progressBarStyle;
  final bool? faceDetection;
  final bool? documentLivenessEnabled;
  final double? successDelay;
  final int? hardwareSupport;
  final String? reviewBackgroundColor;
  final Map<String, dynamic>? reviewBackgroundStyle;
  final bool? iqaEnabled;
  final int? iqaSuccessAutoDismissDelay;
  final IQAScreenStyle? iqaScreenStyle;
  final double? rawPhotoCropRatio;
  final OCRDocumentDetectionConfig? documentDetectionConfig;

  OCRUIConfig({
    this.blurCoefficient,
    this.requestTimeout,
    this.detectionAccuracy,
    this.backButtonEnabled,
    this.reviewScreenEnabled,
    this.footerViewHidden,
    this.manualCapture,
    this.placeholderContainerStyle,
    this.placeholderTemplate,
    this.buttonBackColor,
    this.maskLayerColor,
    this.footerViewStyle,
    this.buttonUseStyle,
    this.buttonRetakeStyle,
    this.orientation,
    this.localizationTableName,
    this.titleLabelStyle,
    this.instructionLabelStyle,
    this.reviewTitleLabelStyle,
    this.reviewInstructionLabelStyle,
    this.progressBarStyle,
    this.faceDetection,
    this.documentLivenessEnabled,
    this.successDelay,
    this.hardwareSupport,
    this.reviewBackgroundColor,
    this.reviewBackgroundStyle,
    this.iqaEnabled,
    this.iqaSuccessAutoDismissDelay,
    this.iqaScreenStyle,
    this.rawPhotoCropRatio,
    this.documentDetectionConfig,
  });

  Map<String, dynamic> toMap() {
    return {
      'blurCoefficient': blurCoefficient,
      'requestTimeout': requestTimeout,
      'detectionAccuracy': detectionAccuracy,
      'backButtonEnabled': backButtonEnabled,
      'reviewScreenEnabled': reviewScreenEnabled,
      'footerViewHidden': footerViewHidden,
      'manualCapture': manualCapture,
      'placeholderContainerStyle': placeholderContainerStyle?.toMap(),
      'placeholderTemplate': placeholderTemplate?.value,
      'buttonBackColor': buttonBackColor,
      'maskLayerColor': maskLayerColor,
      'footerViewStyle': footerViewStyle?.toMap(),
      'buttonUseStyle': buttonUseStyle?.toMap(),
      'buttonRetakeStyle': buttonRetakeStyle?.toMap(),
      'orientation': orientation?.value,
      'localizationTableName': localizationTableName,
      // iOS native side reads the localization table under the key 'tableName'
      'tableName': localizationTableName,
      'titleLabelStyle': titleLabelStyle?.toMap(),
      'instructionLabelStyle': instructionLabelStyle?.toMap(),
      'reviewTitleLabelStyle': reviewTitleLabelStyle?.toMap(),
      'reviewInstructionLabelStyle': reviewInstructionLabelStyle?.toMap(),
      'progressBarStyle': progressBarStyle?.toMap(),
      'faceDetection': faceDetection,
      'documentLivenessEnabled': documentLivenessEnabled,
      'successDelay': successDelay,
      'hardwareSupport': hardwareSupport,
      'reviewBackgroundColor': reviewBackgroundColor,
      'reviewBackgroundStyle': reviewBackgroundStyle,
      'iqaEnabled': iqaEnabled,
      'iqaSuccessAutoDismissDelay': iqaSuccessAutoDismissDelay,
      'iqaScreenStyle': iqaScreenStyle?.toMap(),
      'rawPhotoCropRatio': rawPhotoCropRatio,
      'documentDetectionConfig': documentDetectionConfig?.toMap(),
    };
  }
}

/// OCR Error Types
enum OCRErrorType {
  cameraPermissionRequired('ERR_CAMERA_PERMISSION_REQUIRED'),
  readExternalStoragePermissionRequired(
      'ERR_READ_EXTERNAL_STORAGE_PERMISSION_REQUIRED'),
  writeExternalStoragePermissionRequired(
      'ERR_WRITE_EXTERNAL_STORAGE_PERMISSION_REQUIRED'),
  unknown('ERR_UNKNOWN'),
  faceCredentialsMissing('ERR_FACE_CREDENTIALS_MISSING'),
  serverTimeoutException('ERR_SERVER_TIMEOUT_EXCEPTION'),
  invalidServerResponse('ERR_INVALID_SERVER_RESPONSE'),
  serverResponseEmpty('ERR_SERVER_RESPONSE_EMPTY'),
  serverResponseParamsEmpty('ERR_SERVER_RESPONSE_PARAMS_EMPTY'),
  transactionNotFound('ERR_TRANSACTION_NOT_FOUND'),
  transactionFailed('ERR_TRANSACTION_FAILED'),
  transactionExpired('ERR_TRANSACTION_EXPIRED'),
  transactionAlreadyCompleted('ERR_TRANSACTION_ALREADY_COMPLETED'),
  cameraReasonUnknown('ERR_CAMERA_REASON_UNKNOWN'),
  cameraReasonFailedToConnect('ERR_CAMERA_REASON_FAILED_TO_CONNECT'),
  cameraReasonFailedToStartPreview('ERR_CAMERA_REASON_FAILED_TO_START_PREVIEW'),
  cameraReasonDisconnected('ERR_CAMERA_REASON_DISCONNECTED'),
  cameraReasonPictureFailed('ERR_CAMERA_REASON_PICTURE_FAILED'),
  cameraReasonVideoFailed('ERR_CAMERA_REASON_VIDEO_FAILED'),
  cameraReasonNoCamera('ERR_CAMERA_REASON_NO_CAMERA'),
  faceUserIdMissing('ERR_FACE_USER_ID_MISSING'),
  faceUserIdNotRegistered('ERR_FACE_USER_ID_NOT_REGISTERED'),
  faceImageNotFound('ERR_FACE_IMAGE_NOT_FOUND'),
  faceFailedToUploadImage('ERR_FACE_FAILED_TO_UPLOAD_IMAGE'),
  faceIncorrectImageSize('ERR_FACE_INCORRECT_IMAGE_SIZE'),
  faceErrorImageDecode('ERR_FACE_ERROR_IMAGE_DECODE'),
  internalServer('ERR_INTERNAL_SERVER'),
  documentLivenessDocumentPhotoNotFound(
      'ERR_DOCUMENT_LIVENESS_DOCUMENT_PHOTO_NOT_FOUND'),
  documentLivenessThresholdError('ERR_DOCUMENT_LIVENESS_THRESHOLD_ERROR'),
  noLivenessProvided('ERR_NO_LIVENESS_PROVIDED');

  const OCRErrorType(this.value);
  final String value;

  static OCRErrorType? fromString(String? errorString) {
    if (errorString == null) return null;

    for (OCRErrorType type in OCRErrorType.values) {
      if (type.value == errorString) {
        return type;
      }
    }
    return null;
  }
}

/// OCR Exception Class
class OCRException implements Exception {
  final OCRErrorType type;
  final String message;
  final String? details;
  final dynamic originalError;

  const OCRException({
    required this.type,
    required this.message,
    this.details,
    this.originalError,
  });

  @override
  String toString() {
    var result = 'OCRException: ${type.value} - $message';
    if (details != null) {
      result += '\nDetails: $details';
    }
    return result;
  }

  factory OCRException.fromError(String? errorCode, String message,
      {String? details, dynamic originalError}) {
    final type = OCRErrorType.fromString(errorCode) ?? OCRErrorType.unknown;
    return OCRException(
      type: type,
      message: message,
      details: details,
      originalError: originalError,
    );
  }
}

/// Camera Error Types (iOS specific)
enum CameraErrorType {
  cameraNotFound('CameraNotFound'),
  minIOSRequirementNotSatisfied('MinIOSRequirementNotSatisfied'),
  cameraPermissionRequired('CameraPermissionRequired'),
  focusViewInvalidSize('FocusViewInvalidSize'),
  sessionPresetNotAvailable('SessionPresetNotAvailable'),
  sessionNotRunning('SessionNotRunning'),
  videoPathMissing('VideoPathMissing'),
  unableToGenerateVideoData('UnableToGenerateVideoData'),
  videoExportingFailed('VideoExportingFailed'),
  videoExportingCancelled('VideoExportingCancelled'),
  unknownCamera('Unknown');

  const CameraErrorType(this.value);
  final String value;
}

/// Server Error Types (iOS specific)
enum ServerErrorType {
  invalidResponse('InvalidResponse'),
  unexpectedError('UnexpectedError');

  const ServerErrorType(this.value);
  final String value;
}
