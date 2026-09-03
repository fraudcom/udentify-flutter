import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mrz_flutter_platform_interface.dart';
import 'mrz_flutter.dart';

/// An implementation of [MrzFlutterPlatform] that uses method channels.
class MethodChannelMrzFlutter extends MrzFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mrz_flutter');

  Function(double progress)? _onProgress;

  MethodChannelMrzFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onProgress':
        final progress = (call.arguments as int).toDouble();
        debugPrint('MRZ Progress: $progress%');
        _onProgress?.call(progress);
        break;
      default:
        debugPrint('Unknown method call: ${call.method}');
    }
  }

  @override
  Future<bool> checkPermissions() async {
    final result = await methodChannel.invokeMethod<bool>('checkPermissions');
    return result ?? false;
  }

  @override
  Future<String> requestPermissions() async {
    final result =
        await methodChannel.invokeMethod<String>('requestPermissions');
    return result ?? 'denied';
  }

  @override
  Future<MrzResult> startMrzCamera({
    MrzReaderMode mode = MrzReaderMode.accurate,
    Function(double progress)? onProgress,
  }) async {
    try {
      _onProgress = onProgress;

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'startMrzCamera',
        {
          'mode': mode.name,
        },
      );

      if (result == null) {
        return MrzResult(
          success: false,
          errorMessage: 'No MRZ result received',
        );
      }

      return MrzResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      return MrzResult(
        success: false,
        errorMessage: 'Failed to start MRZ camera: ${e.message}',
      );
    } finally {
      _onProgress = null;
    }
  }

  @override
  Future<MrzResult> processMrzImage({
    required String imageBase64,
    MrzReaderMode mode = MrzReaderMode.accurate,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'processMrzImage',
        {
          'imageBase64': imageBase64,
          'mode': mode.name,
        },
      );

      if (result == null) {
        return MrzResult(
          success: false,
          errorMessage: 'No MRZ result received',
        );
      }

      return MrzResult.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      return MrzResult(
        success: false,
        errorMessage: 'Failed to process MRZ image: ${e.message}',
      );
    }
  }

  @override
  Future<void> cancelMrzScanning() async {
    try {
      await methodChannel.invokeMethod('cancelMrzScanning');
    } on PlatformException catch (e) {
      debugPrint('Failed to cancel MRZ scanning: ${e.message}');
    }
  }
}
