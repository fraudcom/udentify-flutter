/// Video Call Credentials
class VideoCallCredentials {
  final String serverURL;
  final String wssURL;
  final String userID;
  final String transactionID;
  final String clientName;
  final String idleTimeout;

  /// Frames per second for the call camera. Leave `null` to keep each native
  /// SDK's own default (they differ per platform). The SDK clamps a rate the
  /// sensor cannot deliver; non-positive values are ignored.
  final double? cameraFeedFrameRate;

  /// What the remote operator sees while an in-call LiveKYC step runs. Leave `null` to keep
  /// the SDK's own default (`cameraFeed`). On Android this is a call credential; on iOS it
  /// doubles as the LiveKYC switch (see [liveKYCOptions] for the full configuration).
  final VideoCallObservationMode? observationMode;

  /// Per-session configuration of the in-call LiveKYC steps, **iOS only** (Android is
  /// configured through each capture package's `setRepeatConfig`). Its presence is the
  /// switch: pass it to enable LiveKYC, omit it to run a plain call. Fixed for the session.
  final VideoCallLiveKYCOptions? liveKYCOptions;

  /// Verbosity of the SDK's own logging, **iOS only** (the Android SDK has no such setting).
  /// Leave `null` for the SDK's default, `info`.
  final VideoCallLogLevel? logLevel;

  const VideoCallCredentials({
    required this.serverURL,
    required this.wssURL,
    required this.userID,
    required this.transactionID,
    required this.clientName,
    this.idleTimeout = "30",
    this.cameraFeedFrameRate,
    this.observationMode,
    this.liveKYCOptions,
    this.logLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'wssURL': wssURL,
      'userID': userID,
      'transactionID': transactionID,
      'clientName': clientName,
      'idleTimeout': idleTimeout,
      if (cameraFeedFrameRate != null) 'cameraFeedFrameRate': cameraFeedFrameRate,
      if (observationMode != null) 'observationMode': observationMode!.value,
      if (liveKYCOptions != null) 'liveKYCOptions': liveKYCOptions!.toMap(),
      if (logLevel != null) 'logLevel': logLevel!.value,
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
      cameraFeedFrameRate: (map['cameraFeedFrameRate'] as num?)?.toDouble(),
      observationMode:
          VideoCallObservationMode.fromString(map['observationMode'] as String?),
      logLevel: VideoCallLogLevel.fromString(map['logLevel'] as String?),
    );
  }
}

/// How much the SDK writes to its own log, **iOS only**. The names are the SDK's `LogLevel` cases.
enum VideoCallLogLevel {
  verbose('verbose'),
  debug('debug'),
  info('info'),
  warning('warning'),
  error('error');

  final String value;
  const VideoCallLogLevel(this.value);

  static VideoCallLogLevel? fromString(String? value) {
    for (final level in VideoCallLogLevel.values) {
      if (level.value == value) return level;
    }
    return null;
  }
}

/// Video Call Status
enum VideoCallStatus {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  completed,
  initiating,
  tokenFetching,
  tokenFetched,
  reconnecting,
  unknown;

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
      case 'initiating':
        return VideoCallStatus.initiating;
      case 'tokenfetching':
        return VideoCallStatus.tokenFetching;
      case 'tokenfetched':
        return VideoCallStatus.tokenFetched;
      case 'reconnecting':
        return VideoCallStatus.reconnecting;
      default:
        return VideoCallStatus.unknown;
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
      case VideoCallStatus.initiating:
        return 'initiating';
      case VideoCallStatus.tokenFetching:
        return 'tokenFetching';
      case VideoCallStatus.tokenFetched:
        return 'tokenFetched';
      case VideoCallStatus.reconnecting:
        return 'reconnecting';
      case VideoCallStatus.unknown:
        return 'unknown';
    }
  }
}

/// State of a device phone call overlapping the video call, as reported by
/// the native `onPhoneCallStateChanged` event. Informational only: the SDK
/// keeps the call connected while the system call UI is in front.
enum VideoCallPhoneCallState {
  incoming,
  outgoing,
  connected,
  ended;

