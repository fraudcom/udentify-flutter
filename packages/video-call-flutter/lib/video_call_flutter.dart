library video_call_flutter;

export 'src/video_call_flutter_platform_interface.dart';
export 'src/video_call_flutter_method_channel.dart';
export 'src/models/video_call_models.dart';

import 'src/video_call_flutter_platform_interface.dart';
import 'src/video_call_flutter_method_channel.dart';
import 'src/models/video_call_models.dart';

/// The main Video Call Flutter plugin class
class VideoCallFlutter {
  /// Returns the platform-specific implementation
  static VideoCallFlutterPlatform get _platform => VideoCallFlutterPlatform.instance;

  /// Check current permissions status
  static Future<VideoCallPermissionStatus> checkPermissions() {
    return _platform.checkPermissions();
  }

  /// Request necessary permissions for video call functionality
  static Future<String> requestPermissions() {
    return _platform.requestPermissions();
  }

  /// Start video call with given credentials
  static Future<VideoCallResult> startVideoCall(
      VideoCallCredentials credentials) {
    return _platform.startVideoCall(credentials);
  }

  /// End ongoing video call
  static Future<VideoCallResult> endVideoCall() {
    return _platform.endVideoCall();
  }

  /// Get current video call status
  static Future<VideoCallStatus> getVideoCallStatus() {
    return _platform.getVideoCallStatus();
  }

  /// Set video call UI configuration
  static Future<void> setVideoCallConfig(VideoCallConfig config) {
    return _platform.setVideoCallConfig(config);
  }

  /// Cancel the video call transaction on the server and dismiss the call
  static Future<VideoCallResult> cancelVideoCall() {
    return _platform.cancelVideoCall();
  }

  /// Ask the SDK to mute (`false`) or unmute (`true`) the microphone.
  /// Returns whether the request was accepted; listen to
  /// [setOnMicrophoneStateChanged] for the real outcome.
  static Future<bool> setMicrophoneEnabled(bool enabled) {
    return _platform.setMicrophoneEnabled(enabled);
  }

  /// Whether the microphone is currently enabled
  static Future<bool> isMicrophoneEnabled() {
    return _platform.isMicrophoneEnabled();
  }

  /// Dismiss video call UI
  static Future<void> dismissVideoCall() {
    return _platform.dismissVideoCall();
  }

  /// Set status change callback
  static void setOnStatusChanged(Function(VideoCallStatus status) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnStatusChanged(callback);
    }
  }

  /// Set error callback
  static void setOnError(Function(VideoCallError error) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnError(callback);
    }
  }

  /// Set user state change callback
  static void setOnUserStateChanged(Function(VideoCallStatus state) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter)
          .setOnUserStateChanged(callback);
    }
  }

  /// Set participant state change callback
  static void setOnParticipantStateChanged(
    Function(VideoCallParticipantState state) callback,
  ) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter)
          .setOnParticipantStateChanged(callback);
    }
  }

  /// Set microphone state callback (any source: in-call button, agent signal,
  /// automatic SDK mutes, or [setMicrophoneEnabled])
  static void setOnMicrophoneStateChanged(Function(bool enabled) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter)
          .setOnMicrophoneStateChanged(callback);
    }
  }

  /// Set device phone call state callback
  static void setOnPhoneCallStateChanged(
    Function(VideoCallPhoneCallState state) callback,
  ) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter)
          .setOnPhoneCallStateChanged(callback);
    }
  }

  /// Set screen locked callback
  static void setOnScreenLocked(Function() callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnScreenLocked(callback);
    }
  }

  /// Set screen unlocked callback
  static void setOnScreenUnlocked(Function() callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnScreenUnlocked(callback);
    }
  }

  /// An in-call LiveKYC repeat is about to take over the call screen
  static void setOnRepeatStarted(Function(VideoCallRepeatRole role) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnRepeatStarted(callback);
    }
  }

  /// An in-call repeat produced a result (never on cancel or failure)
  static void setOnRepeatResult(Function(VideoCallRepeatRole role) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnRepeatResult(callback);
    }
  }

  /// An in-call repeat ended, whatever ended it
  static void setOnRepeatEnded(
    Function(VideoCallRepeatEndedEvent event) callback,
  ) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnRepeatEnded(callback);
    }
  }

  /// Chip-read progress (`0`-`99`) during an in-call NFC repeat; iOS only
  static void setOnNfcProgress(Function(int percent) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnNfcProgress(callback);
    }
  }

  /// The call ended. On Android `success` is `false` when it ended after an SDK error; on iOS this fires
  /// only when the agent ends the session, with `success` `true`. Use [setOnVideoCallDismissed] on iOS for
  /// "the call screen is gone".
  static void setOnVideoCallEnded(Function(bool success) callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnVideoCallEnded(callback);
    }
  }

  /// The call screen was dismissed without a definitive result (iOS)
  static void setOnVideoCallDismissed(Function() callback) {
    if (_platform is MethodChannelVideoCallFlutter) {
      (_platform as MethodChannelVideoCallFlutter).setOnVideoCallDismissed(callback);
    }
  }
}
