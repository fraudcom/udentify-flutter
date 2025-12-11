import 'package:flutter/material.dart';

/// 🤳 Selfie Capture & Manual Processing Widget
/// 
/// This widget matches the exact logic and structure from React Native LivenessTab.tsx
/// Provides two-phase selfie workflow: capture first, then manually process
class SelfieTestingWidget extends StatelessWidget {
  // Core state properties (matching React Native state)
  final bool isLoading;
  final bool isSelfieCapturing;
  final bool ocrCompleted;
  final bool userRegistered;
  final String selfieOperation;
  final String? capturedSelfieImage;
  final String selectedUserID;
  
  // Callback functions (matching React Native functions)
  final Function(String) onSelfieOperationChanged;
  final VoidCallback onCaptureSelfie;
  final VoidCallback onProcessSelfie;
  final VoidCallback onClearSelfie;
  final VoidCallback? onPreviewSelfie;
  final VoidCallback? onRegisterFirst;
  final VoidCallback? onSwitchToRegistration;

  const SelfieTestingWidget({
    super.key,
    required this.isLoading,
    required this.isSelfieCapturing,
    required this.ocrCompleted,
    required this.userRegistered,
    required this.selfieOperation,
    required this.selectedUserID,
    this.capturedSelfieImage,
    required this.onSelfieOperationChanged,
    required this.onCaptureSelfie,
    required this.onProcessSelfie,
    required this.onClearSelfie,
    this.onPreviewSelfie,
    this.onRegisterFirst,
    this.onSwitchToRegistration,
  });