  static VideoCallPhoneCallState fromString(String value) {
    switch (value.toLowerCase()) {
      case 'incoming':
        return VideoCallPhoneCallState.incoming;
      case 'outgoing':
        return VideoCallPhoneCallState.outgoing;
      case 'connected':
        return VideoCallPhoneCallState.connected;
      default:
        return VideoCallPhoneCallState.ended;
    }
  }
}

/// Video Call Participant State
///
/// Describes a state transition for a remote participant (agent/supervisor)
/// in the call, as reported by the native `onParticipantStateChanged` event.
class VideoCallParticipantState {
  final String? participantType;
  final String state;

  const VideoCallParticipantState({this.participantType, required this.state});

  factory VideoCallParticipantState.fromMap(Map<String, dynamic> map) {
    return VideoCallParticipantState(
      participantType: map['participantType'],
      state: map['state'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {'participantType': participantType, 'state': state};
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
  sdkNotAvailable,
  sdk,
  cameraPermissionRequired,
  cameraPermissionDenied,
  microphonePermissionRequired,
  microphonePermissionDenied;

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
      case 'ERR_SDK':
        return VideoCallErrorType.sdk;
      case 'ERR_CAMERA_PERMISSION_REQUIRED':
        return VideoCallErrorType.cameraPermissionRequired;
      case 'ERR_CAMERA_PERMISSION_DENIED':
        return VideoCallErrorType.cameraPermissionDenied;
      case 'ERR_MICROPHONE_PERMISSION_REQUIRED':
        return VideoCallErrorType.microphonePermissionRequired;
      case 'ERR_MICROPHONE_PERMISSION_DENIED':
        return VideoCallErrorType.microphonePermissionDenied;
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
      case VideoCallErrorType.sdk:
        return 'ERR_SDK';
      case VideoCallErrorType.cameraPermissionRequired:
        return 'ERR_CAMERA_PERMISSION_REQUIRED';
      case VideoCallErrorType.cameraPermissionDenied:
        return 'ERR_CAMERA_PERMISSION_DENIED';
      case VideoCallErrorType.microphonePermissionRequired:
        return 'ERR_MICROPHONE_PERMISSION_REQUIRED';
      case VideoCallErrorType.microphonePermissionDenied:
        return 'ERR_MICROPHONE_PERMISSION_DENIED';
    }
  }
}

/// Video Call Error
class VideoCallError {
  final VideoCallErrorType type;

  /// The code exactly as the native layer sent it. [type] is [VideoCallErrorType.unknown] for a code the enum
  /// does not list, for example one the plugin raises itself (`NO_ACTIVE_CALL`, `ALREADY_IN_PROGRESS`,
  /// `CANCEL_VIDEO_CALL_FAILED`, `INVALID_ARGUMENTS`, ...); read [code] for those. Null when the failure
  /// never reached the native layer.
  final String? code;
  final String message;
  final String? details;

  const VideoCallError({
    required this.type,
    this.code,
    required this.message,
    this.details,
  });

