import 'package:liveness_flutter/liveness_flutter.dart';

/// Manages selfie capture and processing operations
class SelfieManager {
  // Selfie state
  String? _capturedSelfieImage;
  String _selfieOperation = 'registration';
  FaceRecognitionResult? _selfieResult;
  bool _isSelfieCapturing = false;
  String? _displaySelfie;
  
  // Getters
  String? get capturedSelfieImage => _capturedSelfieImage;
  String get selfieOperation => _selfieOperation;
  FaceRecognitionResult? get selfieResult => _selfieResult;
  bool get isSelfieCapturing => _isSelfieCapturing;
  String? get displaySelfie => _displaySelfie;
  
  // Setters
  set selfieOperation(String operation) => _selfieOperation = operation;
  set isSelfieCapturing(bool capturing) => _isSelfieCapturing = capturing;
  
  /// Handle selfie taken callback
  void handleSelfieTaken(String base64Image) {
    print('\n🤳 ========== SELFIE TAKEN EVENT FIRED ==========');
    print('📦 Base64 image length: ${base64Image.length} characters');
    
    _isSelfieCapturing = false;
    _capturedSelfieImage = base64Image;
    _displaySelfie = base64Image;
    
    print('✅ Selfie captured and stored successfully');
    print('===================================\n');
  }
  
  /// Process captured selfie with face recognition API
  Future<FaceRecognitionResult?> processCapturedSelfie(FaceRecognizerCredentials credentials) async {
    print('\n🔄 ========== PROCESSING CAPTURED SELFIE ==========');
    print('⏰ Start Time: ${DateTime.now()}');
    print('📋 Operation Type: $_selfieOperation');
    print('📷 Selfie Image State: ${_capturedSelfieImage != null ? 'EXISTS' : 'NULL/UNDEFINED'}');
    print('📷 Selfie Image Size: ${_capturedSelfieImage?.length ?? 0} characters');

    if (_capturedSelfieImage == null || _capturedSelfieImage!.isEmpty) {
      print('❌ ABORTING: No selfie image available');
      return null;
    }

    try {
      print('🔧 Processing selfie with Face Recognition API...');
      print('   🌐 Server URL: ${credentials.serverURL}');
      print('   🆔 Transaction ID: ${credentials.transactionID}');
      print('   👤 User ID: ${credentials.userID}');
      print('   🔐 Is Authentication: ${_selfieOperation == 'authentication'}');

      final isAuthentication = _selfieOperation == 'authentication';
      
      // ✨ Use the new performFaceRecognitionWithSelfie method that processes captured selfie
      final result = await LivenessFlutter.performFaceRecognitionWithSelfie(
        credentials,
        _capturedSelfieImage!,
        isAuthentication,
      );

      print('✅ Selfie processing completed');
      print('📊 Result: $result');

      _selfieResult = result;
      return result;

    } catch (error) {
      print('❌ Selfie processing failed with exception: $error');
      _selfieResult = null;
      rethrow;
    } finally {
      print('================================================\n');
    }
  }
  
  /// Start selfie capture process
  Future<void> startSelfieCapture(FaceRecognizerCredentials credentials) async {
    print('\n🤳 ========== STARTING SELFIE CAPTURE ==========');
    print('⏰ Start Time: ${DateTime.now()}');
    print('👤 User ID: ${credentials.userID}');
    print('📋 Operation Type: $_selfieOperation');

    try {
      _isSelfieCapturing = true;
      
      print('🔧 Building credentials for selfie capture...');
      print('✅ Credentials built successfully');
      print('🚀 Launching Selfie Capture with credentials:');
      print('   🌐 Server URL: ${credentials.serverURL}');
      print('   🆔 Transaction ID: ${credentials.transactionID}');
      print('   👤 User ID: ${credentials.userID}');
      
      // ✨ Use the new startSelfieCapture method that only captures without processing
      await LivenessFlutter.startSelfieCapture(credentials);
      
      print('✅ Selfie capture started successfully');
      print('⏳ Waiting for selfie to be captured...');
    } catch (error) {
      print('❌ Selfie capture failed with exception: $error');
      _isSelfieCapturing = false;
      rethrow;
    } finally {
      print('==============================================\n');
    }
  }
  
  /// Clear captured selfie
  void clearCapturedSelfie() {
    print('🗑️ Clearing captured selfie image');
    _capturedSelfieImage = null;
    _selfieResult = null;
    _displaySelfie = null;
  }
  
  /// Reset selfie state
  void resetSelfieState() {
    _capturedSelfieImage = null;
    _selfieResult = null;
    _isSelfieCapturing = false;
    _displaySelfie = null;
    _selfieOperation = 'registration';
    print('🔄 Selfie state has been reset');
  }
  
  /// Check if selfie is ready for processing
  bool isSelfieReadyForProcessing() {
    return _capturedSelfieImage != null && _capturedSelfieImage!.isNotEmpty;
  }
  
  /// Get selfie status message
  String getSelfieStatusMessage() {
    if (_capturedSelfieImage != null) {
      return 'Selfie is ready for $_selfieOperation processing. Image size: ${_capturedSelfieImage!.length} characters.';
    } else {
      return 'Capture a selfie first, then you can process it manually for face recognition.';
    }
  }
}
