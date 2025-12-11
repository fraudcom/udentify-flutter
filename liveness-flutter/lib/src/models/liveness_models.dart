/// Face Recognition & Liveness models for the liveness_flutter plugin.

/// Face recognition method types
enum FaceRecognitionMethod {
  register,
  authentication,
}

/// Face recognition credentials for configuring the SDK
class FaceRecognizerCredentials {
  final String serverURL;
  final String transactionID;
  final String userID;
  final bool autoTake;
  final double errorDelay;
  final double successDelay;
  final bool runInBackground;
  final bool blinkDetectionEnabled;
  final int requestTimeout;
  final double eyesOpenThreshold;
  final double maskConfidence;
  final bool invertedAnimation;
  final bool activeLivenessAutoNextEnabled;

  const FaceRecognizerCredentials({
    required this.serverURL,
    required this.transactionID,
    required this.userID,
    this.autoTake = true,
    this.errorDelay = 0.10,
    this.successDelay = 0.75,
    this.runInBackground = false,
    this.blinkDetectionEnabled = false,
    this.requestTimeout = 10,
    this.eyesOpenThreshold = 0.75,
    this.maskConfidence = 0.95,
    this.invertedAnimation = false,
    this.activeLivenessAutoNextEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'autoTake': autoTake,
      'errorDelay': errorDelay,
      'successDelay': successDelay,
      'runInBackground': runInBackground,
      'blinkDetectionEnabled': blinkDetectionEnabled,
      'requestTimeout': requestTimeout,
      'eyesOpenThreshold': eyesOpenThreshold,
      'maskConfidence': maskConfidence,
      'invertedAnimation': invertedAnimation,
      'activeLivenessAutoNextEnabled': activeLivenessAutoNextEnabled,
    };
  }

  factory FaceRecognizerCredentials.fromMap(Map<String, dynamic> map) {
    return FaceRecognizerCredentials(
      serverURL: map['serverURL'] ?? '',
      transactionID: map['transactionID'] ?? '',
      userID: map['userID'] ?? '',
      autoTake: map['autoTake'] ?? true,
      errorDelay: (map['errorDelay'] ?? 0.10).toDouble(),
      successDelay: (map['successDelay'] ?? 0.75).toDouble(),
      runInBackground: map['runInBackground'] ?? false,
      blinkDetectionEnabled: map['blinkDetectionEnabled'] ?? false,
      requestTimeout: map['requestTimeout'] ?? 10,
      eyesOpenThreshold: (map['eyesOpenThreshold'] ?? 0.75).toDouble(),
      maskConfidence: (map['maskConfidence'] ?? 0.95).toDouble(),
      invertedAnimation: map['invertedAnimation'] ?? false,
      activeLivenessAutoNextEnabled:
          map['activeLivenessAutoNextEnabled'] ?? true,
    );
  }
}

/// Face recognition result status
enum FaceRecognitionStatus {
  success,
  failure,
  photoTaken,
  selfieTaken,
  error,
}

/// Face recognition result message
/// Enhanced FaceIDMessage with comprehensive server response data
class FaceIDMessage {
  final bool success;
  final String? message;
  final String? errorCode;
  final bool? isFailed;
  final Map<String, dynamic>? data;

  // Enhanced result objects
  final FaceIDResult? faceIDResult;
  final LivenessResult? livenessResult;
  final ActiveLivenessResult? activeLivenessResult;

  const FaceIDMessage({
    required this.success,
    this.message,
    this.errorCode,
    this.isFailed,
    this.data,
    this.faceIDResult,
    this.livenessResult,
    this.activeLivenessResult,
  });

