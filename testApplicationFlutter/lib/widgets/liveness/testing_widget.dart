import 'package:flutter/material.dart';

/// Widget that handles liveness testing controls and buttons
class LivenessTestingWidget extends StatelessWidget {
  final bool isLoading;
  final bool ocrCompleted;
  final bool userRegistered;
  final String selectedOperation;
  final VoidCallback onTestFaceRegistration;
  final VoidCallback onTestFaceAuthentication;
  final VoidCallback onTestActiveLiveness;
  final VoidCallback onTestHybridLiveness;
  final VoidCallback onCancelRecognition;

  const LivenessTestingWidget({
    super.key,
    required this.isLoading,
    required this.ocrCompleted,
    required this.userRegistered,
    required this.selectedOperation,
    required this.onTestFaceRegistration,
    required this.onTestFaceAuthentication,
    required this.onTestActiveLiveness,
    required this.onTestHybridLiveness,
    required this.onCancelRecognition,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Face Recognition & Liveness Testing',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: (isLoading || !ocrCompleted) ? null : onTestFaceRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: ocrCompleted ? Colors.green : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(ocrCompleted 
                  ? 'Test Face Registration' 
                  : 'OCR Required - Face Registration'),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: (isLoading || !ocrCompleted || !userRegistered) ? null : onTestFaceAuthentication,
              style: ElevatedButton.styleFrom(
                backgroundColor: (ocrCompleted && userRegistered) ? Colors.blue : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(isLoading ? "Processing..." : 
                  !ocrCompleted ? "OCR Required - Face Authentication" : 
                  !userRegistered ? "Registration Required - Face Authentication" : 
                  "Test Face Authentication"),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: (isLoading || !ocrCompleted || (selectedOperation == 'authentication' && !userRegistered)) ? null : onTestActiveLiveness,
              style: ElevatedButton.styleFrom(
                backgroundColor: (ocrCompleted && (selectedOperation == 'registration' || userRegistered)) ? Colors.purple : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(
                isLoading ? "Processing..." : 
                !ocrCompleted ? "OCR Required - Active Liveness" : 
                selectedOperation == 'authentication' && !userRegistered ? "Registration Required - Active Liveness" : 
                "🎭 Test Active Liveness ($selectedOperation)"
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: (isLoading || !ocrCompleted || (selectedOperation == 'authentication' && !userRegistered)) ? null : onTestHybridLiveness,
              style: ElevatedButton.styleFrom(
                backgroundColor: (ocrCompleted && (selectedOperation == 'registration' || userRegistered)) ? Colors.orange : Colors.grey.shade400,
                foregroundColor: Colors.white,
              ),
              child: Text(
                isLoading ? "Processing..." : 
                !ocrCompleted ? "OCR Required - Hybrid Liveness" : 
                selectedOperation == 'authentication' && !userRegistered ? "Registration Required - Hybrid Liveness" : 
                "🔄 Test Hybrid Liveness ($selectedOperation)"
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton(
              onPressed: isLoading ? onCancelRecognition : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Recognition'),
            ),
          ],
        ),
      ),
    );
  }
}
