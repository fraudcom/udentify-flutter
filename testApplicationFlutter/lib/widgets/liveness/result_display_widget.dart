import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:liveness_flutter/liveness_flutter.dart' hide TextStyle;
import 'package:ocr_flutter/ocr_flutter.dart';
import '../../utils/liveness_result_formatter.dart';

/// Widget that displays various result sections
class LivenessResultDisplayWidget extends StatelessWidget {
  final String? currentTransactionID;
  final OCRResponse? ocrResult;
  final FaceRecognitionResult? faceRecognitionResult;
  final FaceRecognitionResult? livenessResult;
  final FaceRecognitionResult? selfieResult;
  final String? displaySelfie;
  final String userID;
  final String selfieOperation;

  const LivenessResultDisplayWidget({
    super.key,
    this.currentTransactionID,
    this.ocrResult,
    this.faceRecognitionResult,
    this.livenessResult,
    this.selfieResult,
    this.displaySelfie,
    required this.userID,
    required this.selfieOperation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Transaction Section
        if (currentTransactionID != null && currentTransactionID!.isNotEmpty)
          _buildTransactionSection(context),
        
        if (currentTransactionID != null && currentTransactionID!.isNotEmpty)
          const SizedBox(height: 16),

        // OCR Results
        if (ocrResult != null) _buildOCRResultSection(context),
        if (ocrResult != null) const SizedBox(height: 16),

        // Face Recognition Results
        if (faceRecognitionResult != null) _buildFaceRecognitionResultSection(context),
        if (faceRecognitionResult != null) const SizedBox(height: 16),
        
        // Liveness Results
        if (livenessResult != null) _buildLivenessResultSection(context),
        if (livenessResult != null) const SizedBox(height: 16),

        // Captured Selfie Display
        if (displaySelfie != null) _buildCapturedSelfieSection(context),
        if (displaySelfie != null) const SizedBox(height: 16),

        // Selfie Processing Results
        if (selfieResult != null) _buildSelfieResultSection(context),
      ],
    );
  }

  Widget _buildTransactionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Transaction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ID: $currentTransactionID',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOCRResultSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OCR Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Response Type: ${ocrResult!.responseType}'),
            if (ocrResult!.responseType == 'idCard' &&
                ocrResult!.idCardResponse != null) ...[
              const SizedBox(height: 8),
              Text('Document Type: ${ocrResult!.idCardResponse!.documentType ?? 'N/A'}'),
              Text('First Name: ${ocrResult!.idCardResponse!.firstName ?? 'N/A'}'),
              Text('Last Name: ${ocrResult!.idCardResponse!.lastName ?? 'N/A'}'),
              Text('Identity No: ${ocrResult!.idCardResponse!.identityNo ?? 'N/A'}'),
              Text('Birth Date: ${ocrResult!.idCardResponse!.birthDate ?? 'N/A'}'),
              Text('Expiry Date: ${ocrResult!.idCardResponse!.expiryDate ?? 'N/A'}'),
              if (ocrResult!.idCardResponse!.faceImage != null)
                const Text('Face Image: Available (Base64)'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFaceRecognitionResultSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  faceRecognitionResult?.status == FaceRecognitionStatus.success 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: faceRecognitionResult?.status == FaceRecognitionStatus.success 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Face Recognition Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  LivenessResultFormatter.formatResultData(faceRecognitionResult!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivenessResultSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  livenessResult?.status == FaceRecognitionStatus.success 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: livenessResult?.status == FaceRecognitionStatus.success 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Liveness Detection Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  LivenessResultFormatter.formatResultData(livenessResult!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturedSelfieSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📸 Captured Selfie Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _decodeBase64Image(displaySelfie!),
                      width: 200,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 300,
                          color: Colors.grey.shade200,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Image size: ${displaySelfie!.length} characters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfieResultSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selfieResult?.status == FaceRecognitionStatus.success 
                      ? Icons.check_circle 
                      : Icons.error,
                  color: selfieResult?.status == FaceRecognitionStatus.success 
                      ? Colors.green 
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  '🤳 Selfie Processing Result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Operation: $selfieOperation | 👤 User: $userID',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This result shows the outcome of manually processing the captured selfie through the face recognition API.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  LivenessResultFormatter.formatResultData(selfieResult!),
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to safely decode base64 image data
  /// Handles data URL prefixes and cleans invalid characters
  Uint8List _decodeBase64Image(String base64String) {
    try {
      // Remove data URL prefix if present (e.g., "data:image/jpeg;base64,")
      String cleanBase64 = base64String;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      
      // Remove any whitespace and newlines
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      
      // Ensure proper padding
      while (cleanBase64.length % 4 != 0) {
        cleanBase64 += '=';
      }
      
      print('🔍 Decoding base64 image: ${cleanBase64.length} characters');
      return base64Decode(cleanBase64);
    } catch (e) {
      print('❌ Failed to decode base64 image: $e');
      print('📷 Base64 preview: ${base64String.substring(0, math.min(100, base64String.length))}...');
      
      // Return a 1x1 transparent pixel as fallback
      return base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
    }
  }
}