  @override
  Widget build(BuildContext context) {
    // State calculations (matching React Native logic)
    final bool isAuthenticationMode = selfieOperation == 'authentication';
    final bool canProceedWithAuthentication = !isAuthenticationMode || userRegistered;
    final bool hasCapturedSelfie = capturedSelfieImage != null && capturedSelfieImage!.isNotEmpty;
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title (matching React Native styles.sectionTitle)
            Text(
              '🤳 Selfie Capture & Manual Processing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // How Selfie Works Info Box (matching React Native styles.infoContainer)
            _buildHowItWorksSection(context),
            const SizedBox(height: 16),
            
            // Selfie Operation Configuration (matching React Native OptionPicker)
            _buildOperationTypeSelector(context),
            const SizedBox(height: 16),

            // Selfie Status Display (matching React Native styles.statusContainer)
            _buildSelfieStatusDisplay(context, hasCapturedSelfie),
            const SizedBox(height: 16),

            // Selfie Action Buttons (matching React Native button logic)
            _buildActionButtons(context, canProceedWithAuthentication, hasCapturedSelfie),

            // Selfie Operation Warnings (matching React Native warning logic)
            ..._buildWarningMessages(context, isAuthenticationMode),

            // Selfie Capturing Progress Indicator (matching React Native)
            if (isSelfieCapturing) ...[
              const SizedBox(height: 16),
              _buildCapturingIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

  /// How Selfie Works Information Section (matches React Native infoContainer)
  Widget _buildHowItWorksSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: const Border(
          left: BorderSide(color: Colors.blue, width: 4),
        ),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                const TextSpan(text: '📝 '),
                TextSpan(
                  text: 'How Selfie Works:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
              children: const [
                TextSpan(text: '1. 📸 '),
                TextSpan(text: 'Capture:', style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: ' Opens camera, takes photo, closes camera\n'),
                TextSpan(text: '2. 📋 '),
                TextSpan(text: 'Review:', style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: ' You can review the captured selfie\n'),
                TextSpan(text: '3. 🔄 '),
                TextSpan(text: 'Process:', style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: ' Manually trigger face recognition API when ready\n'),
                TextSpan(text: '4. ⚡ '),
                TextSpan(text: 'Control:', style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: ' Full control over timing and operation type'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Operation Type Selector (matches React Native OptionPicker)
  Widget _buildOperationTypeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selfie Operation Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selfieOperation,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'registration',
                  child: Text('Registration'),
                ),
                DropdownMenuItem(
                  value: 'authentication',
                  child: Text('Authentication'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSelfieOperationChanged(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Selfie Status Display (matches React Native statusContainer)
  Widget _buildSelfieStatusDisplay(BuildContext context, bool hasCapturedSelfie) {
    final MaterialColor statusColor = hasCapturedSelfie ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.shade50,
        border: Border.all(color: statusColor.shade200, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasCapturedSelfie ? Icons.check_circle_rounded : Icons.photo_camera_rounded,
            color: statusColor.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCapturedSelfie ? '✅ Selfie Captured' : '📸 No Selfie Captured',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCapturedSelfie
                      ? 'Selfie is ready for $selfieOperation processing. Image size: ${capturedSelfieImage!.length} characters.'
                      : 'Capture a selfie first, then you can process it manually for face recognition.',
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Action Buttons Section (matches React Native button logic exactly)
  Widget _buildActionButtons(BuildContext context, bool canProceedWithAuthentication, bool hasCapturedSelfie) {
    return Column(
      children: [
        // Capture Selfie Button (matching React Native color and disabled logic)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _shouldEnableCaptureButton(canProceedWithAuthentication) ? onCaptureSelfie : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _getCaptureButtonColor(canProceedWithAuthentication),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _getCaptureButtonText(canProceedWithAuthentication),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Process Selfie Button (only show if selfie is captured, matching React Native)
        if (hasCapturedSelfie) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _shouldEnableProcessButton(canProceedWithAuthentication) ? onProcessSelfie : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getProcessButtonColor(canProceedWithAuthentication),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _getProcessButtonText(canProceedWithAuthentication),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Preview and Clear buttons row (matching React Native layout)
          const SizedBox(height: 12),
          Row(
            children: [
              // Preview Selfie Button (matching React Native #FFC107 color)
              if (onPreviewSelfie != null)
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isLoading || isSelfieCapturing) ? null : onPreviewSelfie,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '📷 Preview Selfie',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              
              if (onPreviewSelfie != null) const SizedBox(width: 12),
              
              // Clear Selfie Button (matching React Native #f44336 color)
              Expanded(
                child: ElevatedButton(
                  onPressed: (isLoading || isSelfieCapturing) ? null : onClearSelfie,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFf44336),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '🗑️ Clear Selfie',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Warning Messages Section (matches React Native warning logic exactly)
  List<Widget> _buildWarningMessages(BuildContext context, bool isAuthenticationMode) {
    final List<Widget> warnings = [];

    // OCR Required Warning (matching React Native styles)
    if (!ocrCompleted) {
      warnings.add(const SizedBox(height: 16));
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3E0), // #fff3e0
            border: Border(
              left: BorderSide(color: Color(0xFFFF9800), width: 4), // #ff9800
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange.shade700, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ OCR scanning must be completed first before selfie capture',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFf57c00), // #f57c00
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Authentication Registration Warning (matching React Native styles)
    if (ocrCompleted && isAuthenticationMode && !userRegistered) {
      warnings.add(const SizedBox(height: 12));
      warnings.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEAA7), // #ffeaa7
            border: Border(
              left: BorderSide(color: Color(0xFFfdcb6e), width: 4), // #fdcb6e
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_rounded, color: const Color(0xFFe17055), size: 18), // #e17055
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔐 Selfie Authentication requires prior Registration',
                      style: TextStyle(
                        fontSize: 13,
                        color: const Color(0xFFe17055), // #e17055
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  'Complete "Test Face Registration" first, or switch to Registration mode for selfie.',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF636e72), // #636e72
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return warnings;
  }

  /// Selfie Capturing Progress Indicator (matches React Native)
  Widget _buildCapturingIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFFe3f2fd), // #e3f2fd
        border: Border(
          left: BorderSide(color: Color(0xFF2196f3), width: 4), // #2196f3
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '📸 Selfie capture in progress... The camera will open and close automatically after taking the photo.',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFF1976d2), // #1976d2
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Button State Logic (matches React Native disabled conditions exactly)
  
  bool _shouldEnableCaptureButton(bool canProceedWithAuthentication) {
    return !isSelfieCapturing && !isLoading && ocrCompleted && canProceedWithAuthentication;
  }

  bool _shouldEnableProcessButton(bool canProceedWithAuthentication) {
    return !isLoading && !isSelfieCapturing && canProceedWithAuthentication;
  }

  Color _getCaptureButtonColor(bool canProceedWithAuthentication) {
    if (ocrCompleted && canProceedWithAuthentication) {
      return const Color(0xFFFF6B35); // #FF6B35 - Orange color matching React Native
    }
    return Colors.grey.shade400;
  }

  Color _getProcessButtonColor(bool canProceedWithAuthentication) {
    if (canProceedWithAuthentication) {
      return const Color(0xFF4CAF50); // #4CAF50 - Green color matching React Native
    }
    return Colors.grey.shade400;
  }

  String _getCaptureButtonText(bool canProceedWithAuthentication) {
    if (isSelfieCapturing) {
      return "Capturing Selfie...";
    } else if (!ocrCompleted) {
      return "OCR Required - Capture Selfie";
    } else if (selfieOperation == 'authentication' && !userRegistered) {
      return "Registration Required - Capture Selfie";
    } else {
      return "📸 Capture Selfie";
    }
  }

  String _getProcessButtonText(bool canProceedWithAuthentication) {
    if (isLoading) {
      return "Processing Selfie...";
    } else if (selfieOperation == 'authentication' && !userRegistered) {
      return "Registration Required - Process Selfie";
    } else {
      return "🔄 Process Selfie ($selfieOperation)";
    }
  }
}
