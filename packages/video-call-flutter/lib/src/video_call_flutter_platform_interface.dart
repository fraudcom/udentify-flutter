import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_call_flutter_method_channel.dart';
import 'models/video_call_models.dart';

abstract class VideoCallFlutterPlatform extends PlatformInterface {
  /// Constructs a VideoCallFlutterPlatform.
  VideoCallFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoCallFlutterPlatform _instance = MethodChannelVideoCallFlutter();

  /// The default instance of [VideoCallFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoCallFlutter].
  static VideoCallFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoCallFlutterPlatform] when
  /// they register themselves.
  static set instance(VideoCallFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check current permissions status
  Future<VideoCallPermissionStatus> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Request necessary permissions for video call functionality
  Future<String> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Start video call with given credentials
  Future<VideoCallResult> startVideoCall(VideoCallCredentials credentials) {
    throw UnimplementedError('startVideoCall() has not been implemented.');
  }

  /// End ongoing video call
  Future<VideoCallResult> endVideoCall() {
    throw UnimplementedError('endVideoCall() has not been implemented.');
  }

  /// Get current video call status
  Future<VideoCallStatus> getVideoCallStatus() {
    throw UnimplementedError('getVideoCallStatus() has not been implemented.');
  }

  /// Set video call UI configuration
  Future<void> setVideoCallConfig(VideoCallConfig config) {
    throw UnimplementedError('setVideoCallConfig() has not been implemented.');
  }

  /// Cancel the video call transaction on the server, then dismiss the call.
  ///
  /// The cancel is what ends the agent's session; leaving the media room alone
  /// looks like a network blip from their side. Fails with a
  /// `NO_ACTIVE_CALL` error result when no call is running.
  Future<VideoCallResult> cancelVideoCall() {
    throw UnimplementedError('cancelVideoCall() has not been implemented.');
  }

  /// Ask the SDK to mute or unmute the microphone.
  ///
  /// Returns whether the request was accepted (`false` when there is no
  /// connected call). Accepted is not applied: listen to the microphone state
  /// callback for the real outcome.
  Future<bool> setMicrophoneEnabled(bool enabled) {
    throw UnimplementedError('setMicrophoneEnabled() has not been implemented.');
  }

  /// Whether the microphone is currently enabled, as reported by the SDK.
  Future<bool> isMicrophoneEnabled() {
    throw UnimplementedError('isMicrophoneEnabled() has not been implemented.');
  }

  /// Dismiss video call UI
  Future<void> dismissVideoCall() {
    throw UnimplementedError('dismissVideoCall() has not been implemented.');
  }
}
