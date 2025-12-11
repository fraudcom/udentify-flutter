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
  Future<bool> toggleCamera() async {
    try {
      final bool? result = await methodChannel.invokeMethod<bool>(
        'toggleCamera',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error toggling camera: $e');
      return false;
    }
  }

  @override
  Future<bool> switchCamera() async {
    try {
      final bool? result = await methodChannel.invokeMethod<bool>(
        'switchCamera',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error switching camera: $e');
      return false;
    }
  }

  @override
  Future<bool> toggleMicrophone() async {
    try {
      final bool? result = await methodChannel.invokeMethod<bool>(
        'toggleMicrophone',
      );
      return result ?? false;
    } catch (e) {
      debugPrint('Error toggling microphone: $e');
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

  /// Set status change callback
  void setOnStatusChanged(Function(VideoCallStatus status) callback) {
    _onStatusChanged = callback;
  }

  /// Set error callback
  void setOnError(Function(VideoCallError error) callback) {
    _onError = callback;
  }
}
