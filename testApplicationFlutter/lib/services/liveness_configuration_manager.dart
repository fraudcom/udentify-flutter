import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:liveness_flutter/liveness_flutter.dart';
import '../models/app_constants.dart';

/// Manages liveness configuration, credentials, and UI settings
class LivenessConfigurationManager {
  static const String _serverUrl = AppConstants.serverUrl;
  
  // Current configuration state
  UISettings? _currentUIConfig;
  String _currentTransactionID = '';
  
  // Getters
  String get currentTransactionID => _currentTransactionID;
  UISettings? get currentUIConfig => _currentUIConfig;
  
  /// Configure transparent background UI settings
  Future<void> configureTransparentBackground() async {
    print('\n🎨 ========== CONFIGURING UI SETTINGS ==========');

    // Configure UI settings
    final uiSettings = UISettings(
      colors: UIColors(
        titleColor: "#FFFFFF",
        titleBG: "#844EE3",
        buttonErrorColor: "#FF3B30",
        buttonSuccessColor: "#4CD964", 
        buttonColor: "#844EE3",
        buttonTextColor: "#FFFFFF",
        buttonErrorTextColor: "#FFFFFF",
        buttonSuccessTextColor: "#FFFFFF",
        buttonBackColor: "#000000",
        footerTextColor: "#FFFFFF",
        checkmarkTintColor: "#FFFFFF",
        backgroundColor: "#844EE3",
      ),
    );

    print('🎨 UI Settings to apply:');
    print('   🌈 Background Color: #844EE3');
    print('   📝 Title Color: #FFFFFF');
    print('   🔘 Button Color: #844EE3');

    try {
      print('🚀 Applying UI settings...');
      await LivenessFlutter.configureUISettings(uiSettings);
      _currentUIConfig = uiSettings;
      print('✅ UI settings configured successfully');
    } catch (e) {
      print('❌ Failed to configure UI settings: $e');
      rethrow;
    }

    // Configure localization
    await _configureLocalization();
    print('=============================================\n');
  }
  
  /// Configure localization settings
  Future<void> _configureLocalization() async {
    print('\n🌍 ========== CONFIGURING LOCALIZATION ==========');
    try {
      print('🚀 Setting up English localization...');
      await LivenessFlutter.setLocalization(
        languageCode: 'en',
        customStrings: {
          // Active Liveness specific strings
          'udentifyface_active_liveness_footer_button_text_recording': 'Recording...',
          'udentifyface_active_liveness_footer_button_text_processing': 'Processing...',
          'udentifyface_active_liveness_footer_button_text_default': 'Center your face',
          'udentifyface_active_liveness_footer_button_text_result': 'Next Step',
          'udentifyface_active_liveness_footer_label_text_processing': 'Performing active \nPlease wait...',

          // Gesture instructions
          'udentifyface_gesture_text_move_head_to_left': 'Turn Left',
          'udentifyface_gesture_text_move_head_to_right': 'Turn Right',
          'udentifyface_gesture_text_move_head_to_up': 'Tilt Up',
          'udentifyface_gesture_text_move_head_to_down': 'Tilt Down',
          'udentifyface_gesture_text_blink_once': 'Blink once',
          'udentifyface_gesture_text_blink_twice': 'Blink twice',
          'udentifyface_gesture_text_blink_thrice': 'Blink 3 times',
          'udentifyface_gesture_text_smile': 'Smile',

          // General strings
          'udentifyface_header_text': 'Take Selfie',
          'udentifyface_footer_button_text_default': 'Take Selfie',
          'udentifyface_footer_button_text_progressing': 'Liveness Check',
          'udentifyface_footer_button_text_result': 'Liveness',

          // Face detection messages
          'udentifyface_message_face_too_big': 'Move Back',
          'udentifyface_message_face_too_small': 'Move Closer',
          'udentifyface_message_face_not_found': 'Face not found',
          'udentifyface_message_too_many_faces': 'Too many faces',
          'udentifyface_message_face_angled': 'Face to Camera',
          'udentifyface_message_head_angled': 'Face to Camera',
          'udentifyface_message_face_off_center': 'Center your face',
          'udentifyface_message_mask_detected': 'Remove Mask',
        },
      );
      print('✅ Localization configured successfully');
    } catch (e) {
      print('❌ Failed to configure localization: $e');
      rethrow;
    }
  }
  
