import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/app_constants.dart';

class ApiUtils {
  static const String serverUrl = AppConstants.serverUrl;
  static const String apiKey = AppConstants.apiKey;

  /// Get transaction ID for face registration and liveness
  static Future<String?> getFaceRegistrationAndLivenessTransactionId() async {
    return getTransactionId(AppConstants.faceRegistrationAndLivenessModules);
  }

  static Future<String?> getVideoCallTransactionId({
    int channelId = 252,
    String severity = "NORMAL",
  }) async {
    try {
      final url = '$serverUrl/transaction/start';
      final requestBody = {
        'moduleList': [
          'OCR',
          'FACE_REGISTRATION',
          'FACE_LIVENESS',
          'VIDEO_CALL'
        ],
        'transactionSource': 1,
        'channelId': channelId,
        'severity': severity,
      };

      print('🔍 VIDEO CALL API REQUEST DEBUG:');
      print('   URL: $url');
      print(
          '   Headers: X-Api-Key: ${apiKey.substring(0, 8)}..., Content-Type: application/json');
      print('   Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Api-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 VIDEO CALL API RESPONSE DEBUG:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['response'] != null) {
          final transactionId = data['response']['id'];
          print(
              '✅ Video Call Transaction ID obtained: ${transactionId.substring(0, 20)}...');
          return transactionId;
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting video call transaction ID: $e');
      return null;
    }
  }

  static Future<String?> getTransactionId(List<String> moduleList) async {
    try {
      final url = '$serverUrl/transaction/start';
      final requestBody = {'moduleList': moduleList};

      print('🔍 API REQUEST DEBUG:');
      print('   URL: $url');
      print(
          '   Headers: X-Api-Key: ${apiKey.substring(0, 8)}..., Content-Type: application/json');
      print('   Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'X-Api-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('📡 API RESPONSE DEBUG:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['response'] != null) {
          final transactionId = data['response']['id'];
          print(
              '✅ Transaction ID obtained: ${transactionId.substring(0, 20)}...');
          return transactionId;
        } else {
          throw Exception(
              'API returned error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting transaction ID: $e');
      return null;
    }
  }
}
