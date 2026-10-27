import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_call_flutter_platform_interface.dart';
import 'models/video_call_models.dart';

/// An implementation of [VideoCallFlutterPlatform] that uses method channels.
class MethodChannelVideoCallFlutter extends VideoCallFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_call_flutter');

  Function(VideoCallStatus status)? _onStatusChanged;
  Function(VideoCallError error)? _onError;
  Function(VideoCallStatus state)? _onUserStateChanged;
  Function(VideoCallParticipantState state)? _onParticipantStateChanged;
  Function(bool enabled)? _onMicrophoneStateChanged;
  Function(VideoCallPhoneCallState state)? _onPhoneCallStateChanged;
  Function()? _onScreenLocked;
  Function()? _onScreenUnlocked;
  Function(VideoCallRepeatRole role)? _onRepeatStarted;
  Function(VideoCallRepeatRole role)? _onRepeatResult;
  Function(VideoCallRepeatEndedEvent event)? _onRepeatEnded;
  Function(int percent)? _onNfcProgress;
  Function(bool success)? _onVideoCallEnded;
  Function()? _onVideoCallDismissed;

  MethodChannelVideoCallFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onStatusChanged':
        final statusString = call.arguments as String;
        final status = VideoCallStatus.fromString(statusString);
        debugPrint('Video Call Status Changed: $status');
        _onStatusChanged?.call(status);
        break;
      case 'onError':
        final errorMap = Map<String, dynamic>.from(call.arguments);
        final error = VideoCallError.fromMap(errorMap);
        debugPrint('Video Call Error: ${error.message}');
        _onError?.call(error);
        break;
      case 'onUserStateChanged':
        final userStateMap = Map<String, dynamic>.from(call.arguments);
        final userState = VideoCallStatus.fromString(
          userStateMap['state'] ?? 'unknown',
        );
        debugPrint('Video Call User State Changed: $userState');
        _onUserStateChanged?.call(userState);
        break;
      case 'onParticipantStateChanged':
        final participantStateMap = Map<String, dynamic>.from(call.arguments);
        final participantState = VideoCallParticipantState.fromMap(
          participantStateMap,
        );
        debugPrint(
          'Video Call Participant State Changed: ${participantState.state}',
        );
        _onParticipantStateChanged?.call(participantState);
        break;
      case 'onMicrophoneStateChanged':
        final micMap = Map<String, dynamic>.from(call.arguments);
        _onMicrophoneStateChanged?.call(micMap['enabled'] == true);
        break;
      case 'onPhoneCallStateChanged':
        final phoneMap = Map<String, dynamic>.from(call.arguments);
        _onPhoneCallStateChanged?.call(
          VideoCallPhoneCallState.fromString(phoneMap['state'] ?? 'ended'),
        );
        break;
      case 'onRepeatStarted':
      case 'onRepeatResult':
        final role = VideoCallRepeatRole.fromString(
          Map<String, dynamic>.from(call.arguments)['role'] as String?,
        );
        if (role != null) {
          (call.method == 'onRepeatStarted' ? _onRepeatStarted : _onRepeatResult)
              ?.call(role);
        }
        break;
      case 'onRepeatEnded':
        _onRepeatEnded?.call(
          VideoCallRepeatEndedEvent.fromMap(
            Map<String, dynamic>.from(call.arguments),
          ),
        );
        break;
      case 'onNfcProgress':
        _onNfcProgress?.call(
          (Map<String, dynamic>.from(call.arguments)['percent'] as num?)?.toInt() ?? 0,
        );
        break;
      case 'onVideoCallEnded':
        _onVideoCallEnded?.call(
          (call.arguments is Map ? Map<String, dynamic>.from(call.arguments)['success'] : null) == true,
        );
        break;
      case 'onVideoCallDismissed':
        _onVideoCallDismissed?.call();
        break;
      case 'onScreenLocked':
        _onScreenLocked?.call();
        break;
      case 'onScreenUnlocked':
        _onScreenUnlocked?.call();
        break;
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }

  @override
  Future<VideoCallPermissionStatus> checkPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'checkPermissions',
      );

      if (result != null) {
        return VideoCallPermissionStatus.fromMap(
          Map<String, dynamic>.from(result),
        );
      }
      return const VideoCallPermissionStatus(
        hasCameraPermission: false,
        hasPhoneStatePermission: false,
        hasInternetPermission: false,
        hasRecordAudioPermission: false,
      );
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return const VideoCallPermissionStatus(
        hasCameraPermission: false,
        hasPhoneStatePermission: false,
        hasInternetPermission: false,
        hasRecordAudioPermission: false,
      );
    }
  }

  @override
  Future<String> requestPermissions() async {
    try {
      final String? result = await methodChannel.invokeMethod<String>(
        'requestPermissions',
      );
      return result ?? 'error';
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return 'error';
    }
  }

  @override
  Future<VideoCallResult> startVideoCall(
    VideoCallCredentials credentials,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'startVideoCall',
        credentials.toMap(),
      );

      if (result != null) {
        return VideoCallResult.fromMap(Map<String, dynamic>.from(result));
      }
      return const VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.unknown,
          message: 'No result received from native platform',
        ),
      );
    } on PlatformException catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.fromString(e.code),
          code: e.code,
          message: e.message ?? 'Failed to start video call',
          details: e.details?.toString(),
        ),
      );
    } catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.unknown,
          message: 'Failed to start video call: $e',
        ),
      );
    }
  }

  @override
  Future<VideoCallResult> endVideoCall() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'endVideoCall',
      );

      if (result != null) {
        return VideoCallResult.fromMap(Map<String, dynamic>.from(result));
      }
      return const VideoCallResult(success: true);
    } on PlatformException catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.fromString(e.code),
          code: e.code,
          message: e.message ?? 'Failed to end video call',
          details: e.details?.toString(),
        ),
      );
    } catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.unknown,
          message: 'Failed to end video call: $e',
        ),
      );
    }
  }

  @override
  Future<VideoCallStatus> getVideoCallStatus() async {
    try {
      final String? result = await methodChannel.invokeMethod<String>(
        'getVideoCallStatus',
      );
      return VideoCallStatus.fromString(result ?? 'idle');
    } catch (e) {
      debugPrint('Error getting video call status: $e');
      return VideoCallStatus.idle;
    }
  }

  @override
  Future<void> setVideoCallConfig(VideoCallConfig config) async {
    try {
      await methodChannel.invokeMethod<void>(
        'setVideoCallConfig',
        config.toMap(),
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to set video call config: ${e.message}');
    }
  }

  @override
  Future<VideoCallResult> cancelVideoCall() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'cancelVideoCall',
      );
      if (result != null) {
        return VideoCallResult.fromMap(Map<String, dynamic>.from(result));
      }
      return const VideoCallResult(success: false);
    } on PlatformException catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.fromString(e.code),
          code: e.code,
          message: e.message ?? 'Failed to cancel video call',
          details: e.details?.toString(),
        ),
      );
    } catch (e) {
      return VideoCallResult(
        success: false,
        error: VideoCallError(
          type: VideoCallErrorType.unknown,
          message: 'Failed to cancel video call: $e',
        ),
      );
    }
  }

  @override
  Future<bool> setMicrophoneEnabled(bool enabled) async {
    try {
      final bool? result = await methodChannel.invokeMethod<bool>(
        'setMicrophoneEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error setting microphone state: $e');
      return false;
    }
  }

  @override
  Future<bool> isMicrophoneEnabled() async {
    try {
      final bool? result = await methodChannel.invokeMethod<bool>(
        'isMicrophoneEnabled',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error reading microphone state: $e');
      return false;
    }
  }

  @override
  Future<void> dismissVideoCall() async {
    try {
      await methodChannel.invokeMethod<void>('dismissVideoCall');
    } catch (e) {
      debugPrint('Error dismissing video call: $e');
    }
  }

  /// Set microphone state callback. Fires for every change the SDK makes, not
  /// only ones requested through [setMicrophoneEnabled]: the in-call button,
  /// the agent's mute signal, and the SDK's automatic mutes.
  void setOnMicrophoneStateChanged(Function(bool enabled) callback) {
    _onMicrophoneStateChanged = callback;
  }

  /// Set device phone call state callback
  void setOnPhoneCallStateChanged(
    Function(VideoCallPhoneCallState state) callback,
  ) {
    _onPhoneCallStateChanged = callback;
  }

  /// An in-call repeat is about to take over the call screen. Not fired when the repeat is
  /// refused, which is the default until the matching capture package is opted in.
  void setOnRepeatStarted(Function(VideoCallRepeatRole role) callback) {
    _onRepeatStarted = callback;
  }

  /// An in-call repeat produced a result. Never fires on cancel or failure, and carries nothing
  /// for OCR; prefer [setOnRepeatEnded].
  void setOnRepeatResult(Function(VideoCallRepeatRole role) callback) {
    _onRepeatResult = callback;
  }

  /// An in-call repeat ended, whatever ended it.
  void setOnRepeatEnded(Function(VideoCallRepeatEndedEvent event) callback) {
    _onRepeatEnded = callback;
  }

  /// Chip-read progress during an in-call NFC repeat, `0` to `99` (iOS only; Android's SDK
  /// reports none). A finished read arrives as a completed NFC repeat, never as 100.
  void setOnNfcProgress(Function(int percent) callback) {
    _onNfcProgress = callback;
  }

  /// The call ended. On Android `success` is `false` when it ended after an SDK error and the event fires
  /// alongside the terminal `completed` / `failed` status; on iOS it fires only when the agent ends the
  /// session, with `success` `true`.
  void setOnVideoCallEnded(Function(bool success) callback) {
    _onVideoCallEnded = callback;
  }

  /// The call screen was dismissed without a definitive result (iOS).
  void setOnVideoCallDismissed(Function() callback) {
    _onVideoCallDismissed = callback;
  }

  /// Set screen locked callback
  void setOnScreenLocked(Function() callback) {
    _onScreenLocked = callback;
  }

  /// Set screen unlocked callback
  void setOnScreenUnlocked(Function() callback) {
    _onScreenUnlocked = callback;
  }

  /// Set status change callback
  void setOnStatusChanged(Function(VideoCallStatus status) callback) {
    _onStatusChanged = callback;
  }

  /// Set error callback
  void setOnError(Function(VideoCallError error) callback) {
    _onError = callback;
  }

  /// Set user state change callback
  void setOnUserStateChanged(Function(VideoCallStatus state) callback) {
    _onUserStateChanged = callback;
  }

  /// Set participant state change callback
  void setOnParticipantStateChanged(
    Function(VideoCallParticipantState state) callback,
  ) {
    _onParticipantStateChanged = callback;
  }
}
