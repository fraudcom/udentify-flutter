/// A Flutter plugin for Udentify Face Recognition & Liveness detection.
///
/// This plugin provides face recognition and liveness detection capabilities
/// using the Udentify SDK. It supports both embedded camera capture and
/// provided photo recognition, as well as active liveness detection.
library liveness_flutter;

export 'src/models/liveness_models.dart';
export 'src/liveness_flutter_platform_interface.dart';
import 'src/liveness_flutter_platform_interface.dart';
import 'src/models/liveness_models.dart';

/// The main class for interacting with the Liveness Flutter plugin.
class LivenessFlutter {
  LivenessFlutter._();

  static LivenessFlutterPlatform get _platform =>
      LivenessFlutterPlatform.instance;

  /// Check if face recognition permissions are granted.
  ///
  /// Returns a [FaceRecognitionPermissionStatus] indicating the status
  /// of camera, phone state, and internet permissions.
  static Future<FaceRecognitionPermissionStatus> checkPermissions() {
    return _platform.checkPermissions();
  }

  /// Request face recognition permissions.
  ///
  /// Returns a [FaceRecognitionPermissionStatus] indicating the status
  /// of camera, phone state, and internet permissions after the request.
  static Future<FaceRecognitionPermissionStatus> requestPermissions() {
    return _platform.requestPermissions();
  }

  /// Start face recognition with embedded camera for user registration.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  ///
  /// Returns a [FaceRecognitionResult] with the registration result.
  static Future<FaceRecognitionResult> startFaceRecognitionRegistration(
    FaceRecognizerCredentials credentials,
  ) {
    return _platform.startFaceRecognitionRegistration(credentials);
  }

  /// Start face recognition with embedded camera for user authentication.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  ///
  /// Returns a [FaceRecognitionResult] with the authentication result.
  static Future<FaceRecognitionResult> startFaceRecognitionAuthentication(
    FaceRecognizerCredentials credentials,
  ) {
    return _platform.startFaceRecognitionAuthentication(credentials);
  }

  /// Start active liveness detection.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  /// [isAuthentication] - Set to true for authentication, false for registration.
  ///
  /// Returns a [FaceRecognitionResult] with the liveness detection result.
  static Future<FaceRecognitionResult> startActiveLiveness(
    FaceRecognizerCredentials credentials,
    {bool isAuthentication = false}
  ) {
    return _platform.startActiveLiveness(credentials, isAuthentication: isAuthentication);
  }

  /// Start hybrid liveness detection (combines active and passive liveness).
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  /// [isAuthentication] - Set to true for authentication, false for registration.
  ///
  /// Returns a [FaceRecognitionResult] with the hybrid liveness detection result.
  static Future<FaceRecognitionResult> startHybridLiveness(
      FaceRecognizerCredentials credentials,
      {bool isAuthentication = false}) {
    return _platform.startHybridLiveness(credentials,
        isAuthentication: isAuthentication);
  }

