/// Video Call Credentials
class VideoCallCredentials {
  final String serverURL;
  final String wssURL;
  final String userID;
  final String transactionID;
  final String clientName;
  final String idleTimeout;

  const VideoCallCredentials({
    required this.serverURL,
    required this.wssURL,
    required this.userID,
    required this.transactionID,
    required this.clientName,
    this.idleTimeout = "30",
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'wssURL': wssURL,
      'userID': userID,
      'transactionID': transactionID,
      'clientName': clientName,
      'idleTimeout': idleTimeout,
    };
  }

  factory VideoCallCredentials.fromMap(Map<String, dynamic> map) {
    return VideoCallCredentials(
      serverURL: map['serverURL'] ?? '',
      wssURL: map['wssURL'] ?? '',
      userID: map['userID'] ?? '',
      transactionID: map['transactionID'] ?? '',
      clientName: map['clientName'] ?? '',
      idleTimeout: map['idleTimeout'] ?? '30',
    );
  }
}

/// Video Call Status
enum VideoCallStatus {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  completed;

  static VideoCallStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'idle':
        return VideoCallStatus.idle;
      case 'connecting':
        return VideoCallStatus.connecting;
      case 'connected':
        return VideoCallStatus.connected;
      case 'disconnected':
        return VideoCallStatus.disconnected;
      case 'failed':
        return VideoCallStatus.failed;
      case 'completed':
        return VideoCallStatus.completed;
      default:
        return VideoCallStatus.idle;
    }
  }

  @override
  String toString() {
    switch (this) {
      case VideoCallStatus.idle:
        return 'idle';
      case VideoCallStatus.connecting:
        return 'connecting';
      case VideoCallStatus.connected:
        return 'connected';
      case VideoCallStatus.disconnected:
        return 'disconnected';
      case VideoCallStatus.failed:
        return 'failed';
      case VideoCallStatus.completed:
        return 'completed';
    }
  }
}

/// Video Call Error Types
enum VideoCallErrorType {
  unknown,
  credentialsMissing,
  serverTimeout,
  transactionNotFound,
  transactionFailed,
  transactionExpired,
  transactionAlreadyCompleted,
  sdkNotAvailable;

  static VideoCallErrorType fromString(String value) {
    switch (value) {
      case 'ERR_UNKNOWN':
        return VideoCallErrorType.unknown;
      case 'ERR_CREDENTIALS_MISSING':
        return VideoCallErrorType.credentialsMissing;
      case 'ERR_SERVER_TIMEOUT_EXCEPTION':
        return VideoCallErrorType.serverTimeout;
      case 'ERR_TRANSACTION_NOT_FOUND':
        return VideoCallErrorType.transactionNotFound;
      case 'ERR_TRANSACTION_FAILED':
        return VideoCallErrorType.transactionFailed;
      case 'ERR_TRANSACTION_EXPIRED':
        return VideoCallErrorType.transactionExpired;
      case 'ERR_TRANSACTION_ALREADY_COMPLETED':
        return VideoCallErrorType.transactionAlreadyCompleted;
      case 'ERR_SDK_NOT_AVAILABLE':
        return VideoCallErrorType.sdkNotAvailable;
      default:
        return VideoCallErrorType.unknown;
    }
  }

  @override
  String toString() {
    switch (this) {
      case VideoCallErrorType.unknown:
        return 'ERR_UNKNOWN';
      case VideoCallErrorType.credentialsMissing:
        return 'ERR_CREDENTIALS_MISSING';
      case VideoCallErrorType.serverTimeout:
        return 'ERR_SERVER_TIMEOUT_EXCEPTION';
      case VideoCallErrorType.transactionNotFound:
        return 'ERR_TRANSACTION_NOT_FOUND';
      case VideoCallErrorType.transactionFailed:
        return 'ERR_TRANSACTION_FAILED';
      case VideoCallErrorType.transactionExpired:
        return 'ERR_TRANSACTION_EXPIRED';
      case VideoCallErrorType.transactionAlreadyCompleted:
        return 'ERR_TRANSACTION_ALREADY_COMPLETED';
      case VideoCallErrorType.sdkNotAvailable:
        return 'ERR_SDK_NOT_AVAILABLE';
    }
  }
}

