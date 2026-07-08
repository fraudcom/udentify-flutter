import 'dart:convert';
import 'dart:io';
import 'package:liveness_flutter/liveness_flutter.dart';

/// Utility class for formatting liveness results for display
class LivenessResultFormatter {
  /// Format result data for display
  static String formatResultData(FaceRecognitionResult result) {
    try {
      print('🔍 Formatting result data: ${result.runtimeType}');
      
      // Check if we have raw server data in faceIDMessage.data
      if (result.faceIDMessage?.data != null) {
        print('📡 Found raw server response data, displaying directly');
        const encoder = JsonEncoder.withIndent('  ');
        final formattedJson = encoder.convert(result.faceIDMessage!.data);
        print('✅ Successfully formatted raw server data as JSON');
        return formattedJson;
      }
      
      // Fallback to original formatting
      final Map<String, dynamic> resultMap = result.toMap();
      const encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(resultMap);
      
      print('✅ Successfully formatted result data as JSON');
      return formattedJson;
    } catch (e) {
      print('⚠️ Formatting failed with error: $e');
      
      // If formatting fails, try to extract meaningful information from the result object
      try {
        final resultDetails = <String, dynamic>{};
        
        // Extract basic properties
        resultDetails['status'] = result.status.name;
        resultDetails['platform'] = Platform.isAndroid ? 'Android' : 'iOS';
        resultDetails['timestamp'] = DateTime.now().toIso8601String();
        
        // Extract faceIDMessage if available
        if (result.faceIDMessage != null) {
          final faceIDMsg = result.faceIDMessage!;
          resultDetails['faceIDMessage'] = {
            'success': faceIDMsg.success,
            'message': faceIDMsg.message,
            'errorCode': faceIDMsg.errorCode,
            'isFailed': faceIDMsg.isFailed,
          };
          
          // Add detailed server data if available (from Android native layer)
          if (faceIDMsg.data != null) {
            resultDetails['serverResponseData'] = faceIDMsg.data;
            print('📡 Server response data found: ${faceIDMsg.data}');
          }
          
          // Add faceIDResult if available
          if (faceIDMsg.faceIDResult != null) {
            final faceIDResult = faceIDMsg.faceIDResult!;
            resultDetails['faceIDResult'] = {
              'verified': faceIDResult.verified,
              'matchScore': faceIDResult.matchScore,
              'userID': faceIDResult.userID,
              'transactionID': faceIDResult.transactionID,
              'method': faceIDResult.method,
              'description': faceIDResult.description,
            };
          }
        }
        
        // Extract error if available
        if (result.error != null) {
          resultDetails['error'] = {
            'code': result.error!.code,
            'message': result.error!.message,
            'details': result.error!.details,
          };
        }
        
        // Extract base64Image info if available
        if (result.base64Image != null) {
          resultDetails['base64Image'] = {
            'available': true,
            'length': result.base64Image!.length,
            'preview': result.base64Image!.length > 100 
                ? '${result.base64Image!.substring(0, 100)}...' 
                : result.base64Image!,
          };
        }
        
        const encoder = JsonEncoder.withIndent('  ');
        final formattedResult = encoder.convert(resultDetails);
        
        print('✅ Successfully extracted and formatted result data manually');
        return formattedResult;
        
      } catch (extractionError) {
        print('❌ Manual extraction also failed: $extractionError');
        
        // Last resort: return a safe string representation
        final safeString = '''
Result Display Error Recovery
============================
Status: ${result.status.name}
Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}
Timestamp: ${DateTime.now().toIso8601String()}

Raw String Representation:
${result.toString()}

Error Details:
- Formatting Error: $e
- Extraction Error: $extractionError

Note: This indicates a compatibility issue with the result object.
The operation may have succeeded, but result formatting failed.
''';
        
        print('🚨 Using fallback string representation');
        return safeString;
      }
    }
  }
  
  /// Extract user registration information from result
  static Map<String, dynamic>? extractRegistrationInfo(FaceRecognitionResult result) {
    try {
      if (result.faceIDMessage?.success == true && result.faceIDMessage?.faceIDResult != null) {
        final faceIDResult = result.faceIDMessage!.faceIDResult!;
        
        if (faceIDResult.verified && faceIDResult.userID != null && faceIDResult.transactionID != null) {
          return {
            'userID': faceIDResult.userID,
            'transactionID': faceIDResult.transactionID,
            'method': faceIDResult.method,
            'verified': faceIDResult.verified,
            'matchScore': faceIDResult.matchScore,
          };
        }
      }
      return null;
    } catch (e) {
      print('❌ Failed to extract registration info: $e');
      return null;
    }
  }
  
  /// Check if result indicates successful registration
  static bool isSuccessfulRegistration(FaceRecognitionResult result) {
    if (result.faceIDMessage?.success == true) {
      // Check for registration-specific indicators
      final message = result.faceIDMessage?.message?.toLowerCase() ?? '';
      return message.contains('registration') || message.contains('completed successfully');
    }
    return false;
  }
  
  /// Check if result indicates successful authentication
  static bool isSuccessfulAuthentication(FaceRecognitionResult result) {
    if (result.faceIDMessage?.success == true && result.faceIDMessage?.faceIDResult != null) {
      return result.faceIDMessage!.faceIDResult!.verified;
    }
    return false;
  }
  
  /// Get human-readable status message
  static String getStatusMessage(FaceRecognitionResult result) {
    switch (result.status) {
      case FaceRecognitionStatus.success:
        if (result.faceIDMessage?.success == true) {
          return result.faceIDMessage?.message ?? 'Operation completed successfully';
        } else {
          return 'Operation completed with warnings';
        }
      case FaceRecognitionStatus.failure:
        return result.error?.message ?? 'Operation failed';
      // case FaceRecognitionStatus.cancelled:
      //   return 'Operation was cancelled by user';
      default:
        return 'Unknown status';
    }
  }
}
