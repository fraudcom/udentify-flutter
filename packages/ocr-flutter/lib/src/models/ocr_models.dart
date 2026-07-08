import '../constants/document_type.dart';
import '../constants/document_side.dart';

/// OCR Countries
enum OCRCountry {
  turkey('TUR'),
  unitedKingdom('GBR'),
  colombia('COL'),
  spain('ESP'),
  brazil('BRA'),
  usa('USA'),
  peru('PER'),
  ecuador('ECU');

  const OCRCountry(this.value);
  final String value;
}

/// OCR Controller Types
enum OCRControllerType {
  ocr('OCR'),
  hologram('HOLOGRAM');

  const OCRControllerType(this.value);
  final String value;
}

/// OCR Camera Parameters
class OCRCameraParams {
  final String serverURL;
  final String transactionID;
  final String? userID;
  final OCRDocumentType documentType;
  final OCRCountry? country;
  final OCRDocumentSide? documentSide;
  final bool? manualCapture;
  final bool? livenessMode;

  /// Crop extension ratio around detected card edges (0.0-1.0).
  /// Higher values may improve OCR accuracy; SDK default is 0.35.
  final double? rawPhotoCropRatio;

  OCRCameraParams({
    required this.serverURL,
    required this.transactionID,
    this.userID,
    required this.documentType,
    this.country,
    this.documentSide,
    this.manualCapture,
    this.livenessMode,
    this.rawPhotoCropRatio,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'documentType': documentType.value,
      'country': country?.value,
      'documentSide': documentSide?.value ?? 'bothSides',
      'manualCapture': manualCapture ?? false,
      'livenessMode': livenessMode ?? false,
      'rawPhotoCropRatio': rawPhotoCropRatio,
    };
  }
}

/// OCR Process Parameters
class OCRProcessParams {
  final String serverURL;
  final String transactionID;
  final String? userID;
  final String? frontSidePhoto;
  final String? backSidePhoto;
  final OCRCountry? country;
  final OCRDocumentType documentType;
  final int? requestTimeout;

  OCRProcessParams({
    required this.serverURL,
    required this.transactionID,
    this.userID,
    this.frontSidePhoto,
    this.backSidePhoto,
    this.country,
    required this.documentType,
    this.requestTimeout,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'frontSidePhoto': frontSidePhoto,
      'backSidePhoto': backSidePhoto,
      'country': country?.value,
      'documentType': documentType.value,
      'requestTimeout': requestTimeout ?? 30,
    };
  }
}

/// Hologram Parameters
class HologramParams {
  final String serverURL;
  final String transactionID;
  final String? userID;
  final OCRCountry? country;
  final String? logLevel;

  /// Seconds recorded without flash before the flash phase. SDK default: 2.
  final int? noFlashDuration;

  /// Seconds recorded with flash on. SDK default: 3.
  final int? flashDuration;

  /// Total hologram video duration in seconds. SDK default: 5.
  final int? totalDuration;

  /// Video encoding bitrate; null uses the SDK default.
  final double? bitrate;

  HologramParams({
    required this.serverURL,
    required this.transactionID,
    this.userID,
    this.country,
    this.logLevel,
    this.noFlashDuration,
    this.flashDuration,
    this.totalDuration,
    this.bitrate,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'country': country?.value,
      'logLevel': logLevel,
      'noFlashDuration': noFlashDuration,
      'flashDuration': flashDuration,
      'totalDuration': totalDuration,
      'bitrate': bitrate,
    };
  }
}

/// Document Liveness Parameters
class DocumentLivenessParams {
  final String serverURL;
  final String transactionID;
  final String? userID;
  final String? frontSidePhoto;
  final String? backSidePhoto;
  final int? requestTimeout;

  DocumentLivenessParams({
    required this.serverURL,
    required this.transactionID,
    this.userID,
    this.frontSidePhoto,
    this.backSidePhoto,
    this.requestTimeout,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'frontSidePhoto': frontSidePhoto,
      'backSidePhoto': backSidePhoto,
      'requestTimeout': requestTimeout ?? 30,
    };
  }
}

/// OCR and Document Liveness Parameters
class OCRAndDocumentLivenessParams {
  final String serverURL;
  final String transactionID;
  final String? userID;
  final String? frontSidePhoto;
  final String? backSidePhoto;
  final OCRCountry? country;
  final OCRDocumentType documentType;
  final int? requestTimeout;

  OCRAndDocumentLivenessParams({
    required this.serverURL,
    required this.transactionID,
    this.userID,
    this.frontSidePhoto,
    this.backSidePhoto,
    this.country,
    required this.documentType,
    this.requestTimeout,
  });

  Map<String, dynamic> toMap() {
    return {
      'serverURL': serverURL,
      'transactionID': transactionID,
      'userID': userID,
      'frontSidePhoto': frontSidePhoto,
      'backSidePhoto': backSidePhoto,
      'country': country?.value,
      'documentType': documentType.value,
      'requestTimeout': requestTimeout ?? 30,
    };
  }
}
