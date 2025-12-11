import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mrz_flutter_method_channel.dart';
import 'mrz_flutter.dart';

abstract class MrzFlutterPlatform extends PlatformInterface {
  /// Constructs a MrzFlutterPlatform.
  MrzFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static MrzFlutterPlatform _instance = MethodChannelMrzFlutter();

  /// The default instance of [MrzFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelMrzFlutter].
  static MrzFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MrzFlutterPlatform] when
  /// they register themselves.
  static set instance(MrzFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  Future<String> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  Future<MrzResult> startMrzCamera({
    MrzReaderMode mode = MrzReaderMode.accurate,
    Function(double progress)? onProgress,
  }) {
    throw UnimplementedError('startMrzCamera() has not been implemented.');
  }

  Future<MrzResult> processMrzImage({
    required String imageBase64,
    MrzReaderMode mode = MrzReaderMode.accurate,
  }) {
    throw UnimplementedError('processMrzImage() has not been implemented.');
  }

  Future<void> cancelMrzScanning() {
    throw UnimplementedError('cancelMrzScanning() has not been implemented.');
  }
}