  factory VideoCallError.fromMap(Map<String, dynamic> map) {
    // The native layers send the SDK's `ERR_*` name as `type`; a `code`, when there is one, wins.
    final code = (map['code'] ?? map['type'])?.toString();
    return VideoCallError(
      type: VideoCallErrorType.fromString(map['type'] ?? 'ERR_UNKNOWN'),
      code: code,
      message: map['message'] ?? '',
      details: map['details'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'type': type.toString(), 'code': code, 'message': message, 'details': details};
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
      // Nested maps arrive from the platform channel as Map<Object?, Object?>, so they are converted rather
      // than cast.
      error: map['error'] is Map
          ? VideoCallError.fromMap(Map<String, dynamic>.from(map['error'] as Map))
          : null,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata'] as Map) : null,
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

/// Where an element sits horizontally inside the call view.
enum VideoCallHorizontalPositionType { center, left, right, custom }

/// Where an element sits vertically inside the call view.
enum VideoCallVerticalPositionType { center, top, bottom, custom }

/// Font weight of the instruction label. Below Android API 28 the platform has only two weights, so
/// `regular` and `medium` round to normal and `semibold` and `bold` round to bold.
enum VideoCallFontWeight { regular, medium, semibold, bold }

/// Horizontal alignment of the instruction label.
enum VideoCallTextAlign { left, center, right }

/// Horizontal placement inside the call view, in dp.
///
/// - [VideoCallHorizontalPositionType.center]: centered, then shifted by a signed [offset]
///   (positive towards the trailing edge).
/// - [VideoCallHorizontalPositionType.left] / [VideoCallHorizontalPositionType.right]: [offset] in
///   from that edge.
/// - [VideoCallHorizontalPositionType.custom]: [x] from the leading edge.
class VideoCallHorizontalPosition {
  final VideoCallHorizontalPositionType type;
  final double? offset;
  final double? x;

  const VideoCallHorizontalPosition(this.type, {this.offset, this.x});

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (offset != null) 'offset': offset,
        if (x != null) 'x': x,
      };
}

/// Vertical placement inside the call view, in dp. [offset] is the inset from `top` / `bottom`;
/// [y] is the distance from the top edge for `custom`. `center` takes no offset.
class VideoCallVerticalPosition {
  final VideoCallVerticalPositionType type;
  final double? offset;
  final double? y;

  const VideoCallVerticalPosition(this.type, {this.offset, this.y});

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (offset != null) 'offset': offset,
        if (y != null) 'y': y,
      };
}

/// Stretch an element horizontally between two insets (dp) instead of giving it a fixed width.
class VideoCallHorizontalAnchors {
  final double leading;
  final double trailing;

  const VideoCallHorizontalAnchors({required this.leading, required this.trailing});

  Map<String, dynamic> toMap() => {'leading': leading, 'trailing': trailing};
}

/// Stretch an element vertically between two insets (dp) instead of giving it a fixed height.
class VideoCallVerticalAnchors {
  final double top;
  final double bottom;

  const VideoCallVerticalAnchors({required this.top, required this.bottom});

  Map<String, dynamic> toMap() => {'top': top, 'bottom': bottom};
}

/// Picture-in-picture (local camera preview) styling. Every field is optional and an omitted one
/// keeps the SDK's own value. Colors are `#RGB`, `#RRGGBB` or `#AARRGGBB`.
class VideoCallPipViewStyle {
  /// Hide the preview entirely. **Android only.**
  final bool? visible;

  /// Fixed size in dp. Ignored when the matching anchors are set.
  final double? width;
  final double? height;
  final VideoCallHorizontalPosition? horizontalPosition;
  final VideoCallVerticalPosition? verticalPosition;
  final VideoCallHorizontalAnchors? horizontalAnchors;
  final VideoCallVerticalAnchors? verticalAnchors;

  /// Fill shown behind the preview before the local camera attaches.
  final String? backgroundColor;
  final String? borderColor;
  final double? borderWidth;
  final double? cornerRadius;

  const VideoCallPipViewStyle({
    this.visible,
    this.width,
    this.height,
    this.horizontalPosition,
    this.verticalPosition,
    this.horizontalAnchors,
    this.verticalAnchors,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.cornerRadius,
  });

  Map<String, dynamic> toMap() => {
        if (visible != null) 'visible': visible,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
        if (horizontalPosition != null) 'horizontalPosition': horizontalPosition!.toMap(),
        if (verticalPosition != null) 'verticalPosition': verticalPosition!.toMap(),
        if (horizontalAnchors != null) 'horizontalAnchors': horizontalAnchors!.toMap(),
        if (verticalAnchors != null) 'verticalAnchors': verticalAnchors!.toMap(),
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (borderColor != null) 'borderColor': borderColor,
        if (borderWidth != null) 'borderWidth': borderWidth,
        if (cornerRadius != null) 'cornerRadius': cornerRadius,
      };
}

/// Mute button styling. Every field is optional and an omitted one keeps the SDK's own value.
class VideoCallMuteButtonStyle {
  /// Hide the button. **Android only.**
  final bool? visible;

  /// Width and height in dp.
  final double? size;

  /// Tint while the microphone is muted / live.
  final String? mutedColor;
  final String? unmutedColor;
  final VideoCallHorizontalPosition? horizontalPosition;
  final VideoCallVerticalPosition? verticalPosition;

  const VideoCallMuteButtonStyle({
    this.visible,
    this.size,
    this.mutedColor,
    this.unmutedColor,
    this.horizontalPosition,
    this.verticalPosition,
  });