/// Video Call Error
class VideoCallError {
  final VideoCallErrorType type;
  final String message;
  final String? details;

  const VideoCallError({
    required this.type,
    required this.message,
    this.details,
  });

  factory VideoCallError.fromMap(Map<String, dynamic> map) {
    return VideoCallError(
      type: VideoCallErrorType.fromString(map['type'] ?? 'ERR_UNKNOWN'),
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'type': type.toString(), 'message': message, 'details': details};
  }
}

/// Video Call Result
class VideoCallResult {
  final bool success;
  final VideoCallStatus? status;
  final String? transactionID;
  final VideoCallError? error;
  final Map<String, dynamic>? metadata;

  const VideoCallResult({
    required this.success,
    this.status,
    this.transactionID,
    this.error,
    this.metadata,
  });

  factory VideoCallResult.fromMap(Map<String, dynamic> map) {
    return VideoCallResult(
      success: map['success'] ?? false,
      status: map['status'] != null
          ? VideoCallStatus.fromString(map['status'])
          : null,
      transactionID: map['transactionID'],
      error: map['error'] != null ? VideoCallError.fromMap(map['error']) : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'status': status?.toString(),
      'transactionID': transactionID,
      'error': error?.toMap(),
      'metadata': metadata,
    };
  }
}

/// Video Call Configuration
class VideoCallConfig {
  final String? backgroundColor;
  final String? textColor;
  final String? pipViewBorderColor;
  final String? notificationLabelDefault;
  final String? notificationLabelCountdown;
  final String? notificationLabelTokenFetch;

  const VideoCallConfig({
    this.backgroundColor,
    this.textColor,
    this.pipViewBorderColor,
    this.notificationLabelDefault,
    this.notificationLabelCountdown,
    this.notificationLabelTokenFetch,
  });

  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'pipViewBorderColor': pipViewBorderColor,
      'notificationLabelDefault': notificationLabelDefault,
      'notificationLabelCountdown': notificationLabelCountdown,
      'notificationLabelTokenFetch': notificationLabelTokenFetch,
    };
  }

  factory VideoCallConfig.fromMap(Map<String, dynamic> map) {
    return VideoCallConfig(
      backgroundColor: map['backgroundColor'],
      textColor: map['textColor'],
      pipViewBorderColor: map['pipViewBorderColor'],
      notificationLabelDefault: map['notificationLabelDefault'],
      notificationLabelCountdown: map['notificationLabelCountdown'],
      notificationLabelTokenFetch: map['notificationLabelTokenFetch'],
    );
  }
}

/// Permission Status for Video Call
class VideoCallPermissionStatus {
  final bool hasCameraPermission;
  final bool hasPhoneStatePermission;
  final bool hasInternetPermission;
  final bool hasRecordAudioPermission;

  const VideoCallPermissionStatus({
    required this.hasCameraPermission,
    required this.hasPhoneStatePermission,
    required this.hasInternetPermission,
    required this.hasRecordAudioPermission,
  });

  factory VideoCallPermissionStatus.fromMap(Map<String, dynamic> map) {
    return VideoCallPermissionStatus(
      hasCameraPermission: map['hasCameraPermission'] ?? false,
      hasPhoneStatePermission: map['hasPhoneStatePermission'] ?? false,
      hasInternetPermission: map['hasInternetPermission'] ?? false,
      hasRecordAudioPermission: map['hasRecordAudioPermission'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasCameraPermission': hasCameraPermission,
      'hasPhoneStatePermission': hasPhoneStatePermission,
      'hasInternetPermission': hasInternetPermission,
      'hasRecordAudioPermission': hasRecordAudioPermission,
    };
  }

  bool get allGranted =>
      hasCameraPermission &&
      hasPhoneStatePermission &&
      hasInternetPermission &&
      hasRecordAudioPermission;
}
