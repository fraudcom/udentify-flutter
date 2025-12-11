class AppConstants {
  static const String serverUrl = "https://demo.udentify.io/api";
  static const String wssUrl = "wss://livekit.np.fraud.com";
  static const String apiKey = "EcNzFN26S24/uf1tv7d+FXHgAPMzEye8";
  static const String appTitle = "Flutter Test App";
  static const String clientName = "Flutter Test Client";
  static const String idleTimeout = "30";
  static const int defaultRequestTimeout = 30;
  static const int defaultVideoCallTimeout = 10;
  static const String moduleOCR = "OCR";
  static const String moduleOCRHologram = "OCR_HOLOGRAM";
  static const String moduleNFC = "NFC";
  static const String moduleVideoCall = "VIDEO_CALL";
  static const String moduleDocumentLiveness = "DOCUMENT_LIVENESS";
  static const String moduleFaceLiveness = "FACE_LIVENESS";
  static const String moduleFaceRegistration = "FACE_REGISTRATION";
  static const String moduleFaceAuthentication = "FACE_AUTHENTICATION";
  static const String moduleActiveLiveness = "ACTIVE_LIVENESS";
  static const String moduleMRZ = "MRZ";
  static const String severityLow = "LOW";
  static const String severityNormal = "NORMAL";
  static const String severityHigh = "HIGH";
  static const String severityCritical = "CRITICAL";

  // Common module combinations
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
  static const List<String> faceLivenessModules = [moduleFaceLiveness];
  static const List<String> faceRegistrationAndLivenessModules = [
    moduleFaceRegistration,
    moduleFaceLiveness
  ];
  static const List<String> nfcModules = [moduleNFC];
  static const List<String> videoCallModules = [moduleVideoCall];

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultSpacing = 8.0;
  static const double cardElevation = 2.0;

  // Error Messages
  static const String permissionDeniedMessage =
      "Permission denied. Please grant the required permissions.";
  static const String networkErrorMessage =
      "Network error. Please check your connection.";
  static const String unknownErrorMessage = "An unknown error occurred.";
}

/// Note: Transaction IDs should be obtained from the API using ApiUtils.getTransactionId()
/// instead of generating them locally. This ensures proper server-side tracking and validation.
