import 'package:flutter/material.dart';
import 'package:liveness_flutter/liveness_flutter.dart' hide TextStyle;
import '../../models/liveness_state.dart';

/// Widget that displays a quick status summary of the liveness session
class LivenessStatusSummaryWidget extends StatelessWidget {
  final LivenessState state;
  final bool ocrCompleted;
  final bool userRegistered;
  final String? capturedSelfieImage;
  final bool isOCRInProgress;
  final bool isLivenessInProgress;

  const LivenessStatusSummaryWidget({
    super.key,
    required this.state,
    required this.ocrCompleted,
    required this.userRegistered,
    this.capturedSelfieImage,
    this.isOCRInProgress = false,
    this.isLivenessInProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasResults = state.hasResults;
    final allSuccessful = state.allSuccessful;
    
    return Card(
      color: hasResults 
          ? (allSuccessful ? Colors.green.shade50 : Colors.orange.shade50)
          : Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasResults 
                      ? (allSuccessful ? Icons.check_circle : Icons.warning)
                      : Icons.info,
                  color: hasResults 
                      ? (allSuccessful ? Colors.green : Colors.orange)
                      : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '📊 Session Status Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildOCRStatusRow(),
            _buildStatusRow('User Registered', userRegistered),
            if (state.faceRecognitionResult != null)
              _buildStatusRow('Face Recognition', state.faceRecognitionResult!.status == FaceRecognitionStatus.success),
            if (state.livenessResult != null)
              _buildStatusRow('Liveness Detection', state.livenessResult!.status == FaceRecognitionStatus.success),
            if (state.selfieResult != null)
              _buildStatusRow('Selfie Processing', state.selfieResult!.status == FaceRecognitionStatus.success),
            if (capturedSelfieImage != null)
              _buildStatusRow('Selfie Captured', true),
            
            const SizedBox(height: 8),
            _buildGuidanceMessage(),
          ],
        ),
      ),
    );
  }

  /// Build OCR status row with enhanced feedback
  Widget _buildOCRStatusRow() {
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (isOCRInProgress) {
      statusText = 'OCR: Processing... 🔄';
      statusColor = Colors.orange;
      statusIcon = Icons.hourglass_empty;
    } else if (ocrCompleted) {
      statusText = 'OCR: Completed Successfully ✅';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else {
      statusText = 'OCR: Required for Liveness Operations';
      statusColor = Colors.blue;
      statusIcon = Icons.document_scanner;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 13,
                color: _getShade800(statusColor),
                fontWeight: ocrCompleted ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (isOCRInProgress) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build guidance message based on current state
  Widget _buildGuidanceMessage() {
    String message;
    Color messageColor;
    IconData messageIcon;
    
    if (ocrCompleted && !state.hasResults) {
      message = '🎉 OCR completed! You can now proceed with Liveness operations.';
      messageColor = Colors.green;
      messageIcon = Icons.arrow_forward;
    } else if (ocrCompleted && state.hasResults && state.allSuccessful) {
      message = '✨ All operations completed successfully! Session is ready.';
      messageColor = Colors.green;
      messageIcon = Icons.celebration;
    } else if (isOCRInProgress || isLivenessInProgress) {
      message = '⏳ Processing... Please wait for the operation to complete.';
      messageColor = Colors.orange;
      messageIcon = Icons.pending;
    } else if (!ocrCompleted) {
      message = '📋 Start with OCR to unlock Liveness operations.';
      messageColor = Colors.blue;
      messageIcon = Icons.start;
    } else if (state.hasResults && !state.allSuccessful) {
      message = '⚠️ Some operations failed. Check results above and retry if needed.';
      messageColor = Colors.orange;
      messageIcon = Icons.warning;
    } else {
      message = '💡 Complete the operations above to see results here.';
      messageColor = Colors.blue;
      messageIcon = Icons.info;
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getShade50(messageColor),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getShade200(messageColor)),
      ),
      child: Row(
        children: [
          Icon(messageIcon, size: 16, color: _getShade700(messageColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: _getShade700(messageColor),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isSuccess) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 16,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${isSuccess ? 'Success' : 'Pending/Failed'}',
            style: TextStyle(
              fontSize: 13,
              color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Helper methods to get color shades safely
  Color _getShade50(Color color) {
    if (color == Colors.green) return Colors.green.shade50;
    if (color == Colors.orange) return Colors.orange.shade50;
    if (color == Colors.blue) return Colors.blue.shade50;
    if (color == Colors.red) return Colors.red.shade50;
    return color.withOpacity(0.1);
  }
  
  Color _getShade200(Color color) {
    if (color == Colors.green) return Colors.green.shade200;
    if (color == Colors.orange) return Colors.orange.shade200;
    if (color == Colors.blue) return Colors.blue.shade200;
    if (color == Colors.red) return Colors.red.shade200;
    return color.withOpacity(0.3);
  }
  
  Color _getShade700(Color color) {
    if (color == Colors.green) return Colors.green.shade700;
    if (color == Colors.orange) return Colors.orange.shade700;
    if (color == Colors.blue) return Colors.blue.shade700;
    if (color == Colors.red) return Colors.red.shade700;
    return color.withOpacity(0.8);
  }
  
  Color _getShade800(Color color) {
    if (color == Colors.green) return Colors.green.shade800;
    if (color == Colors.orange) return Colors.orange.shade800;
    if (color == Colors.blue) return Colors.blue.shade800;
    if (color == Colors.red) return Colors.red.shade800;
    return color.withOpacity(0.9);
  }
}
