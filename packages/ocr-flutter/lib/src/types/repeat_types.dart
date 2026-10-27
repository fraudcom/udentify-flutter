/// Which side an in-call OCR repeat re-scans.
enum OCRRepeatDocumentSide { front, back }

/// Credentials for an in-call OCR repeat, supplied to `OcrFlutter.setRepeatConfig`.
///
/// The video call operator can ask the customer to redo a capture without leaving the
/// call. Repeats are off until the app opts in with this configuration.
class OCRRepeatConfig {
  final String serverURL;
  final String userID;
  final String transactionID;

  /// ISO country or Udentify country code. The SDK defaults to `TUR`.
  final String country;

  /// `ID_CARD` (default), `PASSPORT` or `DRIVER_LICENSE`.
  final String documentType;

  /// Which side a repeat re-scans. Omitted, the native SDK always re-scans the
  /// front, so set it if the operator can ask for a back-side redo.
  final OCRRepeatDocumentSide? documentSide;

  /// Passed through to the native SDK's card-orientation handling.
  final bool? cardOrientation;

  const OCRRepeatConfig({
    required this.serverURL,
    required this.userID,
    required this.transactionID,
    this.country = 'TUR',
    this.documentType = 'ID_CARD',
    this.documentSide,
    this.cardOrientation,
  });

  Map<String, dynamic> toMap() => {
        'serverURL': serverURL,
        'userID': userID,
        'transactionID': transactionID,
        'country': country,
        'documentType': documentType,
        if (documentSide != null) 'documentSide': documentSide!.name.toUpperCase(),
        if (cardOrientation != null) 'cardOrientation': cardOrientation,
      };
}
