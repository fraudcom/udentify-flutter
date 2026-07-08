import 'dart:io';
import 'package:liveness_flutter/liveness_flutter.dart';

/// Manages all liveness SDK callbacks and event handling
class LivenessCallbackManager {
  // Callback functions
  Function(FaceRecognitionResult)? _onResult;
  Function(FaceRecognitionError)? _onFailure;
  Function()? _onPhotoTaken;
  Function(String)? _onSelfieTaken;
  Function(FaceRecognitionResult)? _onActiveLivenessResult;
  Function(FaceRecognitionError)? _onActiveLivenessFailure;
  
  /// Setup all liveness callbacks
  void setupCallbacks({
    required Function(FaceRecognitionResult) onResult,
    required Function(FaceRecognitionError) onFailure,
    required Function() onPhotoTaken,
    required Function(String) onSelfieTaken,
    required Function(FaceRecognitionResult) onActiveLivenessResult,
    required Function(FaceRecognitionError) onActiveLivenessFailure,
  }) {
    _onResult = onResult;
    _onFailure = onFailure;
    _onPhotoTaken = onPhotoTaken;
    _onSelfieTaken = onSelfieTaken;
    _onActiveLivenessResult = onActiveLivenessResult;
    _onActiveLivenessFailure = onActiveLivenessFailure;
    
    _setupFaceRecognitionCallbacks();
    _setupActiveLivenessCallbacks();
    _setupPhotoCallbacks();
  }
  
  /// Setup face recognition result and failure callbacks
  void _setupFaceRecognitionCallbacks() {
    // Face Recognition Result Callback
    LivenessFlutter.setOnResultCallback((result) {
      print('\n🎉 ========== LIVENESS RESULT RECEIVED ==========');
      print('📊 Complete Result Object: $result');
      print('📋 Result Status: ${result.status}');

      if (result.faceIDMessage != null) {
        print('\n✅ ========== FACE ID MESSAGE DETAILS ==========');
        print('🔍 Face ID Success: ${result.faceIDMessage?.success}');
        print('💬 Face ID Message Text: "${result.faceIDMessage?.message}"');
        print('❌ Error Code: ${result.faceIDMessage?.errorCode}');
      }
      
      // Auto-close camera on Android when response is received
      if (Platform.isAndroid) {
        print('🤖 Android: Auto-closing face recognition camera after receiving response');
        try {
          LivenessFlutter.cancelFaceRecognition();
        } catch (e) {
          print('⚠️ Failed to close camera: $e');
        }
      }
      
      print('========================================\n');
      _onResult?.call(result);
    });

    // Face Recognition Failure Callback
    LivenessFlutter.setOnFailureCallback((error) {
      print('\n🚨 ========== LIVENESS FAILURE ==========');
      print('❌ Error Code: ${error.code}');
      print('💬 Error Message: "${error.message}"');
      print('📊 Error Details: ${error.details}');
      
      // Auto-close camera on Android when error occurs
      if (Platform.isAndroid) {
        print('🤖 Android: Auto-closing camera after error');
        try {
          LivenessFlutter.cancelFaceRecognition();
        } catch (e) {
          print('⚠️ Failed to close camera: $e');
        }
      }
      
      print('=====================================\n');
      _onFailure?.call(error);
    });
  }
  
  /// Setup active liveness callbacks
  void _setupActiveLivenessCallbacks() {
    // Active Liveness Result Callback
    LivenessFlutter.setOnActiveLivenessResultCallback((result) {
      print('\n🎭 ========== ACTIVE LIVENESS RESULT ==========');
      print('📊 Active Liveness Result: $result');
      print('📋 Result Status: ${result.status}');
      print('🤖 Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}');
      
      // Enhanced logging for Android debugging
      if (Platform.isAndroid) {
        print('🔍 Android Result Details:');
        print('   📱 Result Type: ${result.runtimeType}');
        print('   📄 Raw String: ${result.toString()}');
        
        if (result.faceIDMessage != null) {
          print('   💬 FaceID Message: ${result.faceIDMessage.toString()}');
          print('   ✅ Success: ${result.faceIDMessage?.success}');
          print('   📝 Message Text: ${result.faceIDMessage?.message}');
          
          // Log server response data if available
          if (result.faceIDMessage?.data != null) {
            print('   📡 SERVER RESPONSE DATA FOUND:');
            print('   📊 Data Type: ${result.faceIDMessage!.data.runtimeType}');
            print('   📋 Data Content: ${result.faceIDMessage!.data}');
          } else {
            print('   ⚠️ No server response data in faceIDMessage.data');
          }
        }
      }
      
      // Auto-close camera on Android when response is received
      if (Platform.isAndroid) {
        print('🤖 Android: Auto-closing liveness camera after receiving response');
        try {
          LivenessFlutter.cancelFaceRecognition();
        } catch (e) {
          print('⚠️ Failed to close camera: $e');
        }
      }
      
      print('============================================\n');
      _onActiveLivenessResult?.call(result);
    });

    // Active Liveness Failure Callback
    LivenessFlutter.setOnActiveLivenessFailureCallback((error) {
      print('\n🎭 ========== ACTIVE LIVENESS FAILURE ==========');
      print('❌ Active Liveness Error Code: ${error.code}');
      print('💬 Active Liveness Error Message: "${error.message}"');
      
      // Auto-close camera on Android when error occurs
      if (Platform.isAndroid) {
        print('🤖 Android: Auto-closing liveness camera after error');
        try {
          LivenessFlutter.cancelFaceRecognition();
        } catch (e) {
          print('⚠️ Failed to close camera: $e');
        }
      }
      
      print('==============================================\n');
      _onActiveLivenessFailure?.call(error);
    });
  }
  
  /// Setup photo and selfie callbacks
  void _setupPhotoCallbacks() {
    // Photo Taken Callback
    LivenessFlutter.setOnPhotoTakenCallback(() {
      print('\n📸 ========== PHOTO TAKEN ==========');
      print('📷 Photo captured during liveness process');
      print('⏰ Time: ${DateTime.now()}');
      print('==================================\n');
      _onPhotoTaken?.call();
    });

    // Selfie Taken Callback
    LivenessFlutter.setOnSelfieTakenCallback((base64Image) {
      print('\n🤳 ========== SELFIE TAKEN EVENT FIRED ==========');
      print('📦 Base64 image length: ${base64Image.length} characters');
      print('✅ Selfie captured and stored successfully');
      print('===================================\n');
      _onSelfieTaken?.call(base64Image);
    });
  }
  
  /// Clear all callbacks
  void clearAllCallbacks() {
    // Note: LivenessFlutter doesn't provide a method to clear individual callbacks,
    // so we just clear our internal references
    _onResult = null;
    _onFailure = null;
    _onPhotoTaken = null;
    _onSelfieTaken = null;
    _onActiveLivenessResult = null;
    _onActiveLivenessFailure = null;
    print('🔄 All liveness callbacks cleared');
  }
}
