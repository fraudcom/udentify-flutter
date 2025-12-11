import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'udentify_core_platform_interface.dart';

/// An implementation of [UdentifyCorePlatform] that uses method channels.
class MethodChannelUdentifyCore extends UdentifyCorePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('udentify_core_flutter');

  @override
  Future<bool> loadCertificateFromAssets(
    String certificateName,
    String extension,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'loadCertificateFromAssets',
        {
          'certificateName': certificateName,
          'extension': extension,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to load certificate from assets: ${e.message}');
    }
  }

  @override
  Future<bool> setSSLCertificateBase64(String certificateBase64) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'setSSLCertificateBase64',
        {
          'certificateBase64': certificateBase64,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to set SSL certificate: ${e.message}');
    }
  }

  @override
  Future<bool> removeSSLCertificate() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'removeSSLCertificate',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to remove SSL certificate: ${e.message}');
    }
  }

  @override
  Future<String?> getSSLCertificateBase64() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'getSSLCertificateBase64',
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to get SSL certificate: ${e.message}');
    }
  }

  @override
  Future<bool> isSSLPinningEnabled() async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'isSSLPinningEnabled',
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('Failed to check SSL pinning status: ${e.message}');
    }
  }

  @override
  Future<void> instantiateServerBasedLocalization(
    String language,
    String serverUrl,
    String transactionId,
    double requestTimeout,
  ) async {
    try {
      await methodChannel.invokeMethod<void>(
        'instantiateServerBasedLocalization',
        {
          'language': language,
          'serverUrl': serverUrl,
          'transactionId': transactionId,
          'requestTimeout': requestTimeout,
        },
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to instantiate server-based localization: ${e.message}');
    }
  }

  @override
  Future<Map<String, String>?> getLocalizationMap() async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'getLocalizationMap',
      );
      if (result == null) {
        return null;
      }
      return result.map((key, value) => MapEntry(key.toString(), value.toString()));
    } on PlatformException catch (e) {
      throw Exception('Failed to get localization map: ${e.message}');
    }
  }

  @override
  Future<void> clearLocalizationCache(String language) async {
    try {
      await methodChannel.invokeMethod<void>(
        'clearLocalizationCache',
        {
          'language': language,
        },
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to clear localization cache: ${e.message}');
    }
  }

  @override
  Future<String?> mapSystemLanguageToEnum() async {
    try {
      final result = await methodChannel.invokeMethod<String>(
        'mapSystemLanguageToEnum',
      );
      return result;
    } on PlatformException catch (e) {
      throw Exception('Failed to map system language: ${e.message}');
    }
  }
}

