import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'models/liveness_models.dart';
import 'liveness_flutter_platform_interface.dart';

/// An implementation of [LivenessFlutterPlatform] that uses method channels.
class MethodChannelLivenessFlutter extends LivenessFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('liveness_flutter');

  // Callback functions
  Function(FaceRecognitionResult)? _onResultCallback;
  Function(FaceRecognitionError)? _onFailureCallback;
  Function()? _onPhotoTakenCallback;
  Function(String)? _onSelfieTakenCallback;
  Function(FaceRecognitionResult)? _onActiveLivenessResultCallback;
  Function(FaceRecognitionError)? _onActiveLivenessFailureCallback;

  MethodChannelLivenessFlutter() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onResult':
        final Map<String, dynamic> arguments = _safeConvertMap(call.arguments);
        final result = _createResultFromRawData(arguments);
        _onResultCallback?.call(result);
        break;
      case 'onFailure':
        final Map<String, dynamic> arguments = _safeConvertMap(call.arguments);
        final error = FaceRecognitionError.fromMap(arguments);
        _onFailureCallback?.call(error);
        break;
      case 'onPhotoTaken':
        _onPhotoTakenCallback?.call();
        break;
      case 'onSelfieTaken':
        final String base64Image = call.arguments['base64Image'] ?? '';
        _onSelfieTakenCallback?.call(base64Image);
        break;
      case 'onActiveLivenessResult':
        final Map<String, dynamic> arguments = _safeConvertMap(call.arguments);
        final result = _createResultFromRawData(arguments);
        _onActiveLivenessResultCallback?.call(result);
        break;
      case 'onActiveLivenessFailure':
        final Map<String, dynamic> arguments = _safeConvertMap(call.arguments);
        final error = FaceRecognitionError.fromMap(arguments);
        _onActiveLivenessFailureCallback?.call(error);
        break;
      default:
        throw UnimplementedError('Method ${call.method} not implemented');
    }
  }

  @override
  Future<FaceRecognitionPermissionStatus> checkPermissions() async {
    final result = await methodChannel.invokeMethod('checkPermissions');
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionPermissionStatus.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionPermissionStatus> requestPermissions() async {
    final result = await methodChannel.invokeMethod('requestPermissions');
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionPermissionStatus.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> startFaceRecognitionRegistration(
    FaceRecognizerCredentials credentials,
  ) async {
    final result = await methodChannel.invokeMethod(
      'startFaceRecognitionRegistration',
      credentials.toMap(),
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> startFaceRecognitionAuthentication(
    FaceRecognizerCredentials credentials,
  ) async {
    final result = await methodChannel.invokeMethod(
      'startFaceRecognitionAuthentication',
      credentials.toMap(),
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> startActiveLiveness(
    FaceRecognizerCredentials credentials,
    {bool isAuthentication = false}
  ) async {
    final arguments = {
      ...credentials.toMap(),
      'isAuthentication': isAuthentication,
    };
    final result = await methodChannel.invokeMethod(
      'startActiveLiveness',
      arguments,
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> startHybridLiveness(
      FaceRecognizerCredentials credentials,
      {bool isAuthentication = false}) async {
    final arguments = {
      ...credentials.toMap(),
      'isAuthentication': isAuthentication,
    };
    final result = await methodChannel.invokeMethod(
      'startHybridLiveness',
      arguments,
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> registerUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) async {
    final arguments = {
      ...credentials.toMap(),
      'base64Image': base64Image,
    };
    final result = await methodChannel.invokeMethod(
      'registerUserWithPhoto',
      arguments,
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<FaceRecognitionResult> authenticateUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) async {
    final arguments = {
      ...credentials.toMap(),
      'base64Image': base64Image,
    };
    final result = await methodChannel.invokeMethod(
      'authenticateUserWithPhoto',
      arguments,
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  /// Start selfie capture for manual processing
  @override
  Future<FaceRecognitionResult> startSelfieCapture(
    FaceRecognizerCredentials credentials,
  ) async {
    final result = await methodChannel.invokeMethod(
      'startSelfieCapture',
      credentials.toMap(),
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  /// Process captured selfie with face recognition API
  @override
  Future<FaceRecognitionResult> performFaceRecognitionWithSelfie(
    FaceRecognizerCredentials credentials,
    String base64Image,
    bool isAuthentication,
  ) async {
    final arguments = {
      ...credentials.toMap(),
      'base64Image': base64Image,
      'isAuthentication': isAuthentication,
    };
    final result = await methodChannel.invokeMethod(
      'performFaceRecognitionWithSelfie',
      arguments,
    );
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<void> setOnResultCallback(
      Function(FaceRecognitionResult) callback) async {
    _onResultCallback = callback;
  }

  @override
  Future<void> setOnFailureCallback(
      Function(FaceRecognitionError) callback) async {
    _onFailureCallback = callback;
  }

  @override
  Future<void> setOnPhotoTakenCallback(Function() callback) async {
    _onPhotoTakenCallback = callback;
  }

  @override
  Future<void> setOnSelfieTakenCallback(Function(String) callback) async {
    _onSelfieTakenCallback = callback;
  }

  @override
  Future<void> setOnActiveLivenessResultCallback(
      Function(FaceRecognitionResult) callback) async {
    _onActiveLivenessResultCallback = callback;
  }

  @override
  Future<void> setOnActiveLivenessFailureCallback(
      Function(FaceRecognitionError) callback) async {
    _onActiveLivenessFailureCallback = callback;
  }

  @override
  Future<void> cancelFaceRecognition() async {
    await methodChannel.invokeMethod('cancelFaceRecognition');
  }

  @override
  Future<bool> isFaceRecognitionInProgress() async {
    final result =
        await methodChannel.invokeMethod('isFaceRecognitionInProgress');
    return result as bool? ?? false;
  }

  @override
  Future<AddUserToListResult> addUserToList({
    required String serverURL,
    required String transactionId,
    required String status,
    Map<String, dynamic>? metadata,
  }) async {
    final arguments = {
      'serverURL': serverURL,
      'transactionId': transactionId,
      'status': status,
      'metadata': metadata,
    };
    final result = await methodChannel.invokeMethod('addUserToList', arguments);
    final resultMap = _safeConvertMap(result);
    return AddUserToListResult.fromMap(resultMap);
  }

  // New methods for identification workflow
  @override
  Future<FaceRecognitionResult> startFaceRecognitionIdentification({
    required String serverURL,
    required String transactionId,
    required String listName,
    String? logLevel,
  }) async {
    final arguments = {
      'serverURL': serverURL,
      'transactionID': transactionId,
      'listName': listName,
      'logLevel': logLevel,
    };
    final result = await methodChannel.invokeMethod(
        'startFaceRecognitionIdentification', arguments);
    final resultMap = _safeConvertMap(result);
    return FaceRecognitionResult.fromMap(resultMap);
  }

  @override
  Future<DeleteUserFromListResult> deleteUserFromList({
    required String serverURL,
    required String transactionId,
    required String listName,
    required String photoBase64,
  }) async {
    final arguments = {
      'serverURL': serverURL,
      'transactionID': transactionId,
      'listName': listName,
      'photo': photoBase64,
    };
    final result =
        await methodChannel.invokeMethod('deleteUserFromList', arguments);
    final resultMap = _safeConvertMap(result);
    return DeleteUserFromListResult.fromMap(resultMap);
  }

  // UI Customization
  @override
  Future<void> configureUISettings(UISettings settings) async {
    await methodChannel.invokeMethod('configureUISettings', settings.toMap());
  }

  // Localization
  @override
  Future<void> setLocalization({
    required String languageCode,
    Map<String, String>? customStrings,
  }) async {
    final arguments = {
      'languageCode': languageCode,
      'strings': customStrings,
    };
    await methodChannel.invokeMethod('setLocalization', arguments);
  }

  // Create FaceRecognitionResult from raw server response data
  FaceRecognitionResult _createResultFromRawData(Map<String, dynamic> rawData) {
    // Determine success based on server response
    final isFailed = rawData['isFailed'] as bool? ?? false;
    final isSuccess = !isFailed;
    
    // Create FaceIDMessage with raw server data
    final faceIDMessage = FaceIDMessage(
      success: isSuccess,
      message: isSuccess ? "Operation completed successfully" : "Operation failed",
      data: rawData, // Put all raw server data here
    );
    
    return FaceRecognitionResult(
      status: isSuccess ? FaceRecognitionStatus.success : FaceRecognitionStatus.error,
      faceIDMessage: faceIDMessage,
    );
  }

  // Helper method to safely convert Map<Object?, Object?> to Map<String, dynamic>
  Map<String, dynamic> _safeConvertMap(dynamic source) {
    if (source == null) return {};
    if (source is Map<String, dynamic>) return source;
    if (source is Map<Object?, Object?>) {
      return _deepConvertMap(source);
    }
    return {};
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
