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
  static VideoCallFlutterPlatform get _platform =>
      VideoCallFlutterPlatform.instance;

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

  /// Toggle camera on/off
  static Future<bool> toggleCamera() {
    return _platform.toggleCamera();
  }

  /// Switch between front and back camera
  static Future<bool> switchCamera() {
    return _platform.switchCamera();
  }

  /// Toggle microphone on/off
  static Future<bool> toggleMicrophone() {
    return _platform.toggleMicrophone();
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
}
