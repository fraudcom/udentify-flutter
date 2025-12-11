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
  final String? contentAlignment;
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
    this.contentAlignment,
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
      'contentAlignment': contentAlignment,
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

  OCRViewStyle({
    this.backgroundColor,
    this.borderColor,
    this.cornerRadius,
    this.borderWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'borderColor': borderColor,
      'cornerRadius': cornerRadius,
      'borderWidth': borderWidth,
    };
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
  final String? localizationBundle;
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
  final String? cardMaskViewStrokeColor;
  final String? cardMaskViewBackgroundColor;
  final String? maskCardColor;
  final String? maskBorderStrokeColor;
  final String? idTurBackgroundColor;
  final String? buttonTextColor;
  final String? footerButtonColorSuccess;
  final String? footerButtonColorError;
  final bool? iqaEnabled;
  final int? iqaSuccessAutoDismissDelay;

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
    this.localizationBundle,
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
    this.cardMaskViewStrokeColor,
    this.cardMaskViewBackgroundColor,
    this.maskCardColor,
    this.maskBorderStrokeColor,
    this.idTurBackgroundColor,
    this.buttonTextColor,
    this.footerButtonColorSuccess,
    this.footerButtonColorError,
    this.iqaEnabled,
    this.iqaSuccessAutoDismissDelay,
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
      'localizationBundle': localizationBundle,
      'localizationTableName': localizationTableName,
      'titleLabelStyle': titleLabelStyle?.toMap(),
      'instructionLabelStyle': instructionLabelStyle?.toMap(),
      'reviewTitleLabelStyle': reviewTitleLabelStyle?.toMap(),
      'reviewInstructionLabelStyle': reviewInstructionLabelStyle?.toMap(),
      'progressBarStyle': progressBarStyle?.toMap(),
      'faceDetection': faceDetection,
      'documentLivenessEnabled': documentLivenessEnabled,
      'successDelay': successDelay,
      'hardwareSupport': hardwareSupport,
      'cardMaskViewStrokeColor': cardMaskViewStrokeColor,
      'cardMaskViewBackgroundColor': cardMaskViewBackgroundColor,
      'maskCardColor': maskCardColor,
      'maskBorderStrokeColor': maskBorderStrokeColor,
      'idTurBackgroundColor': idTurBackgroundColor,
      'buttonTextColor': buttonTextColor,
      'footerButtonColorSuccess': footerButtonColorSuccess,
      'footerButtonColorError': footerButtonColorError,
      'iqaEnabled': iqaEnabled,
      'iqaSuccessAutoDismissDelay': iqaSuccessAutoDismissDelay,
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
