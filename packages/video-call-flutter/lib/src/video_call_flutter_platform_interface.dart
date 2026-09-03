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

  /// Toggle camera on/off
  Future<bool> toggleCamera() {
    throw UnimplementedError('toggleCamera() has not been implemented.');
  }

  /// Switch between front and back camera
  Future<bool> switchCamera() {
    throw UnimplementedError('switchCamera() has not been implemented.');
  }

  /// Toggle microphone on/off
  Future<bool> toggleMicrophone() {
    throw UnimplementedError('toggleMicrophone() has not been implemented.');
  }

  /// Dismiss video call UI
  Future<void> dismissVideoCall() {
    throw UnimplementedError('dismissVideoCall() has not been implemented.');
  }
}
