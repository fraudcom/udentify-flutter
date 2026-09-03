import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nfc_flutter_method_channel.dart';
import 'nfc_flutter.dart';

abstract class NfcFlutterPlatform extends PlatformInterface {
  /// Constructs a NfcFlutterPlatform.
  NfcFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static NfcFlutterPlatform _instance = MethodChannelNfcFlutter();

  /// The default instance of [NfcFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelNfcFlutter].
  static NfcFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NfcFlutterPlatform] when
  /// they register themselves.
  static set instance(NfcFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Read passport data using NFC
  Future<NfcPassport?> readPassport(
    NfcPassportParams params, {
    Function(double progress)? onProgress,
  }) {
    throw UnimplementedError('readPassport() has not been implemented.');
  }

  /// Cancel ongoing NFC reading operation
  Future<void> cancelReading() {
    throw UnimplementedError('cancelReading() has not been implemented.');
  }

  /// Get NFC antenna location on the device
  Future<NfcLocation> getNfcLocation(String serverURL) {
    throw UnimplementedError('getNfcLocation() has not been implemented.');
  }

  Future<String> getNfcLocationRaw(String serverURL) {
    throw UnimplementedError('getNfcLocationRaw() has not been implemented.');
  }

  /// Check current permissions status
  Future<PermissionStatus> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Request necessary permissions for NFC functionality
  Future<String> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }
}
