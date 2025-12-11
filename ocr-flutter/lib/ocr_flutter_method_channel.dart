import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'src/ocr_flutter_platform_interface.dart';
import 'src/models/ocr_models.dart';
import 'src/types/ocr_types.dart';
import 'src/types/hologram_types.dart';
import 'src/types/ui_types.dart';

/// An implementation of [OcrFlutterPlatform] that uses method channels.
class MethodChannelOcrFlutter extends OcrFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ocr_flutter');

  // Callbacks for OCR camera events - make them accessible from other classes
  static Function(OCRResponse)? onOCRSuccess;
  static Function(String)? onOCRFailure;
  static Function(String, String?, String?)? onDocumentScan;
  static Function()? onBackButtonPressed;
  static Function(OCRAndDocumentLivenessResponse)?
      onOCRAndDocumentLivenessResult;

  // Hologram callback functions
  static Function(List<String>)? onHologramVideoRecorded;
  static Function(String)? onHologramFailure;
  static Function()? onHologramBackButtonPressed;

  MethodChannelOcrFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOCRSuccess':
        debugPrint('OCR success event: ${call.arguments}');
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
        debugPrint('OCR failure event: ${call.arguments}');
        if (onOCRFailure != null && call.arguments != null) {
          final error =
              call.arguments['error']?.toString() ?? 'Unknown OCR error';
          onOCRFailure!(error);
        }
        break;
      case 'onDocumentScan':
        debugPrint('Document scan event: ${call.arguments}');
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
        debugPrint('OCR+DocLiveness event: ${call.arguments}');
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
      // Hologram callbacks
      case 'onHologramVideoRecorded':
        debugPrint('🎬 Hologram video recorded event: ${call.arguments}');
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
        debugPrint('🎬 Hologram failure event: ${call.arguments}');
        if (onHologramFailure != null && call.arguments != null) {
          final args = _deepConvertMap(call.arguments as Map<Object?, Object?>);
          final error = args['error']?.toString() ?? 'Unknown hologram error';
          onHologramFailure!(error);
        }
        break;
      case 'onHologramBackButtonPressed':
        debugPrint('🎬 Hologram back button pressed');
        if (onHologramBackButtonPressed != null) {
          onHologramBackButtonPressed!();
        }
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
      // Debug logging - print OCR request payload
      debugPrint('🔍 OCR REQUEST PAYLOAD:');
      debugPrint('   Method: performOCR');
      final payload = params.toMap();
      debugPrint('   Payload Type: ${payload.runtimeType}');
      debugPrint('   Payload Keys: ${payload.keys.toList()}');

      // Print each key-value pair (excluding large base64 images)
      payload.forEach((key, value) {
        if (key == 'frontSidePhoto' || key == 'backSidePhoto') {
          if (value != null && value is String) {
            debugPrint(
                '   [$key]: [Base64 Image - ${value.length} characters]');
            debugPrint(
                '   [$key] Preview: ${value.substring(0, value.length > 50 ? 50 : value.length)}...');
          } else {
            debugPrint('   [$key]: $value');
          }
        } else {
          debugPrint('   [$key]: $value (${value.runtimeType})');
        }
      });

      debugPrint(
          '🚀 Flutter: About to call methodChannel.invokeMethod(performOCR)');

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'performOCR',
        payload,
      );

      debugPrint('✅ Flutter: performOCR methodChannel call completed');

      if (result == null) {
        debugPrint('❌ Flutter: OCR result is null!');
        throw Exception('No OCR response received');
      }

      // Debug logging - print raw response
      debugPrint('🔍 RAW OCR Response from iOS:');
      debugPrint('   Type: ${result.runtimeType}');
      debugPrint('   Raw Response: $result');
      debugPrint('   Keys: ${result.keys.toList()}');
      debugPrint('   Values: ${result.values.toList()}');

      // Deep conversion to handle nested maps
      Map<String, dynamic> convertedResult = _deepConvertMap(result);
      debugPrint('   ✅ Deep conversion completed');

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
      debugPrint('🎬 Flutter: Starting hologram video upload...');
      debugPrint('   Server URL: ${params.serverURL}');
      debugPrint('   Transaction ID: ${params.transactionID}');
      debugPrint('   Video URLs count: ${videoUrls.length}');
      debugPrint('   Country: ${params.country?.value}');
      debugPrint('   Log Level: ${params.logLevel}');

      final Map<String, dynamic> arguments = {
        ...params.toMap(),
        'videoUrls': videoUrls
      };
      debugPrint(
          '🚀 Flutter: About to call methodChannel.invokeMethod with arguments:');
      debugPrint('   Method: uploadHologramVideo');
      debugPrint('   Arguments: $arguments');

      final result = await methodChannel.invokeMethod<Map<Object?, Object?>>(
        'uploadHologramVideo',
        arguments,
      );

      debugPrint(
          '✅ Flutter: methodChannel.invokeMethod completed, received result');

      if (result == null) {
        debugPrint('❌ Flutter: result is null!');
        throw Exception('No hologram response received from native platform');
      }

      debugPrint('🎬 Flutter: Raw hologram response received:');
      debugPrint('   Type: ${result.runtimeType}');
      debugPrint('   Raw Response: $result');
      debugPrint('   Keys: ${result.keys.toList()}');
      debugPrint('   Values: ${result.values.toList()}');

      // Print each key-value pair for detailed analysis
      result.forEach((key, value) {
        debugPrint('   [$key]: $value (${value.runtimeType})');
      });

      // Deep conversion to handle nested maps (similar to OCR)
      Map<String, dynamic> convertedResult = _deepConvertMap(result);
      debugPrint('   ✅ Deep conversion completed for hologram response');

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

  // Static getter and setter methods for callback access
  static void setOnOCRSuccessCallback(Function(OCRResponse) callback) {
    onOCRSuccess = callback;
  }

  static void setOnOCRFailureCallback(Function(String) callback) {
    onOCRFailure = callback;
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

  // Hologram callback setters
  static void setOnHologramVideoRecordedCallback(
      Function(List<String>) callback) {
    onHologramVideoRecorded = callback;
  }

  static void setOnHologramFailureCallback(Function(String) callback) {
    onHologramFailure = callback;
  }

  static void setOnHologramBackButtonPressedCallback(Function() callback) {
    onHologramBackButtonPressed = callback;
  }

  static void clearAllCallbacks() {
    onOCRSuccess = null;
    onOCRFailure = null;
    onDocumentScan = null;
    onBackButtonPressed = null;
    onOCRAndDocumentLivenessResult = null;
    // Clear hologram callbacks
    onHologramVideoRecorded = null;
    onHologramFailure = null;
    onHologramBackButtonPressed = null;
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
