library ocr_flutter;

export 'src/ocr_flutter_platform_interface.dart';
export 'ocr_flutter_method_channel.dart';

export 'src/constants/document_type.dart';
export 'src/constants/document_side.dart';
export 'src/constants/iqa_feedback.dart';

export 'src/types/ocr_types.dart';
export 'src/types/hologram_types.dart';
export 'src/types/ui_types.dart';
export 'src/types/iqa_types.dart';

export 'src/models/ocr_models.dart';

export 'src/events/iqa_events.dart';

import 'src/ocr_flutter_platform_interface.dart';
import 'ocr_flutter_method_channel.dart';
import 'src/models/ocr_models.dart';
import 'src/types/ocr_types.dart';
import 'src/types/hologram_types.dart';
import 'src/types/ui_types.dart';

/// The main OCR Flutter plugin class
class OcrFlutter {
  static OcrFlutterPlatform get _platform => OcrFlutterPlatform.instance;

  static Future<bool> startOCRCamera(OCRCameraParams params) {
    return _platform.startOCRCamera(params);
  }

  static Future<OCRResponse> performOCR(OCRProcessParams params) {
    return _platform.performOCR(params);
  }

  static Future<bool> startHologramCamera(HologramParams params) {
    return _platform.startHologramCamera(params);
  }

  static Future<HologramResponse> uploadHologramVideo(
      HologramParams params, List<String> videoUrls) {
    return _platform.uploadHologramVideo(params, videoUrls);
  }

  static Future<OCRAndDocumentLivenessResponse> performDocumentLiveness(
      DocumentLivenessParams params) {
    return _platform.performDocumentLiveness(params);
  }

  static Future<OCRAndDocumentLivenessResponse> performOCRAndDocumentLiveness(
      OCRAndDocumentLivenessParams params) {
    return _platform.performOCRAndDocumentLiveness(params);
  }

  static Future<void> setOCRUIConfig(OCRUIConfig config) {
    return _platform.setOCRUIConfig(config);
  }

  static Future<void> dismissOCRCamera() {
    return _platform.dismissOCRCamera();
  }

  static Future<void> dismissHologramCamera() {
    return _platform.dismissHologramCamera();
  }

  static void setOnOCRSuccessCallback(Function(OCRResponse) callback) {
    MethodChannelOcrFlutter.setOnOCRSuccessCallback(callback);
  }

  static void setOnOCRFailureCallback(Function(String) callback) {
    MethodChannelOcrFlutter.setOnOCRFailureCallback(callback);
  }

  static void setOnDocumentScanCallback(
      Function(String, String?, String?) callback) {
    MethodChannelOcrFlutter.setOnDocumentScanCallback(callback);
  }

  static void setOnBackButtonPressedCallback(Function() callback) {
    MethodChannelOcrFlutter.setOnBackButtonPressedCallback(callback);
  }

  static void setOnOCRAndDocumentLivenessResultCallback(
      Function(OCRAndDocumentLivenessResponse) callback) {
    MethodChannelOcrFlutter.setOnOCRAndDocumentLivenessResultCallback(callback);
  }

  static void setOnHologramVideoRecordedCallback(
      Function(List<String>) callback) {
    MethodChannelOcrFlutter.setOnHologramVideoRecordedCallback(callback);
  }

  static void setOnHologramFailureCallback(Function(String) callback) {
    MethodChannelOcrFlutter.setOnHologramFailureCallback(callback);
  }

  static void setOnHologramBackButtonPressedCallback(Function() callback) {
    MethodChannelOcrFlutter.setOnHologramBackButtonPressedCallback(callback);
  }

  static void clearOCRCallbacks() {
    MethodChannelOcrFlutter.clearAllCallbacks();
  }
}