  Map<String, dynamic> toMap() => {
        if (visible != null) 'visible': visible,
        if (size != null) 'size': size,
        if (mutedColor != null) 'mutedColor': mutedColor,
        if (unmutedColor != null) 'unmutedColor': unmutedColor,
        if (horizontalPosition != null) 'horizontalPosition': horizontalPosition!.toMap(),
        if (verticalPosition != null) 'verticalPosition': verticalPosition!.toMap(),
      };
}

/// Front/back camera switch button styling. The button has one icon, whichever camera is active.
class VideoCallCameraSwitchButtonStyle {
  /// Hide the button. **Android only.**
  final bool? visible;
  final double? size;

  /// Icon tint. Leave unset to keep the SDK's own colour.
  final String? color;
  final VideoCallHorizontalPosition? horizontalPosition;
  final VideoCallVerticalPosition? verticalPosition;

  const VideoCallCameraSwitchButtonStyle({
    this.visible,
    this.size,
    this.color,
    this.horizontalPosition,
    this.verticalPosition,
  });

  Map<String, dynamic> toMap() => {
        if (visible != null) 'visible': visible,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        if (horizontalPosition != null) 'horizontalPosition': horizontalPosition!.toMap(),
        if (verticalPosition != null) 'verticalPosition': verticalPosition!.toMap(),
      };
}

/// Torch button styling. **Android only**, ignored on iOS, which has no flash button. Hidden by
/// default; set `visible: true` to show it.
class VideoCallFlashButtonStyle {
  final bool? visible;
  final double? size;
  final String? color;
  final VideoCallHorizontalPosition? horizontalPosition;
  final VideoCallVerticalPosition? verticalPosition;

  const VideoCallFlashButtonStyle({
    this.visible,
    this.size,
    this.color,
    this.horizontalPosition,
    this.verticalPosition,
  });

  Map<String, dynamic> toMap() => {
        if (visible != null) 'visible': visible,
        if (size != null) 'size': size,
        if (color != null) 'color': color,
        if (horizontalPosition != null) 'horizontalPosition': horizontalPosition!.toMap(),
        if (verticalPosition != null) 'verticalPosition': verticalPosition!.toMap(),
      };
}

/// Styling for the label on the waiting screen, before the agent joins. Every field is optional and
/// an omitted one keeps the SDK's own value.
class VideoCallInstructionLabelStyle {
  final double? fontSize;
  final VideoCallFontWeight? fontWeight;

  /// A `UIFont` name on iOS, a `Typeface.create` family name on Android. Unset uses the system font.
  final String? fontFamily;
  final String? textColor;
  final VideoCallTextAlign? textAlign;

  /// `0` means as many lines as needed.
  final int? numberOfLines;

  /// Line-height multiplier; `0` leaves the platform default.
  final double? lineHeightMultiple;

  /// Insets in dp.
  final double? leading;
  final double? trailing;
  final VideoCallVerticalPosition? verticalPosition;

  const VideoCallInstructionLabelStyle({
    this.fontSize,
    this.fontWeight,
    this.fontFamily,
    this.textColor,
    this.textAlign,
    this.numberOfLines,
    this.lineHeightMultiple,
    this.leading,
    this.trailing,
    this.verticalPosition,
  });

  Map<String, dynamic> toMap() => {
        if (fontSize != null) 'fontSize': fontSize,
        if (fontWeight != null) 'fontWeight': fontWeight!.name,
        if (fontFamily != null) 'fontFamily': fontFamily,
        if (textColor != null) 'textColor': textColor,
        if (textAlign != null) 'textAlign': textAlign!.name,
        if (numberOfLines != null) 'numberOfLines': numberOfLines,
        if (lineHeightMultiple != null) 'lineHeightMultiple': lineHeightMultiple,
        if (leading != null) 'leading': leading,
        if (trailing != null) 'trailing': trailing,
        if (verticalPosition != null) 'verticalPosition': verticalPosition!.toMap(),
      };
}

/// Video Call Configuration (the styler). Set it with `VideoCallFlutter.setVideoCallConfig` before
/// `startVideoCall`. Every field is optional: what the app does not set keeps the SDK's own look.
/// Colors are `#RGB`, `#RRGGBB` or `#AARRGGBB`.
class VideoCallConfig {
  /// Fill behind the remote video and the waiting screen.
  final String? backgroundColor;