  /// Register user with a provided photo.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  /// [base64Image] - The user's photo in base64 format.
  ///
  /// Returns a [FaceRecognitionResult] with the registration result.
  static Future<FaceRecognitionResult> registerUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) {
    return _platform.registerUserWithPhoto(credentials, base64Image);
  }

  /// Authenticate user with a provided photo.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  /// [base64Image] - The user's photo in base64 format.
  ///
  /// Returns a [FaceRecognitionResult] with the authentication result.
  static Future<FaceRecognitionResult> authenticateUserWithPhoto(
    FaceRecognizerCredentials credentials,
    String base64Image,
  ) {
    return _platform.authenticateUserWithPhoto(credentials, base64Image);
  }

  /// Start selfie capture for manual processing.
  ///
  /// This method opens the camera, captures a selfie, and closes the camera.
  /// The captured selfie can then be processed manually using [performFaceRecognitionWithSelfie].
  /// This provides a two-phase workflow: capture first, then process when ready.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  ///
  /// Returns a [FaceRecognitionResult] indicating the capture operation status.
  /// Listen for the onSelfieTaken callback to receive the captured image.
  static Future<FaceRecognitionResult> startSelfieCapture(
    FaceRecognizerCredentials credentials,
  ) {
    return _platform.startSelfieCapture(credentials);
  }

  /// Process captured selfie with face recognition API.
  ///
  /// This method performs face recognition on a previously captured selfie image.
  /// Use this after [startSelfieCapture] to manually control when processing occurs.
  ///
  /// [credentials] - The face recognizer credentials containing server URL,
  /// transaction ID, and other configuration options.
  /// [base64Image] - The captured selfie image in base64 format.
  /// [isAuthentication] - Set to true for authentication, false for registration.
  ///
  /// Returns a [FaceRecognitionResult] with the face recognition result.
  static Future<FaceRecognitionResult> performFaceRecognitionWithSelfie(
    FaceRecognizerCredentials credentials,
    String base64Image,
    bool isAuthentication,
  ) {
    return _platform.performFaceRecognitionWithSelfie(credentials, base64Image, isAuthentication);
  }

  /// Set callback for face recognition result updates.
  ///
  /// [callback] - Function to be called when a face recognition result is received.
  static Future<void> setOnResultCallback(
      Function(FaceRecognitionResult) callback) {
    return _platform.setOnResultCallback(callback);
  }

  /// Set callback for face recognition failure updates.
  ///
  /// [callback] - Function to be called when a face recognition failure occurs.
  static Future<void> setOnFailureCallback(
      Function(FaceRecognitionError) callback) {
    return _platform.setOnFailureCallback(callback);
  }

  /// Set callback for photo taken event.
  ///
  /// [callback] - Function to be called when a photo is taken.
  static Future<void> setOnPhotoTakenCallback(Function() callback) {
    return _platform.setOnPhotoTakenCallback(callback);
  }

  /// Set callback for selfie taken event.
  ///
  /// [callback] - Function to be called when a selfie is taken.
  /// The callback receives the selfie image in base64 format.
  static Future<void> setOnSelfieTakenCallback(Function(String) callback) {
    return _platform.setOnSelfieTakenCallback(callback);
  }

  /// Set callback for active liveness result (ActiveLivenessOperator interface).
  ///
  /// [callback] - Function to be called when active liveness completes successfully.
  static Future<void> setOnActiveLivenessResultCallback(
      Function(FaceRecognitionResult) callback) {
    return _platform.setOnActiveLivenessResultCallback(callback);
  }

  /// Set callback for active liveness failure (ActiveLivenessOperator interface).
  ///
  /// [callback] - Function to be called when active liveness fails.
  static Future<void> setOnActiveLivenessFailureCallback(
      Function(FaceRecognitionError) callback) {
    return _platform.setOnActiveLivenessFailureCallback(callback);
  }

  /// Cancel current face recognition operation.
  static Future<void> cancelFaceRecognition() {
    return _platform.cancelFaceRecognition();
  }

  /// Check if face recognition is currently in progress.
  ///
  /// Returns true if a face recognition operation is currently running.
  static Future<bool> isFaceRecognitionInProgress() {
    return _platform.isFaceRecognitionInProgress();
  }

  /// Add user to identification list.
  ///
  /// [serverURL] - The server endpoint URL.
  /// [transactionId] - The transaction ID.
  /// [status] - The status to assign (e.g., "Registered").
  /// [metadata] - Optional metadata to associate with the user.
  ///
  /// Returns an [AddUserToListResult] with the operation result.
  static Future<AddUserToListResult> addUserToList({
    required String serverURL,
    required String transactionId,
    required String status,
    Map<String, dynamic>? metadata,
  }) {
    return _platform.addUserToList(
      serverURL: serverURL,
      transactionId: transactionId,
      status: status,
      metadata: metadata,
    );
  }

  /// Start face recognition identification in a list.
  ///
  /// [serverURL] - The server endpoint URL.
  /// [transactionId] - The transaction ID.
  /// [listName] - The name of the list to search in.
  /// [logLevel] - Optional log level.
  ///
  /// Returns a [FaceRecognitionResult] with the identification result.
  static Future<FaceRecognitionResult> startFaceRecognitionIdentification({
    required String serverURL,
    required String transactionId,
    required String listName,
    String? logLevel,
  }) {
    return _platform.startFaceRecognitionIdentification(
      serverURL: serverURL,
      transactionId: transactionId,
      listName: listName,
      logLevel: logLevel,
    );
  }

  /// Delete user from identification list.
  ///
  /// [serverURL] - The server endpoint URL.
  /// [transactionId] - The transaction ID.
  /// [listName] - The name of the list to delete from.
  /// [photoBase64] - Base64 encoded photo of the user to delete.
  ///
  /// Returns a [DeleteUserFromListResult] with the operation result.
  static Future<DeleteUserFromListResult> deleteUserFromList({
    required String serverURL,
    required String transactionId,
    required String listName,
    required String photoBase64,
  }) {
    return _platform.deleteUserFromList(
      serverURL: serverURL,
      transactionId: transactionId,
      listName: listName,
      photoBase64: photoBase64,
    );
  }

  /// Configure UI appearance settings.
  ///
  /// [settings] - The UI settings configuration.
  static Future<void> configureUISettings(UISettings settings) {
    return _platform.configureUISettings(settings);
  }

  /// Set localization for UI strings.
  ///
  /// [languageCode] - The language code (e.g., "en", "tr").
  /// [customStrings] - Optional custom string overrides.
  static Future<void> setLocalization({
    required String languageCode,
    Map<String, String>? customStrings,
  }) {
    return _platform.setLocalization(
      languageCode: languageCode,
      customStrings: customStrings,
    );
  }
}