  factory FaceIDMessage.fromMap(Map<String, dynamic> map) {
    return FaceIDMessage(
      success: map['success'] ?? false,
      message: map['message'],
      errorCode: map['errorCode'],
      isFailed: map['isFailed'],
      data: map['data'],
      faceIDResult: map['faceIDResult'] != null
          ? FaceIDResult.fromMap(Map<String, dynamic>.from(map['faceIDResult']))
          : null,
      livenessResult: map['livenessResult'] != null
          ? LivenessResult.fromMap(
              Map<String, dynamic>.from(map['livenessResult']))
          : null,
      activeLivenessResult: map['activeLivenessResult'] != null
          ? ActiveLivenessResult.fromMap(
              Map<String, dynamic>.from(map['activeLivenessResult']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'errorCode': errorCode,
      'isFailed': isFailed,
      'data': data,
      'faceIDResult': faceIDResult?.toMap(),
      'livenessResult': livenessResult?.toMap(),
      'activeLivenessResult': activeLivenessResult?.toMap(),
    };
  }
}

/// Comprehensive FaceIDResult model with all server response data
class FaceIDResult {
  final bool verified;
  final double matchScore;
  final String? transactionID;
  final String? userID;
  final String? method;
  final String? header;
  final String description;
  final String? listNames;
  final String? listIds;
  final String? registrationTransactionID;
  final String? referencePhotoBase64;
  final FaceRecognitionError? error;

  // RAW SERVER RESPONSE DATA
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? rawServerResponse;

  const FaceIDResult({
    required this.verified,
    required this.matchScore,
    required this.description,
    this.transactionID,
    this.userID,
    this.method,
    this.header,
    this.listNames,
    this.listIds,
    this.registrationTransactionID,
    this.referencePhotoBase64,
    this.error,
    this.metadata,
    this.rawServerResponse,
  });

  factory FaceIDResult.fromMap(Map<String, dynamic> map) {
    return FaceIDResult(
      verified: map['verified'] ?? false,
      matchScore: (map['matchScore'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      transactionID: map['transactionID'],
      userID: map['userID'],
      method: map['method'],
      header: map['header'],
      listNames: map['listNames'],
      listIds: map['listIds'],
      registrationTransactionID: map['registrationTransactionID'],
      referencePhotoBase64: map['referencePhotoBase64'],
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(
              Map<String, dynamic>.from(map['error']))
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      rawServerResponse: map['rawServerResponse'] != null
          ? Map<String, dynamic>.from(map['rawServerResponse'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verified': verified,
      'matchScore': matchScore,
      'description': description,
      'transactionID': transactionID,
      'userID': userID,
      'method': method,
      'header': header,
      'listNames': listNames,
      'listIds': listIds,
      'registrationTransactionID': registrationTransactionID,
      'referencePhotoBase64': referencePhotoBase64,
      'error': error?.toMap(),
      'metadata': metadata,
      'rawServerResponse': rawServerResponse,
    };
  }
}

/// Comprehensive LivenessResult model
class LivenessResult {
  final double assessmentValue;
  final String assessmentDescription;
  final double probability;
  final double quality;
  final double livenessScore;
  final String? transactionID;
  final String? assessment;
  final FaceRecognitionError? error;

  const LivenessResult({
    required this.assessmentValue,
    required this.assessmentDescription,
    required this.probability,
    required this.quality,
    required this.livenessScore,
    this.transactionID,
    this.assessment,
    this.error,
  });

  factory LivenessResult.fromMap(Map<String, dynamic> map) {
    return LivenessResult(
      assessmentValue: (map['assessmentValue'] ?? 0.0).toDouble(),
      assessmentDescription: map['assessmentDescription'] ?? '',
      probability: (map['probability'] ?? 0.0).toDouble(),
      quality: (map['quality'] ?? 0.0).toDouble(),
      livenessScore: (map['livenessScore'] ?? 0.0).toDouble(),
      transactionID: map['transactionID'],
      assessment: map['assessment'],
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(
              Map<String, dynamic>.from(map['error']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assessmentValue': assessmentValue,
      'assessmentDescription': assessmentDescription,
      'probability': probability,
      'quality': quality,
      'livenessScore': livenessScore,
      'transactionID': transactionID,
      'assessment': assessment,
      'error': error?.toMap(),
    };
  }
}

/// Comprehensive ActiveLivenessResult model
class ActiveLivenessResult {
  final String? transactionID;
  final Map<String, bool> gestureResult;
  final FaceRecognitionError? error;

  const ActiveLivenessResult({
    this.transactionID,
    required this.gestureResult,
    this.error,
  });

  factory ActiveLivenessResult.fromMap(Map<String, dynamic> map) {
    return ActiveLivenessResult(
      transactionID: map['transactionID'],
      gestureResult: Map<String, bool>.from(map['gestureResult'] ?? {}),
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(
              Map<String, dynamic>.from(map['error']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionID': transactionID,
      'gestureResult': gestureResult,
      'error': error?.toMap(),
    };
  }
}

/// Face recognition error
class FaceRecognitionError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;

  const FaceRecognitionError({
    required this.code,
    required this.message,
    this.details,
  });

  factory FaceRecognitionError.fromMap(Map<String, dynamic> map) {
    return FaceRecognitionError(
      code: map['code'] ?? 'UNKNOWN_ERROR',
      message: map['message'] ?? 'An unknown error occurred',
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }

  @override
  String toString() => 'FaceRecognitionError(code: $code, message: $message)';
}

/// Face recognition result
class FaceRecognitionResult {
  final FaceRecognitionStatus status;
  final FaceIDMessage? faceIDMessage;
  final FaceRecognitionError? error;
  final String? base64Image;

  const FaceRecognitionResult({
    required this.status,
    this.faceIDMessage,
    this.error,
    this.base64Image,
  });

  factory FaceRecognitionResult.success(FaceIDMessage faceIDMessage) {
    return FaceRecognitionResult(
      status: FaceRecognitionStatus.success,
      faceIDMessage: faceIDMessage,
    );
  }

  factory FaceRecognitionResult.failure(FaceRecognitionError error) {
    return FaceRecognitionResult(
      status: FaceRecognitionStatus.failure,
      error: error,
    );
  }

  factory FaceRecognitionResult.photoTaken() {
    return const FaceRecognitionResult(
      status: FaceRecognitionStatus.photoTaken,
    );
  }

  factory FaceRecognitionResult.selfieTaken(String base64Image) {
    return FaceRecognitionResult(
      status: FaceRecognitionStatus.selfieTaken,
      base64Image: base64Image,
    );
  }

  factory FaceRecognitionResult.error(FaceRecognitionError error) {
    return FaceRecognitionResult(
      status: FaceRecognitionStatus.error,
      error: error,
    );
  }

  factory FaceRecognitionResult.fromMap(Map<String, dynamic> map) {
    final statusString = map['status'] ?? 'error';
    final status = FaceRecognitionStatus.values.firstWhere(
      (e) => e.name == statusString,
      orElse: () => FaceRecognitionStatus.error,
    );

    return FaceRecognitionResult(
      status: status,
      faceIDMessage: map['faceIDMessage'] != null
          ? FaceIDMessage.fromMap(map['faceIDMessage'])
          : null,
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(map['error'])
          : null,
      base64Image: map['base64Image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'faceIDMessage': faceIDMessage?.toMap(),
      'error': error?.toMap(),
      'base64Image': base64Image,
    };
  }
}

/// Permission status for camera and other required permissions
enum LivenessPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  unknown,
}

/// Face recognition permission result
class FaceRecognitionPermissionStatus {
  final LivenessPermissionStatus camera;
  final LivenessPermissionStatus readPhoneState;
  final LivenessPermissionStatus internet;

  const FaceRecognitionPermissionStatus({
    required this.camera,
    required this.readPhoneState,
    required this.internet,
  });

  bool get allGranted =>
      camera == LivenessPermissionStatus.granted &&
      readPhoneState == LivenessPermissionStatus.granted &&
      internet == LivenessPermissionStatus.granted;

  factory FaceRecognitionPermissionStatus.fromMap(Map<String, dynamic> map) {
    return FaceRecognitionPermissionStatus(
      camera: _parsePermissionStatus(map['camera']),
      readPhoneState: _parsePermissionStatus(map['readPhoneState']),
      internet: _parsePermissionStatus(map['internet']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'camera': camera.name,
      'readPhoneState': readPhoneState.name,
      'internet': internet.name,
    };
  }

  static LivenessPermissionStatus _parsePermissionStatus(dynamic value) {
    if (value is String) {
      return LivenessPermissionStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => LivenessPermissionStatus.unknown,
      );
    }
    return LivenessPermissionStatus.unknown;
  }
}

/// Customer list for identification feature
class CustomerList {
  final int? id;
  final String? name;
  final String? listRole;
  final String? description;
  final String? creationDate;

  const CustomerList({
    this.id,
    this.name,
    this.listRole,
    this.description,
    this.creationDate,
  });

  factory CustomerList.fromMap(Map<String, dynamic> map) {
    return CustomerList(
      id: map['id']?.toInt(),
      name: map['name'],
      listRole: map['listRole'],
      description: map['description'],
      creationDate: map['creationDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'listRole': listRole,
      'description': description,
      'creationDate': creationDate,
    };
  }
}

/// Response data for identification list operations
class ListResponseData {
  final int? id;
  final CustomerList? customerList;
  final int? userId;

  const ListResponseData({
    this.id,
    this.customerList,
    this.userId,
  });

  factory ListResponseData.fromMap(Map<String, dynamic> map) {
    return ListResponseData(
      id: map['id']?.toInt(),
      customerList: map['customerList'] != null
          ? CustomerList.fromMap(map['customerList'])
          : null,
      userId: map['userId']?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerList': customerList?.toMap(),
      'userId': userId,
    };
  }
}

/// Add user to list result
class AddUserToListResult {
  final bool success;
  final ListResponseData? data;
  final FaceRecognitionError? error;

  const AddUserToListResult({
    required this.success,
    this.data,
    this.error,
  });

  factory AddUserToListResult.success(ListResponseData data) {
    return AddUserToListResult(
      success: true,
      data: data,
    );
  }

  factory AddUserToListResult.failure(FaceRecognitionError error) {
    return AddUserToListResult(
      success: false,
      error: error,
    );
  }

  factory AddUserToListResult.fromMap(Map<String, dynamic> map) {
    return AddUserToListResult(
      success: map['success'] ?? false,
      data: map['data'] != null ? ListResponseData.fromMap(map['data']) : null,
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(map['error'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'data': data?.toMap(),
      'error': error?.toMap(),
    };
  }
}

/// Delete user from list result
class DeleteUserFromListResult {
  final bool success;
  final String? message;
  final String? userID;
  final String? transactionID;
  final String? listName;
  final double? matchScore;
  final String? registrationTransactionID;
  final FaceRecognitionError? error;

  const DeleteUserFromListResult({
    required this.success,
    this.message,
    this.userID,
    this.transactionID,
    this.listName,
    this.matchScore,
    this.registrationTransactionID,
    this.error,
  });

  factory DeleteUserFromListResult.fromMap(Map<String, dynamic> map) {
    return DeleteUserFromListResult(
      success: map['success'] ?? false,
      message: map['message'],
      userID: map['data']?['userID'],
      transactionID: map['data']?['transactionID'],
      listName: map['data']?['listName'],
      matchScore: map['data']?['matchScore']?.toDouble(),
      registrationTransactionID: map['data']?['registrationTransactionID'],
      error: map['error'] != null
          ? FaceRecognitionError.fromMap(map['error'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'message': message,
      'data': {
        'userID': userID,
        'transactionID': transactionID,
        'listName': listName,
        'matchScore': matchScore,
        'registrationTransactionID': registrationTransactionID,
      },
      'error': error?.toMap(),
    };
  }
}

/// UI Settings for customizing appearance (matches React Native structure)
class UISettings {
  final UIColors? colors;
  final UIFonts? fonts;
  final UIDimensions? dimensions;
  final UIConfigs? configs;

  const UISettings({
    this.colors,
    this.fonts,
    this.dimensions,
    this.configs,
  });

  Map<String, dynamic> toMap() {
    return {
      'colors': colors?.toMap(),
      'fonts': fonts?.toMap(),
      'dimensions': dimensions?.toMap(),
      'configs': configs?.toMap(),
    };
  }
}

/// UI Colors configuration
class UIColors {
  final String? titleColor;
  final String? titleBG;
  final String? buttonErrorColor;
  final String? buttonSuccessColor;
  final String? buttonColor;
  final String? buttonTextColor;
  final String? buttonErrorTextColor;
  final String? buttonSuccessTextColor;
  final String? buttonBackColor;
  final String? footerTextColor;
  final String? checkmarkTintColor;
  final String? backgroundColor;

  const UIColors({
    this.titleColor,
    this.titleBG,
    this.buttonErrorColor,
    this.buttonSuccessColor,
    this.buttonColor,
    this.buttonTextColor,
    this.buttonErrorTextColor,
    this.buttonSuccessTextColor,
    this.buttonBackColor,
    this.footerTextColor,
    this.checkmarkTintColor,
    this.backgroundColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'titleColor': titleColor,
      'titleBG': titleBG,
      'buttonErrorColor': buttonErrorColor,
      'buttonSuccessColor': buttonSuccessColor,
      'buttonColor': buttonColor,
      'buttonTextColor': buttonTextColor,
      'buttonErrorTextColor': buttonErrorTextColor,
      'buttonSuccessTextColor': buttonSuccessTextColor,
      'buttonBackColor': buttonBackColor,
      'footerTextColor': footerTextColor,
      'checkmarkTintColor': checkmarkTintColor,
      'backgroundColor': backgroundColor,
    };
  }
}

/// UI Fonts configuration
class UIFonts {
  final FontConfig? titleFont;
  final FontConfig? buttonFont;
  final FontConfig? footerFont;

  const UIFonts({
    this.titleFont,
    this.buttonFont,
    this.footerFont,
  });

  Map<String, dynamic> toMap() {
    return {
      'titleFont': titleFont?.toMap(),
      'buttonFont': buttonFont?.toMap(),
      'footerFont': footerFont?.toMap(),
    };
  }
}

/// Font configuration
class FontConfig {
  final String name;
  final double size;

  const FontConfig({
    required this.name,
    required this.size,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
    };
  }
}

/// UI Dimensions configuration (matches React Native structure)
class UIDimensions {
  final double? buttonHeight;
  final double? buttonMarginLeft;
  final double? buttonMarginRight;
  final double? buttonCornerRadius;
  final double? gestureFontSize;

  const UIDimensions({
    this.buttonHeight,
    this.buttonMarginLeft,
    this.buttonMarginRight,
    this.buttonCornerRadius,
    this.gestureFontSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'buttonHeight': buttonHeight,
      'buttonMarginLeft': buttonMarginLeft,
      'buttonMarginRight': buttonMarginRight,
      'buttonCornerRadius': buttonCornerRadius,
      'gestureFontSize': gestureFontSize,
    };
  }
}

/// UI Configs
class UIConfigs {
  final String? cameraPosition; // "front" or "back"
  final int? requestTimeout;
  final bool? autoTake;
  final double? errorDelay;
  final double? successDelay;
  final String? tableName;
  final bool? maskDetection;
  final double? maskConfidence;
  final bool? invertedAnimation;
  final bool? backButtonEnabled;
  final bool? multipleFacesRejected;
  final double? buttonHeight;
  final double? buttonMarginLeft;
  final double? buttonMarginRight;
  final double? buttonCornerRadius;
  final ProgressBarStyle? progressBarStyle;

  const UIConfigs({
    this.cameraPosition,
    this.requestTimeout,
    this.autoTake,
    this.errorDelay,
    this.successDelay,
    this.tableName,
    this.maskDetection,
    this.maskConfidence,
    this.invertedAnimation,
    this.backButtonEnabled,
    this.multipleFacesRejected,
    this.buttonHeight,
    this.buttonMarginLeft,
    this.buttonMarginRight,
    this.buttonCornerRadius,
    this.progressBarStyle,
  });

  Map<String, dynamic> toMap() {
    return {
      'cameraPosition': cameraPosition,
      'requestTimeout': requestTimeout,
      'autoTake': autoTake,
      'errorDelay': errorDelay,
      'successDelay': successDelay,
      'tableName': tableName,
      'maskDetection': maskDetection,
      'maskConfidence': maskConfidence,
      'invertedAnimation': invertedAnimation,
      'backButtonEnabled': backButtonEnabled,
      'multipleFacesRejected': multipleFacesRejected,
      'buttonHeight': buttonHeight,
      'buttonMarginLeft': buttonMarginLeft,
      'buttonMarginRight': buttonMarginRight,
      'buttonCornerRadius': buttonCornerRadius,
      'progressBarStyle': progressBarStyle?.toMap(),
    };
  }
}

/// Progress bar style configuration
class ProgressBarStyle {
  final String? backgroundColor;
  final String? progressColor;
  final String? completionColor;
  final TextStyle? textStyle;
  final double? cornerRadius;

  const ProgressBarStyle({
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

/// Text style configuration
class TextStyle {
  final FontConfig? font;
  final String? textColor;
  final String?
      textAlignment; // "left", "right", "center", "justified", "natural"
  final String?
      lineBreakMode; // "byWordWrapping", "byTruncatingTail", "byTruncatingHead", "byClipping"
  final int? numberOfLines;
  final double? leading;
  final double? trailing;

  const TextStyle({
    this.font,
    this.textColor,
    this.textAlignment,
    this.lineBreakMode,
    this.numberOfLines,
    this.leading,
    this.trailing,
  });

  Map<String, dynamic> toMap() {
    return {
      'font': font?.toMap(),
      'textColor': textColor,
      'textAlignment': textAlignment,
      'lineBreakMode': lineBreakMode,
      'numberOfLines': numberOfLines,
      'leading': leading,
      'trailing': trailing,
    };
  }
}
