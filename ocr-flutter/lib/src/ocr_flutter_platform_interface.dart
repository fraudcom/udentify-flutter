import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../ocr_flutter_method_channel.dart';
import 'models/ocr_models.dart';
import 'types/ocr_types.dart';
import 'types/hologram_types.dart';
import 'types/ui_types.dart';

abstract class OcrFlutterPlatform extends PlatformInterface {
  OcrFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static OcrFlutterPlatform _instance = MethodChannelOcrFlutter();

  static OcrFlutterPlatform get instance => _instance;

  static set instance(OcrFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> startOCRCamera(OCRCameraParams params) {
    throw UnimplementedError('startOCRCamera() has not been implemented.');
  }

  Future<OCRResponse> performOCR(OCRProcessParams params) {
    throw UnimplementedError('performOCR() has not been implemented.');
  }

  Future<bool> startHologramCamera(HologramParams params) {
    throw UnimplementedError('startHologramCamera() has not been implemented.');
  }

  Future<HologramResponse> uploadHologramVideo(
      HologramParams params, List<String> videoUrls) {
    throw UnimplementedError('uploadHologramVideo() has not been implemented.');
  }

  Future<OCRAndDocumentLivenessResponse> performDocumentLiveness(
      DocumentLivenessParams params) {
    throw UnimplementedError(
        'performDocumentLiveness() has not been implemented.');
  }

  Future<OCRAndDocumentLivenessResponse> performOCRAndDocumentLiveness(
      OCRAndDocumentLivenessParams params) {
    throw UnimplementedError(
        'performOCRAndDocumentLiveness() has not been implemented.');
  }

  Future<void> setOCRUIConfig(OCRUIConfig config) {
    throw UnimplementedError('setOCRUIConfig() has not been implemented.');
  }

  Future<void> dismissOCRCamera() {
    throw UnimplementedError('dismissOCRCamera() has not been implemented.');
  }

  Future<void> dismissHologramCamera() {
    throw UnimplementedError(
        'dismissHologramCamera() has not been implemented.');
  }
}
