import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nfc_flutter_platform_interface.dart';
import 'nfc_flutter.dart';

/// An implementation of [NfcFlutterPlatform] that uses method channels.
class MethodChannelNfcFlutter extends NfcFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nfc_flutter');

  @override
  Future<NfcPassport?> readPassport(
    NfcPassportParams params, {
    Function(double progress)? onProgress,
  }) async {
    try {
      // Set up progress callback if provided
      if (onProgress != null) {
        methodChannel.setMethodCallHandler((call) async {
          if (call.method == 'onProgress') {
            final int progressInt = call.arguments as int;
            final double progress = progressInt.toDouble();
            debugPrint('Received progress: $progress');
            onProgress(progress);
          }
        });
      }

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'readPassport',
        params.toMap(),
      );

      if (result != null) {
        return NfcPassport.fromMap(Map<String, dynamic>.from(result));
      }
      return null;
    } catch (e) {
      debugPrint('Error reading passport: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelReading() async {
    try {
      await methodChannel.invokeMethod<void>('cancelReading');
    } catch (e) {
      debugPrint('Error canceling reading: $e');
      rethrow;
    }
  }

  @override
  Future<String> getNfcLocationRaw(String serverURL) async {
    try {
      final String? result = await methodChannel.invokeMethod<String>(
        'getNfcLocation',
        {'serverURL': serverURL},
      );
      return result ?? '{"success":false,"location":0,"message":"No response"}';
    } catch (e) {
      return '{"success":false,"location":0,"message":"Error: $e"}';
    }
  }

  @override
  Future<NfcLocation> getNfcLocation(String serverURL) async {
    try {
      final String? result = await methodChannel.invokeMethod<String>(
        'getNfcLocation',
        {'serverURL': serverURL},
      );
      
      // Try to parse as JSON first (new format), fallback to string (old format)
      if (result != null && result.startsWith('{')) {
        try {
          if (result.contains('"locationString":"')) {
            final locationMatch = RegExp(r'"locationString":"([^"]*)"').firstMatch(result);
            if (locationMatch != null) {
              final locationString = locationMatch.group(1) ?? 'unknown';
              return NfcLocation.fromString(locationString);
            }
          }
        } catch (e) {
          // Fall through to default parsing
        }
      }
      
      return NfcLocation.fromString(result ?? 'unknown');
    } catch (e) {
      return NfcLocation.unknown;
    }
  }

  @override
  Future<PermissionStatus> checkPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'checkPermissions',
      );

      if (result != null) {
        return PermissionStatus.fromMap(Map<String, dynamic>.from(result));
      }
      return const PermissionStatus(
        hasPhoneStatePermission: false,
        hasNfcPermission: false,
      );
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return const PermissionStatus(
        hasPhoneStatePermission: false,
        hasNfcPermission: false,
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
}
