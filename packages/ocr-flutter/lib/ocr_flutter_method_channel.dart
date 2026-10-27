import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'src/ocr_flutter_platform_interface.dart';
import 'src/models/ocr_models.dart';
import 'src/types/ocr_types.dart';
import 'src/types/hologram_types.dart';
import 'src/types/iqa_types.dart';
import 'src/types/ui_types.dart';
import 'src/types/repeat_types.dart';

/// An implementation of [OcrFlutterPlatform] that uses method channels.
class MethodChannelOcrFlutter extends OcrFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ocr_flutter');

  // Callbacks for OCR camera events - make them accessible from other classes
  static Function(OCRResponse)? onOCRSuccess;
  static Function(String)? onOCRFailure;
  static Function(OCRFailure)? onOCRError;
  static Function(String, String?, String?)? onDocumentScan;
  static Function()? onBackButtonPressed;
  static Function(OCRAndDocumentLivenessResponse)?
      onOCRAndDocumentLivenessResult;
  static Function(String)? onOCRAndDocumentLivenessFailure;
  static Function(OCRFailure)? onOCRAndDocumentLivenessError;

  // Hologram callback functions
  static Function(List<String>)? onHologramVideoRecorded;
  static Function(String)? onHologramFailure;
  static Function(OCRFailure)? onHologramError;
  static Function()? onHologramBackButtonPressed;

  // Directive callback functions
  static Function(String, double)? onOCRDirectiveChanged;
  static Function(String, double)? onHologramDirectiveChanged;

  // IQA callback function
  static Function(IQAResult)? onIQAResult;

  MethodChannelOcrFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOCRSuccess':
        if (onOCRSuccess != null && call.arguments != null) {
          try {
            // Deep convert Map<Object?, Object?> to Map<String, dynamic>
            final convertedArgs =
                _deepConvertMap(call.arguments as Map<Object?, Object?>);
            final ocrResponse = OCRResponse.fromMap(convertedArgs);
            onOCRSuccess!(ocrResponse);
          } catch (e) {
            debugPrint('Error parsing OCR success response: $e');
          }
        }
        break;
      case 'onOCRFailure':
        if ((onOCRFailure != null || onOCRError != null) && call.arguments != null) {
          final failure = OCRFailure.fromArguments(
              _deepConvertMap(call.arguments as Map<Object?, Object?>), 'Unknown OCR error');
          onOCRFailure?.call(failure.message);
          onOCRError?.call(failure);
        }
        break;
      case 'onDocumentScan':
        if (onDocumentScan != null && call.arguments != null) {
          final args = _deepConvertMap(call.arguments as Map<Object?, Object?>);
          final documentSide = args['documentSide']?.toString() ?? 'unknown';
          final frontSidePhoto = args['frontSidePhoto']?.toString();
          final backSidePhoto = args['backSidePhoto']?.toString();
          onDocumentScan!(documentSide, frontSidePhoto, backSidePhoto);
        }
        break;
      case 'onBackButtonPressed':
        debugPrint('Back button pressed in OCR native UI');
        if (onBackButtonPressed != null) {
          onBackButtonPressed!();
        }
        break;
      case 'onOCRAndDocumentLivenessResult':
        if (onOCRAndDocumentLivenessResult != null && call.arguments != null) {
          try {
            final convertedArgs =
                _deepConvertMap(call.arguments as Map<Object?, Object?>);
            final response =
                OCRAndDocumentLivenessResponse.fromMap(convertedArgs);
            onOCRAndDocumentLivenessResult!(response);
          } catch (e) {
            debugPrint('Error parsing OCR+DocLiveness response: $e');
          }
        }
        break;
      case 'onOCRAndDocumentLivenessFailure':
        if ((onOCRAndDocumentLivenessFailure != null ||
                onOCRAndDocumentLivenessError != null) &&
            call.arguments != null) {
          final failure = OCRFailure.fromArguments(
              _deepConvertMap(call.arguments as Map<Object?, Object?>),
              'Unknown OCR and document liveness error');
          onOCRAndDocumentLivenessFailure?.call(failure.message);
          onOCRAndDocumentLivenessError?.call(failure);
        }
        break;
      // Hologram callbacks
      case 'onHologramVideoRecorded':
        if (onHologramVideoRecorded != null && call.arguments != null) {
          try {
            final args =
                _deepConvertMap(call.arguments as Map<Object?, Object?>);
            final videoUrls =
                (args['videoUrls'] as List<dynamic>).cast<String>();
            onHologramVideoRecorded!(videoUrls);
          } catch (e) {
            debugPrint('Error parsing hologram video recorded response: $e');
          }
        }
        break;
      case 'onHologramFailure':
        if ((onHologramFailure != null || onHologramError != null) && call.arguments != null) {
          final failure = OCRFailure.fromArguments(
              _deepConvertMap(call.arguments as Map<Object?, Object?>), 'Unknown hologram error');
          onHologramFailure?.call(failure.message);
          onHologramError?.call(failure);
        }
        break;
      case 'onHologramBackButtonPressed':
        debugPrint('Hologram back button pressed');
        if (onHologramBackButtonPressed != null) {
          onHologramBackButtonPressed!();
        }
        break;
      case 'onOCRDirectiveChanged':
        if (onOCRDirectiveChanged != null && call.arguments != null) {
          final args = _deepConvertMap(call.arguments as Map<Object?, Object?>);
          final directive = args['directive']?.toString() ?? '';
          final timestamp = (args['timestamp'] as num?)?.toDouble() ?? 0.0;
          onOCRDirectiveChanged!(directive, timestamp);
        }
        break;
      case 'onHologramDirectiveChanged':
        if (onHologramDirectiveChanged != null && call.arguments != null) {
          final args = _deepConvertMap(call.arguments as Map<Object?, Object?>);
          final directive = args['directive']?.toString() ?? '';
          final timestamp = (args['timestamp'] as num?)?.toDouble() ?? 0.0;
          onHologramDirectiveChanged!(directive, timestamp);
        }
        break;
      case 'onIQAResult':
        if (onIQAResult != null && call.arguments != null) {
          try {
            final args =
                _deepConvertMap(call.arguments as Map<Object?, Object?>);
            onIQAResult!(IQAResult.fromMap(args));
          } catch (e) {
            debugPrint('Error parsing IQA result: $e');
          }
        }
        break;
      case 'onCardScanFinished':
      case 'onPhotoTaken':
        // Progress notes the native camera sends (Android); nothing in the Dart API listens for them.
        break;
      default:
        debugPrint('Unknown OCR native event: ${call.method}');
    }
  }

  // OCR Camera Methods
  @override
  Future<bool> startOCRCamera(OCRCameraParams params) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startOCRCamera',
        params.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to start OCR camera',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<OCRResponse> performOCR(OCRProcessParams params) async {
    try {
      final payload = params.toMap();

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'performOCR',
        payload,
      );

      if (result == null) {
        throw Exception('No OCR response received');
      }

      // Deep conversion to handle nested maps
      Map<String, dynamic> convertedResult = _deepConvertMap(result);

      return OCRResponse.fromMap(convertedResult);
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to perform OCR',
        details: e.details?.toString(),
        originalError: e,
      );
    } catch (e) {
      // Catch any other errors including type casting errors
      throw OCRException.fromError(
        'TYPE_ERROR',
        'Failed to process OCR response: $e',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  // Hologram Methods
  @override
  Future<bool> startHologramCamera(HologramParams params) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startHologramCamera',
        params.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to start hologram camera',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<HologramResponse> uploadHologramVideo(
    HologramParams params,
    List<String> videoUrls,
  ) async {
    try {
      final Map<String, dynamic> arguments = {
        ...params.toMap(),
        'videoUrls': videoUrls
      };

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'uploadHologramVideo',
        arguments,
      );

      if (result == null) {
        throw Exception('No hologram response received from native platform');
      }

      // Deep conversion to handle nested maps (similar to OCR)
      Map<String, dynamic> convertedResult = _deepConvertMap(result);

      return HologramResponse.fromMap(convertedResult);
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to upload hologram video',
        details: e.details?.toString(),
        originalError: e,
      );
    } catch (e) {
      throw OCRException.fromError(
        'HOLOGRAM_UPLOAD_ERROR',
        'Failed to process hologram upload response: $e',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  // Document Liveness Methods
  @override
  Future<OCRAndDocumentLivenessResponse> performDocumentLiveness(
    DocumentLivenessParams params,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'performDocumentLiveness',
        params.toMap(),
      );

      if (result == null) {
        throw Exception('No document liveness response received');
      }

      // Deep conversion to handle nested maps
      Map<String, dynamic> convertedResult = _deepConvertMap(result);

      return OCRAndDocumentLivenessResponse.fromMap(convertedResult);
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to perform document liveness',
        details: e.details?.toString(),
        originalError: e,
      );
    } catch (e) {
      // Catch any other errors including type casting errors
      throw OCRException.fromError(
        'TYPE_ERROR',
        'Failed to process document liveness response: $e',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<OCRAndDocumentLivenessResponse> performOCRAndDocumentLiveness(
    OCRAndDocumentLivenessParams params,
  ) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'performOCRAndDocumentLiveness',
        params.toMap(),
      );

      if (result == null) {
        throw Exception('No OCR and document liveness response received');
      }

      // Deep conversion to handle nested maps
      Map<String, dynamic> convertedResult = _deepConvertMap(result);

      return OCRAndDocumentLivenessResponse.fromMap(convertedResult);
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to perform OCR and document liveness',
        details: e.details?.toString(),
        originalError: e,
      );
    } catch (e) {
      // Catch any other errors including type casting errors
      throw OCRException.fromError(
        'TYPE_ERROR',
        'Failed to process OCR and document liveness response: $e',
        details: e.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<bool> setRepeatConfig(OCRRepeatConfig? config) async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await methodChannel.invokeMethod<bool>(
              'setRepeatConfig', config?.toMap()) ??
          false;
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to set OCR repeat config',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  // UI Configuration
  @override
  Future<void> setOCRUIConfig(OCRUIConfig config) async {
    try {
      await methodChannel.invokeMethod<void>('setOCRUIConfig', config.toMap());
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to set OCR UI config',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  // Camera Control
  @override
  Future<void> dismissOCRCamera() async {
    try {
      await methodChannel.invokeMethod<void>('dismissOCRCamera');
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to dismiss OCR camera',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<void> dismissHologramCamera() async {
    try {
      await methodChannel.invokeMethod<void>('dismissHologramCamera');
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to dismiss hologram camera',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> performIQA({
    required String serverURL,
    required String transactionID,
    required String imageBase64,
    required String documentType,
    required String documentSide,
    String country = 'TUR',
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'performIQA',
        {
          'serverURL': serverURL,
          'transactionID': transactionID,
          'imageBase64': imageBase64,
          'documentType': documentType,
          'documentSide': documentSide,
          'country': country,
        },
      );
      if (result == null) throw Exception('No IQA response received');
      return _deepConvertMap(result);
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to perform IQA',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  @override
  Future<String> takePhoto() async {
    try {
      final result = await methodChannel.invokeMethod<String>('takePhoto');
      return result ?? '';
    } on PlatformException catch (e) {
      throw OCRException.fromError(
        e.code,
        e.message ?? 'Failed to take photo',
        details: e.details?.toString(),
        originalError: e,
      );
    }
  }

  // Static getter and setter methods for callback access
  static void setOnOCRSuccessCallback(Function(OCRResponse) callback) {
    onOCRSuccess = callback;
  }

  static void setOnOCRFailureCallback(Function(String) callback) {
    onOCRFailure = callback;
  }

  /// Like [setOnOCRFailureCallback] but with the SDK's error name as well.
  static void setOnOCRErrorCallback(Function(OCRFailure) callback) {
    onOCRError = callback;
  }

  static void setOnDocumentScanCallback(
    Function(String, String?, String?) callback,
  ) {
    onDocumentScan = callback;
  }

  static void setOnBackButtonPressedCallback(Function() callback) {
    onBackButtonPressed = callback;
  }

  static void setOnOCRAndDocumentLivenessResultCallback(
    Function(OCRAndDocumentLivenessResponse) callback,
  ) {
    onOCRAndDocumentLivenessResult = callback;
  }

  static void setOnOCRAndDocumentLivenessFailureCallback(
    Function(String) callback,
  ) {
    onOCRAndDocumentLivenessFailure = callback;
  }

  /// Like [setOnOCRAndDocumentLivenessFailureCallback] but with the SDK's error name as well.
  static void setOnOCRAndDocumentLivenessErrorCallback(Function(OCRFailure) callback) {
    onOCRAndDocumentLivenessError = callback;
  }

  // Hologram callback setters
  static void setOnHologramVideoRecordedCallback(
      Function(List<String>) callback) {
    onHologramVideoRecorded = callback;
  }

  static void setOnHologramFailureCallback(Function(String) callback) {
    onHologramFailure = callback;
  }

  /// Like [setOnHologramFailureCallback] but with the SDK's error name as well.
  static void setOnHologramErrorCallback(Function(OCRFailure) callback) {
    onHologramError = callback;
  }

  static void setOnHologramBackButtonPressedCallback(Function() callback) {
    onHologramBackButtonPressed = callback;
  }

  static void setOnOCRDirectiveChangedCallback(Function(String, double) callback) {
    onOCRDirectiveChanged = callback;
  }

  static void setOnHologramDirectiveChangedCallback(Function(String, double) callback) {
    onHologramDirectiveChanged = callback;
  }

  static void setOnIQAResultCallback(Function(IQAResult) callback) {
    onIQAResult = callback;
  }

  static void clearAllCallbacks() {
    onOCRSuccess = null;
    onOCRFailure = null;
    onOCRError = null;
    onDocumentScan = null;
    onBackButtonPressed = null;
    onOCRAndDocumentLivenessResult = null;
    onOCRAndDocumentLivenessFailure = null;
    onOCRAndDocumentLivenessError = null;
    // Clear hologram callbacks
    onHologramVideoRecorded = null;
    onHologramFailure = null;
    onHologramError = null;
    onHologramBackButtonPressed = null;
    // Clear directive callbacks
    onOCRDirectiveChanged = null;
    onHologramDirectiveChanged = null;
    onIQAResult = null;
  }

  // Helper method to deeply convert nested maps from Object? to String keys
  Map<String, dynamic> _deepConvertMap(Map<Object?, Object?> source) {
    Map<String, dynamic> result = {};

    source.forEach((key, value) {
      if (key != null) {
        String stringKey = key.toString();

        if (value is Map<Object?, Object?>) {
          // Recursively convert nested maps
          result[stringKey] = _deepConvertMap(value);
        } else if (value is List) {
          // Convert lists that might contain maps
          result[stringKey] = _deepConvertList(value);
        } else {
          // Direct assignment for primitive types
          result[stringKey] = value;
        }
      }
    });

    return result;
  }

  // Helper method to convert lists that might contain maps
  List<dynamic> _deepConvertList(List<dynamic> source) {
    return source.map((item) {
      if (item is Map<Object?, Object?>) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      } else {
        return item;
      }
    }).toList();
  }
}
