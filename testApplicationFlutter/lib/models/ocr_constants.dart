class OCRConstants {
  static const String moduleOCR = "OCR";
  static const String moduleOCRHologram = "OCR_HOLOGRAM";
  static const String moduleDocumentLiveness = "DOCUMENT_LIVENESS";

  static const List<String> ocrModules = [moduleOCR];
  static const List<String> ocrAndHologramModules = [
    moduleOCR,
    moduleOCRHologram
  ];
  static const List<String> documentLivenessModules = [moduleDocumentLiveness];
  static const List<String> ocrAndLivenessModules = [
    moduleOCR,
    moduleDocumentLiveness
  ];

  static const int cameraLoadingTimeout = 2000;
  static const int apiRequestTimeout = 30000;
  static const int ocrProcessingTimeout = 60000;

  static const String errorNoTransactionId = 'No transaction ID found in server response';
  static const String errorRequestFailed = 'Request failed';
  static const String errorNetworkError = 'Network error occurred';
  static const String errorPermissionDenied = 'Camera permissions are required';
  static const String errorOCRFailed = 'OCR processing failed';
  static const String errorLivenessFailed = 'Document liveness check failed';
  static const String errorHologramFailed = 'Hologram check failed';

  static const String successTransactionCreated = 'Transaction created successfully';
  static const String successOCRCompleted = 'OCR processing completed';
  static const String successLivenessPassed = 'Document liveness check passed';
  static const String successHologramPassed = 'Hologram check passed';

  static const String uiPresetDefault = 'default';
  static const String uiPresetDark = 'dark';
  static const String uiPresetColorful = 'colorful';
  static const String uiPresetAllPink = 'allpink';
  static const String uiPresetMinimal = 'minimal';
  static const String uiPresetCustom = 'custom';

  static const Map<String, String> uiPresetNames = {
    uiPresetDefault: 'Default',
    uiPresetDark: '🌙 Dark Theme',
    uiPresetColorful: '🌈 Bright Test Colors (Android)',
    uiPresetAllPink: '🌸 ALL PINK - Ultimate Test!',
    uiPresetMinimal: '📱 Minimal Theme',
    uiPresetCustom: '⚙️ Custom Configuration',
  };

  static const double defaultBlurCoefficient = 0.0;
  static const int defaultDetectionAccuracy = 10;
  static const bool defaultReviewScreenEnabled = true;
  static const bool defaultFooterViewHidden = false;
  static const String defaultButtonBackColor = '#FFFFFF';
  static const String defaultMaskLayerColor = '#80000000';
}
