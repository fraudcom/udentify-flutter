import 'package:flutter/material.dart';

/// Widget that displays OCR prerequisite status and controls
class OCRPrerequisiteWidget extends StatelessWidget {
  final bool ocrCompleted;
  final String ocrStatus;
  final bool isLoading;
  final VoidCallback onPerformOCR;

  const OCRPrerequisiteWidget({
    super.key,
    required this.ocrCompleted,
    required this.ocrStatus,
    required this.isLoading,
    required this.onPerformOCR,
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
              'OCR Prerequisite',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ocrCompleted ? Colors.green.shade50 : Colors.orange.shade50,
                border: Border.all(
                  color: ocrCompleted ? Colors.green.shade200 : Colors.orange.shade200,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    ocrCompleted ? Icons.check_circle : Icons.warning,
                    color: ocrCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ocrCompleted ? '✅ OCR Completed' : '⏳ OCR Required',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: ocrCompleted ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ocrCompleted
                              ? 'OCR scanning has been completed. Liveness operations are now available.'
                              : 'OCR scanning must be completed before liveness operations can proceed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: ocrCompleted ? Colors.green.shade600 : Colors.orange.shade600,
                          ),
                        ),
                        if (ocrStatus != "Ready") ...[
                          const SizedBox(height: 4),
                          Text(
                            'Status: $ocrStatus',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: ocrCompleted ? Colors.green.shade600 : Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!ocrCompleted) ...[
              ElevatedButton.icon(
                onPressed: isLoading ? null : onPerformOCR,
                icon: const Icon(Icons.document_scanner),
                label: Text(isLoading ? "Scanning..." : "Perform OCR First"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