  /// Instruction label colour. Shorthand for `instructionLabelStyle.textColor`, which wins.
  final String? textColor;

  /// PiP border colour. Shorthand for `pipViewStyle.borderColor`, which wins.
  final String? pipViewBorderColor;

  final VideoCallPipViewStyle? pipViewStyle;
  final VideoCallMuteButtonStyle? muteButtonStyle;
  final VideoCallCameraSwitchButtonStyle? cameraSwitchButtonStyle;

  /// Android only.
  final VideoCallFlashButtonStyle? flashButtonStyle;

  final VideoCallInstructionLabelStyle? instructionLabelStyle;

  /// **iOS only.** The strings table the SDK reads its texts from.
  final String? tableName;

  /// **iOS only.** The Android SDK exposes no request timeout.
  final double? requestTimeout;

  const VideoCallConfig({
    this.backgroundColor,
    this.textColor,
    this.pipViewBorderColor,
    this.pipViewStyle,
    this.muteButtonStyle,
    this.cameraSwitchButtonStyle,
    this.flashButtonStyle,
    this.instructionLabelStyle,
    this.tableName,
    this.requestTimeout,
  });

  /// Only what was set is sent, so the native side can tell "not styled" from "styled".
  Map<String, dynamic> toMap() {
    return {
      if (backgroundColor != null) 'backgroundColor': backgroundColor,
      if (textColor != null) 'textColor': textColor,
      if (pipViewBorderColor != null) 'pipViewBorderColor': pipViewBorderColor,
      if (pipViewStyle != null) 'pipViewStyle': pipViewStyle!.toMap(),
      if (muteButtonStyle != null) 'muteButtonStyle': muteButtonStyle!.toMap(),
      if (cameraSwitchButtonStyle != null) 'cameraSwitchButtonStyle': cameraSwitchButtonStyle!.toMap(),
      if (flashButtonStyle != null) 'flashButtonStyle': flashButtonStyle!.toMap(),
      if (instructionLabelStyle != null) 'instructionLabelStyle': instructionLabelStyle!.toMap(),
      if (tableName != null) 'tableName': tableName,
      if (requestTimeout != null) 'requestTimeout': requestTimeout,
    };
  }

  /// Reads the three flat colour fields back. The style objects are one-way (Dart to native).
  factory VideoCallConfig.fromMap(Map<String, dynamic> map) {
    return VideoCallConfig(
      backgroundColor: map['backgroundColor'],
      textColor: map['textColor'],
      pipViewBorderColor: map['pipViewBorderColor'],
      tableName: map['tableName'],
      requestTimeout: (map['requestTimeout'] as num?)?.toDouble(),
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


/// What the remote operator sees of the customer while an in-call LiveKYC step runs.
enum VideoCallObservationMode {
  /// The SDK's default: the operator sees the capture module's camera feed. Needs no screen
  /// capture permission.
  cameraFeed('CAMERA_FEED'),

  /// The operator sees the customer's screen. Ships as **beta** and is untested end to end:
  /// it needs Android's MediaProjection permission.
  screenShare('SCREEN_SHARE'),

  /// The operator sees progress only, no live picture.
  progressOnly('PROGRESS_ONLY');

  final String value;
  const VideoCallObservationMode(this.value);

  static VideoCallObservationMode? fromString(String? value) {
    for (final mode in VideoCallObservationMode.values) {
      if (mode.value == value) return mode;
    }
    return null;
  }
}

/// The capture flow an in-call repeat runs.
enum VideoCallRepeatRole {
  ocr,
  face,
  nfc,

  /// Emitted by the SDK but not implemented by it; surfaced so the event is not silently lost.
  hologram;

  static VideoCallRepeatRole? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'OCR':
        return VideoCallRepeatRole.ocr;
      case 'FACE':
        return VideoCallRepeatRole.face;
      case 'NFC':
        return VideoCallRepeatRole.nfc;
      case 'HOLOGRAM':
        return VideoCallRepeatRole.hologram;
      default:
        return null;
    }
  }
}

/// How an in-call repeat ended.
enum VideoCallRepeatOutcome {
  completed,
  cancelled,
  failed;

