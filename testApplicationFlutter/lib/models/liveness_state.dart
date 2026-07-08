import 'package:liveness_flutter/liveness_flutter.dart';
import 'package:ocr_flutter/ocr_flutter.dart';

/// Centralized state management for the liveness test page
class LivenessState {
  // Loading states
  bool isLoading = false;
  bool isSelfieCapturing = false;
  
  // Permission state
  FaceRecognitionPermissionStatus? permissionStatus;
  
  // Results
  FaceRecognitionResult? faceRecognitionResult;
  FaceRecognitionResult? livenessResult;
  FaceRecognitionResult? selfieResult;
  
  // Operation configuration
  String selectedOperation = 'registration'; // 'registration' or 'authentication'
  String selfieOperation = 'registration';
  
  // UI configuration
  UISettings? currentUIConfig;
  
  // Display state
  String? displaySelfie;
  
  /// Check if any results are available
  bool get hasResults => faceRecognitionResult != null || livenessResult != null || selfieResult != null;
  
  /// Check if all successful results
  bool get allSuccessful => 
      (faceRecognitionResult?.status == FaceRecognitionStatus.success || faceRecognitionResult == null) &&
      (livenessResult?.status == FaceRecognitionStatus.success || livenessResult == null) &&
      (selfieResult?.status == FaceRecognitionStatus.success || selfieResult == null);
  
  /// Check if permissions are granted
  bool get allPermissionsGranted => permissionStatus?.allGranted ?? false;
  
  /// Reset all results
  void resetAllResults() {
    faceRecognitionResult = null;
    livenessResult = null;
    selfieResult = null;
    displaySelfie = null;
  }
  
  /// Reset loading states
  void resetLoadingStates() {
    isLoading = false;
    isSelfieCapturing = false;
  }
  
  /// Copy state with new values
  LivenessState copyWith({
    bool? isLoading,
    bool? isSelfieCapturing,
    FaceRecognitionPermissionStatus? permissionStatus,
    FaceRecognitionResult? faceRecognitionResult,
    FaceRecognitionResult? livenessResult,
    FaceRecognitionResult? selfieResult,
    String? selectedOperation,
    String? selfieOperation,
    UISettings? currentUIConfig,
    String? displaySelfie,
  }) {
    final newState = LivenessState();
    newState.isLoading = isLoading ?? this.isLoading;
    newState.isSelfieCapturing = isSelfieCapturing ?? this.isSelfieCapturing;
    newState.permissionStatus = permissionStatus ?? this.permissionStatus;
    newState.faceRecognitionResult = faceRecognitionResult ?? this.faceRecognitionResult;
    newState.livenessResult = livenessResult ?? this.livenessResult;
    newState.selfieResult = selfieResult ?? this.selfieResult;
    newState.selectedOperation = selectedOperation ?? this.selectedOperation;
    newState.selfieOperation = selfieOperation ?? this.selfieOperation;
    newState.currentUIConfig = currentUIConfig ?? this.currentUIConfig;
    newState.displaySelfie = displaySelfie ?? this.displaySelfie;
    return newState;
  }
  
  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'isLoading': isLoading,
      'isSelfieCapturing': isSelfieCapturing,
      'hasPermissions': allPermissionsGranted,
      'selectedOperation': selectedOperation,
      'selfieOperation': selfieOperation,
      'hasResults': hasResults,
      'allSuccessful': allSuccessful,
      'faceRecognitionStatus': faceRecognitionResult?.status?.name,
      'livenessStatus': livenessResult?.status?.name,
      'selfieStatus': selfieResult?.status?.name,
      'hasSelfieImage': displaySelfie != null,
    };
  }
}
