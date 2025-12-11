import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'models/liveness_models.dart';
import 'liveness_flutter_method_channel.dart';

/// The interface that implementations of liveness_flutter must implement.
///
/// Platform implementations should extend this class rather than implement it as `LivenessFlutter`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [LivenessFlutterPlatform] methods.
abstract class LivenessFlutterPlatform extends PlatformInterface {
  /// Constructs a LivenessFlutterPlatform.
  LivenessFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static LivenessFlutterPlatform _instance = MethodChannelLivenessFlutter();

  /// The default instance of [LivenessFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelLivenessFlutter].
  static LivenessFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LivenessFlutterPlatform] when
  /// they register themselves.
  static set instance(LivenessFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check if face recognition permissions are granted
  Future<FaceRecognitionPermissionStatus> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Request face recognition permissions
  Future<FaceRecognitionPermissionStatus> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Start face recognition with embedded camera for registration
  Future<FaceRecognitionResult> startFaceRecognitionRegistration(
    FaceRecognizerCredentials credentials,
  ) {
    throw UnimplementedError(
        'startFaceRecognitionRegistration() has not been implemented.');
  }

  /// Start face recognition with embedded camera for authentication
  Future<FaceRecognitionResult> startFaceRecognitionAuthentication(
    FaceRecognizerCredentials credentials,
  ) {
    throw UnimplementedError(
        'startFaceRecognitionAuthentication() has not been implemented.');
  }

  /// Start active liveness detection
  Future<FaceRecognitionResult> startActiveLiveness(
    FaceRecognizerCredentials credentials,
    {bool isAuthentication = false}
  ) {
    throw UnimplementedError('startActiveLiveness() has not been implemented.');
  }

  /// Start hybrid liveness detection (combines active and passive liveness)
  Future<FaceRecognitionResult> startHybridLiveness(
      FaceRecognizerCredentials credentials,
      {bool isAuthentication = false}) {
    throw UnimplementedError('startHybridLiveness() has not been implemented.');
  }

  /// Register user with provided photo (base64)
  Future<FaceRecognitionResult> registerUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) {
    throw UnimplementedError(
        'registerUserWithPhoto() has not been implemented.');
  }

  /// Authenticate user with provided photo (base64)
  Future<FaceRecognitionResult> authenticateUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) {
    throw UnimplementedError(
        'authenticateUserWithPhoto() has not been implemented.');
  }

  /// Start selfie capture for manual processing
  Future<FaceRecognitionResult> startSelfieCapture(
    FaceRecognizerCredentials credentials,
  ) {
    throw UnimplementedError('startSelfieCapture() has not been implemented.');
  }

  /// Process captured selfie with face recognition API
  Future<FaceRecognitionResult> performFaceRecognitionWithSelfie(
    FaceRecognizerCredentials credentials,
    String base64Image,
    bool isAuthentication,
  ) {
    throw UnimplementedError(
        'performFaceRecognitionWithSelfie() has not been implemented.');
  }

  /// Set callback for face recognition result updates
  Future<void> setOnResultCallback(Function(FaceRecognitionResult) callback) {
    throw UnimplementedError('setOnResultCallback() has not been implemented.');
  }

  /// Set callback for face recognition failure updates
  Future<void> setOnFailureCallback(Function(FaceRecognitionError) callback) {
    throw UnimplementedError(
        'setOnFailureCallback() has not been implemented.');
  }

  /// Set callback for photo taken event
  Future<void> setOnPhotoTakenCallback(Function() callback) {
    throw UnimplementedError(
        'setOnPhotoTakenCallback() has not been implemented.');
  }

  /// Set callback for selfie taken event
  Future<void> setOnSelfieTakenCallback(Function(String) callback) {
    throw UnimplementedError(
        'setOnSelfieTakenCallback() has not been implemented.');
  }

  /// Set callback for active liveness result (ActiveLivenessOperator interface)
  Future<void> setOnActiveLivenessResultCallback(
      Function(FaceRecognitionResult) callback) {
    throw UnimplementedError(
        'setOnActiveLivenessResultCallback() has not been implemented.');
  }

  /// Set callback for active liveness failure (ActiveLivenessOperator interface)
  Future<void> setOnActiveLivenessFailureCallback(
      Function(FaceRecognitionError) callback) {
    throw UnimplementedError(
        'setOnActiveLivenessFailureCallback() has not been implemented.');
  }

  /// Cancel current face recognition operation
  Future<void> cancelFaceRecognition() {
    throw UnimplementedError(
        'cancelFaceRecognition() has not been implemented.');
  }

  /// Check if face recognition is currently in progress
  Future<bool> isFaceRecognitionInProgress() {
    throw UnimplementedError(
        'isFaceRecognitionInProgress() has not been implemented.');
  }

  /// Add user to identification list
  Future<AddUserToListResult> addUserToList({
    required String serverURL,
    required String transactionId,
    required String status,
    Map<String, dynamic>? metadata,
  }) {
    throw UnimplementedError('addUserToList() has not been implemented.');
  }

  /// Start face recognition identification
  Future<FaceRecognitionResult> startFaceRecognitionIdentification({
    required String serverURL,
    required String transactionId,
    required String listName,
    String? logLevel,
  }) {
    throw UnimplementedError(
        'startFaceRecognitionIdentification() has not been implemented.');
  }

  /// Delete user from identification list
  Future<DeleteUserFromListResult> deleteUserFromList({
    required String serverURL,
    required String transactionId,
    required String listName,
    required String photoBase64,
  }) {
    throw UnimplementedError('deleteUserFromList() has not been implemented.');
  }

  /// Configure UI settings
  Future<void> configureUISettings(UISettings settings) {
    throw UnimplementedError('configureUISettings() has not been implemented.');
  }

  /// Set localization
  Future<void> setLocalization({
    required String languageCode,
    Map<String, String>? customStrings,
  }) {
    throw UnimplementedError('setLocalization() has not been implemented.');
  }
}