  static VideoCallRepeatOutcome? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return VideoCallRepeatOutcome.completed;
      case 'CANCELLED':
        return VideoCallRepeatOutcome.cancelled;
      case 'FAILED':
        return VideoCallRepeatOutcome.failed;
      default:
        return null;
    }
  }
}

/// Emitted once per in-call repeat that started, whatever ended it. Prefer it over the
/// repeat-result callback, which does not fire on a cancel and carries nothing for OCR. On a
/// completed repeat the result callback arrives first.
class VideoCallRepeatEndedEvent {
  /// `null` when the SDK named a role this plugin does not know.
  final VideoCallRepeatRole? role;
  final VideoCallRepeatOutcome? outcome;

  /// Optional detail the SDK attaches, typically only on a failure.
  final String? reason;

  const VideoCallRepeatEndedEvent({this.role, this.outcome, this.reason});

  factory VideoCallRepeatEndedEvent.fromMap(Map<String, dynamic> map) {
    return VideoCallRepeatEndedEvent(
      role: VideoCallRepeatRole.fromString(map['role'] as String?),
      outcome: VideoCallRepeatOutcome.fromString(map['outcome'] as String?),
      reason: map['reason'] as String?,
    );
  }
}

/// Document the in-call OCR step captures. iOS only.
enum VideoCallOCRDocumentType {
  idCard('ID_CARD'),
  passport('PASSPORT'),
  driveLicence('DRIVE_LICENCE');

  final String value;
  const VideoCallOCRDocumentType(this.value);
}

/// Which side(s) the in-call OCR step captures. iOS only.
enum VideoCallOCRDocumentSide {
  bothSides('bothSides'),
  frontSide('frontSide'),
  backSide('backSide');

  final String value;
  const VideoCallOCRDocumentSide(this.value);
}

/// What a face or selfie step is processed as. iOS only.
enum VideoCallFaceMethod {
  registration('registration'),
  authentication('authentication'),
  imageUpload('imageUpload'),
  selfie('selfie'),
  identification('identification');

  final String value;
  const VideoCallFaceMethod(this.value);
}

/// Liveness run with the in-call face step. iOS only.
enum VideoCallFaceLivenessMode {
  passive('passive'),
  active('active'),
  hybrid('hybrid');

  final String value;
  const VideoCallFaceLivenessMode(this.value);
}

/// Chip anti-clone checks for the in-call NFC step. iOS only.
enum VideoCallNFCChipAnticloneMode {
  none('none'),
  auto('auto'),
  requireCA('requireCA'),
  requireAA('requireAA');

  final String value;
  const VideoCallNFCChipAnticloneMode(this.value);
}

/// Per-session configuration of the in-call LiveKYC steps, **iOS only**.
///
/// Its presence is the switch: passing it enables LiveKYC, omitting it runs a plain call. Read
/// once when the call starts and fixed for the session. Every field is optional and omitting
/// one keeps the SDK's own default; the values are the SDK's own spellings, untranslated.
class VideoCallLiveKYCOptions {
  final VideoCallObservationMode? observationMode;

  /// Your own identifier for the customer. Required for face registration and authentication,
  /// and for active or hybrid liveness. Falls back to the credentials' `userID` when omitted.
  final String? userID;

  /// Required for face identification.
  final String? listName;

  final VideoCallOCRDocumentType? ocrDocumentType;

  /// Issuing country as an ISO code such as `TUR` or `DEU`. The OCR step does not run without
  /// a country and the SDK's default is Turkey, so set this unless your documents are Turkish.
  final String? ocrCountry;
  final VideoCallOCRDocumentSide? ocrDocumentSide;
  final bool? ocrManualCapture;
  final bool? ocrDocumentLivenessEnabled;

  final VideoCallFaceMethod? faceMethod;
  final VideoCallFaceMethod? selfieOperation;
  final VideoCallFaceLivenessMode? faceLivenessMode;