  /// Build credentials for liveness operations
  Future<FaceRecognizerCredentials?> buildCredentials(String userID, {String? existingTransactionID}) async {
    String? transactionId;
    
    // If we have an existing transaction ID, use it
    if (existingTransactionID != null && existingTransactionID.isNotEmpty) {
      print('✅ Using existing transaction ID for liveness: $existingTransactionID');
      transactionId = existingTransactionID;
      _currentTransactionID = transactionId;
    } else {
      // Get transaction ID from API
      transactionId = await getTransactionIdFromServer();
      if (transactionId == null) {
        return null;
      }
      _currentTransactionID = transactionId;
    }

    return FaceRecognizerCredentials(
      serverURL: _serverUrl,
      transactionID: transactionId,
      userID: userID,
      // Use optimal defaults for testing
      autoTake: true,
      errorDelay: 0.10,
      successDelay: 0.75,
      runInBackground: false,
      blinkDetectionEnabled: false,
      requestTimeout: 10,
      eyesOpenThreshold: 0.75,
      maskConfidence: 0.95,
      activeLivenessAutoNextEnabled: true,
    );
  }
  
  /// Get transaction ID from server
  Future<String?> getTransactionIdFromServer() async {
    try {
      print('🎯 Getting transaction ID from server...');
      final url = '$_serverUrl/transaction/start';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Api-Key': AppConstants.apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'request': "",
          'qrGenerate': true,
          'qrSize': 200,
          'moduleList': [
            "OCR", 
            "OCR_HOLOGRAM", 
            AppConstants.moduleFaceRegistration,
            AppConstants.moduleFaceAuthentication,
            AppConstants.moduleFaceLiveness,
            AppConstants.moduleActiveLiveness
          ]
        }),
      );

      print('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Full Response Data: $data');
        
        final transactionId = data['transactionId'] ?? data['transaction_id'] ?? data['id'] ?? data['txId'] ?? 
                              (data['response'] != null ? data['response']['id'] : null);
        
        if (transactionId != null) {
          print('✅ Transaction ID received from server: $transactionId');
          return transactionId;
        }
      }
      
      print('❌ Failed to get transaction ID from server');
      return null;
    } catch (error) {
      print('❌ Error getting transaction ID from server: $error');
      return null;
    }
  }
  
  /// Apply UI settings
  Future<void> applyUISettings(UISettings uiSettings) async {
    try {
      await LivenessFlutter.configureUISettings(uiSettings);
      _currentUIConfig = uiSettings;
      print('✅ UI settings applied successfully');
    } catch (e) {
      print('❌ Failed to apply UI settings: $e');
      rethrow;
    }
  }
  
  /// Check permissions
  Future<FaceRecognitionPermissionStatus?> checkPermissions() async {
    try {
      print('🔄 Checking liveness permissions...');
      final status = await LivenessFlutter.checkPermissions();
      print('✅ Permissions Status: $status');
      return status;
    } catch (error) {
      print('❌ Permission Check Error: $error');
      return null;
    }
  }
  
  /// Request permissions
  Future<FaceRecognitionPermissionStatus?> requestPermissions() async {
    try {
      print('🔄 Requesting permissions...');
      final status = await LivenessFlutter.requestPermissions();
      print('✅ Permissions Requested: $status');
      return status;
    } catch (error) {
      print('❌ Permission Request Error: $error');
      return null;
    }
  }
  
  /// Cancel face recognition
  Future<void> cancelFaceRecognition() async {
    try {
      await LivenessFlutter.cancelFaceRecognition();
      print('✅ Face recognition cancelled');
    } catch (e) {
      print('❌ Error canceling face recognition: $e');
      rethrow;
    }
  }
}