  final VideoCallNFCChipAnticloneMode? nfcChipAnticloneMode;
  final bool? nfcIsPassiveAuthenticationEnabled;

  /// Seconds before the chip read times out.
  final double? nfcRequestTimeout;
  final bool? nfcIsFastModeEnabled;

  /// `.strings` table for the NFC step's text.
  final String? nfcTableName;

  final double? hologramNoFlashDuration;
  final double? hologramFlashDuration;
  final double? hologramTotalDuration;
  final double? hologramBitrate;
  final double? hologramRequestTimeout;

  /// Verbosity of each step's SDK logging. The SDK's defaults are `warning` for OCR, hologram and
  /// face, and `info` for NFC.
  final VideoCallLogLevel? ocrLogLevel;
  final VideoCallLogLevel? hologramLogLevel;
  final VideoCallLogLevel? faceLogLevel;
  final VideoCallLogLevel? nfcLogLevel;

  const VideoCallLiveKYCOptions({
    this.observationMode,
    this.userID,
    this.listName,
    this.ocrDocumentType,
    this.ocrCountry,
    this.ocrDocumentSide,
    this.ocrManualCapture,
    this.ocrDocumentLivenessEnabled,
    this.faceMethod,
    this.selfieOperation,
    this.faceLivenessMode,
    this.nfcChipAnticloneMode,
    this.nfcIsPassiveAuthenticationEnabled,
    this.nfcRequestTimeout,
    this.nfcIsFastModeEnabled,
    this.nfcTableName,
    this.hologramNoFlashDuration,
    this.hologramFlashDuration,
    this.hologramTotalDuration,
    this.hologramBitrate,
    this.hologramRequestTimeout,
    this.ocrLogLevel,
    this.hologramLogLevel,
    this.faceLogLevel,
    this.nfcLogLevel,
  });

  Map<String, dynamic> toMap() => {
        if (observationMode != null) 'observationMode': observationMode!.value,
        if (userID != null) 'userID': userID,
        if (listName != null) 'listName': listName,
        if (ocrDocumentType != null) 'ocrDocumentType': ocrDocumentType!.value,
        if (ocrCountry != null) 'ocrCountry': ocrCountry,
        if (ocrDocumentSide != null) 'ocrDocumentSide': ocrDocumentSide!.value,
        if (ocrManualCapture != null) 'ocrManualCapture': ocrManualCapture,
        if (ocrDocumentLivenessEnabled != null)
          'ocrDocumentLivenessEnabled': ocrDocumentLivenessEnabled,
        if (faceMethod != null) 'faceMethod': faceMethod!.value,
        if (selfieOperation != null) 'selfieOperation': selfieOperation!.value,
        if (faceLivenessMode != null) 'faceLivenessMode': faceLivenessMode!.value,
        if (nfcChipAnticloneMode != null)
          'nfcChipAnticloneMode': nfcChipAnticloneMode!.value,
        if (nfcIsPassiveAuthenticationEnabled != null)
          'nfcIsPassiveAuthenticationEnabled': nfcIsPassiveAuthenticationEnabled,
        if (nfcRequestTimeout != null) 'nfcRequestTimeout': nfcRequestTimeout,
        if (nfcIsFastModeEnabled != null)
          'nfcIsFastModeEnabled': nfcIsFastModeEnabled,
        if (nfcTableName != null) 'nfcTableName': nfcTableName,
        if (hologramNoFlashDuration != null)
          'hologramNoFlashDuration': hologramNoFlashDuration,
        if (hologramFlashDuration != null)
          'hologramFlashDuration': hologramFlashDuration,
        if (hologramTotalDuration != null)
          'hologramTotalDuration': hologramTotalDuration,
        if (hologramBitrate != null) 'hologramBitrate': hologramBitrate,
        if (hologramRequestTimeout != null)
          'hologramRequestTimeout': hologramRequestTimeout,
        if (ocrLogLevel != null) 'ocrLogLevel': ocrLogLevel!.value,
        if (hologramLogLevel != null) 'hologramLogLevel': hologramLogLevel!.value,
        if (faceLogLevel != null) 'faceLogLevel': faceLogLevel!.value,
        if (nfcLogLevel != null) 'nfcLogLevel': nfcLogLevel!.value,
      };
}
