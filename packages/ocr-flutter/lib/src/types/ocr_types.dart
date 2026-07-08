/// Common OCR Fields
class CommonOCRFields {
  final String? documentType;
  final String? countryCode;
  final String? documentID;
  final bool? isOCRDocumentExpired;
  final String? faceImage;
  final String? firstName;
  final String? lastName;
  final bool? isOCRIDValid;
  final String? identityNo;
  final String? birthDate;
  final String? expiryDate;
  final bool? hasOCRSignature;
  final String? ocrFieldValidationMessage;

  CommonOCRFields({
    this.documentType,
    this.countryCode,
    this.documentID,
    this.isOCRDocumentExpired,
    this.faceImage,
    this.firstName,
    this.lastName,
    this.isOCRIDValid,
    this.identityNo,
    this.birthDate,
    this.expiryDate,
    this.hasOCRSignature,
    this.ocrFieldValidationMessage,
  });

  factory CommonOCRFields.fromMap(Map<String, dynamic> map) {
    return CommonOCRFields(
      documentType: map['documentType'],
      countryCode: map['countryCode'],
      documentID: map['documentID'],
      isOCRDocumentExpired: _parseBool(map['isOCRDocumentExpired']),
      faceImage: map['faceImage'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      isOCRIDValid: _parseBool(map['isOCRIDValid']),
      identityNo: map['identityNo'],
      birthDate: map['birthDate'],
      expiryDate: map['expiryDate'],
      hasOCRSignature: _parseBool(map['hasOCRSignature']),
      ocrFieldValidationMessage: map['ocrFieldValidationMessage'],
    );
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }
}

/// ID Card OCR Response
class IDCardOCRResponse extends CommonOCRFields {
  final String? documentIssuer;
  final String? motherName;
  final String? fatherName;
  final String? mrzString;
  final String? gender;
  final String? nationality;
  final bool? hasOCRPhoto;
  final bool? hasHiddenPhoto;
  final bool? isPhotoCheatDetected;
  final bool? mrzDataExists;
  final String? mrzBirthDate;
  final String? mrzBirthDateChecksum;
  final String? mrzCountry;
  final String? mrzDocumentNo;
  final String? mrzDocumentNoChecksum;
  final String? mrzDocumentType;
  final String? mrzExpiryDate;
  final String? mrzExpiryDateChecksum;
  final String? mrzDataIntegrityChecksum;
  final String? mrzName;
  final String? mrzNationality;
  final String? mrzOptionalData;
  final String? mrzGender;
  final String? mrzSurname;
  final String? barcodeData;
  final bool? barcodeDataExists;
  final String? mrzDigitChecksum;
  final bool? isMrzAndOcrMatch;
  final bool? chipExists;
  final bool? mrzDocumentNoChecksumVerified;
  final bool? mrzBirthDateChecksumVerified;
  final bool? mrzExpiryDateChecksumVerified;
  final bool? mrzFinalChecksumVerified;

  IDCardOCRResponse({
    super.documentType,
    super.countryCode,
    super.documentID,
    super.isOCRDocumentExpired,
    super.faceImage,
    super.firstName,
    super.lastName,
    super.isOCRIDValid,
    super.identityNo,
    super.birthDate,
    super.expiryDate,
    super.hasOCRSignature,
    super.ocrFieldValidationMessage,
    this.documentIssuer,
    this.motherName,
    this.fatherName,
    this.mrzString,
    this.gender,
    this.nationality,
    this.hasOCRPhoto,
    this.hasHiddenPhoto,
    this.isPhotoCheatDetected,
    this.mrzDataExists,
    this.mrzBirthDate,
    this.mrzBirthDateChecksum,
    this.mrzCountry,
    this.mrzDocumentNo,
    this.mrzDocumentNoChecksum,
    this.mrzDocumentType,
    this.mrzExpiryDate,
    this.mrzExpiryDateChecksum,
    this.mrzDataIntegrityChecksum,
    this.mrzName,
    this.mrzNationality,
    this.mrzOptionalData,
    this.mrzGender,
    this.mrzSurname,
    this.barcodeData,
    this.barcodeDataExists,
    this.mrzDigitChecksum,
    this.isMrzAndOcrMatch,
    this.chipExists,
    this.mrzDocumentNoChecksumVerified,
    this.mrzBirthDateChecksumVerified,
    this.mrzExpiryDateChecksumVerified,
    this.mrzFinalChecksumVerified,
  });

  factory IDCardOCRResponse.fromMap(Map<String, dynamic> map) {
    return IDCardOCRResponse(
      documentType: map['documentType'],
      countryCode: map['countryCode'],
      documentID: map['documentID'],
      isOCRDocumentExpired:
          CommonOCRFields._parseBool(map['isOCRDocumentExpired']),
      faceImage: map['faceImage'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      isOCRIDValid: CommonOCRFields._parseBool(map['isOCRIDValid']),
      identityNo: map['identityNo'],
      birthDate: map['birthDate'],
      expiryDate: map['expiryDate'],
      hasOCRSignature: CommonOCRFields._parseBool(map['hasOCRSignature']),
      ocrFieldValidationMessage: map['ocrFieldValidationMessage'],
      documentIssuer: map['documentIssuer'],
      motherName: map['motherName'],
      fatherName: map['fatherName'],
      mrzString: map['mrzString'],
      gender: map['gender'],
      nationality: map['nationality'],
      hasOCRPhoto: CommonOCRFields._parseBool(map['hasOCRPhoto']),
      hasHiddenPhoto: CommonOCRFields._parseBool(map['hasHiddenPhoto']),
      isPhotoCheatDetected:
          CommonOCRFields._parseBool(map['isPhotoCheatDetected']),
      mrzDataExists: CommonOCRFields._parseBool(map['mrzDataExists']),
      mrzBirthDate: map['mrzBirthDate'],
      mrzBirthDateChecksum: map['mrzBirthDateChecksum'],
      mrzCountry: map['mrzCountry'],
      mrzDocumentNo: map['mrzDocumentNo'],
      mrzDocumentNoChecksum: map['mrzDocumentNoChecksum'],
      mrzDocumentType: map['mrzDocumentType'],
      mrzExpiryDate: map['mrzExpiryDate'],
      mrzExpiryDateChecksum: map['mrzExpiryDateChecksum'],
      mrzDataIntegrityChecksum: map['mrzDataIntegrityChecksum'],
      mrzName: map['mrzName'],
      mrzNationality: map['mrzNationality'],
      mrzOptionalData: map['mrzOptionalData'],
      mrzGender: map['mrzGender'],
      mrzSurname: map['mrzSurname'],
      barcodeData: map['barcodeData'],
      barcodeDataExists: CommonOCRFields._parseBool(map['barcodeDataExists']),
      mrzDigitChecksum: map['mrzDigitChecksum'],
      isMrzAndOcrMatch: CommonOCRFields._parseBool(map['isMrzAndOcrMatch']),
      chipExists: CommonOCRFields._parseBool(map['chipExists']),
      mrzDocumentNoChecksumVerified:
          CommonOCRFields._parseBool(map['mrzDocumentNoChecksumVerified']),
      mrzBirthDateChecksumVerified:
          CommonOCRFields._parseBool(map['mrzBirthDateChecksumVerified']),
      mrzExpiryDateChecksumVerified:
          CommonOCRFields._parseBool(map['mrzExpiryDateChecksumVerified']),
      mrzFinalChecksumVerified:
          CommonOCRFields._parseBool(map['mrzFinalChecksumVerified']),
    );
  }
}

/// Driver License OCR Response
class DriverLicenseOCRResponse extends CommonOCRFields {
  final String? issueDate;
  final bool? ocrQRApproved;
  final String? ocrQRLicenceID;
  final String? ocrQRIdentityNo;
  final bool? ocrQRIdentityNoCheck;
  final bool? ocrQRLicenceIDCheck;
  final String? ocrLicenceType;
  final String? city;
  final String? district;

  DriverLicenseOCRResponse({
    super.documentType,
    super.countryCode,
    super.documentID,
    super.isOCRDocumentExpired,
    super.faceImage,
    super.firstName,
    super.lastName,
    super.isOCRIDValid,
    super.identityNo,
    super.birthDate,
    super.expiryDate,
    super.hasOCRSignature,
    super.ocrFieldValidationMessage,
    this.issueDate,
    this.ocrQRApproved,
    this.ocrQRLicenceID,
    this.ocrQRIdentityNo,
    this.ocrQRIdentityNoCheck,
    this.ocrQRLicenceIDCheck,
    this.ocrLicenceType,
    this.city,
    this.district,
  });

  factory DriverLicenseOCRResponse.fromMap(Map<String, dynamic> map) {
    return DriverLicenseOCRResponse(
      documentType: map['documentType'],
      countryCode: map['countryCode'],
      documentID: map['documentID'],
      isOCRDocumentExpired: map['isOCRDocumentExpired'],
      faceImage: map['faceImage'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      isOCRIDValid: map['isOCRIDValid'],
      identityNo: map['identityNo'],
      birthDate: map['birthDate'],
      expiryDate: map['expiryDate'],
      hasOCRSignature: map['hasOCRSignature'],
      ocrFieldValidationMessage: map['ocrFieldValidationMessage'],
      issueDate: map['issueDate'],
      ocrQRApproved: map['ocrQRApproved'],
      ocrQRLicenceID: map['ocrQRLicenceID'],
      ocrQRIdentityNo: map['ocrQRIdentityNo'],
      ocrQRIdentityNoCheck: map['ocrQRIdentityNoCheck'],
      ocrQRLicenceIDCheck: map['ocrQRLicenceIDCheck'],
      ocrLicenceType: map['ocrLicenceType'],
      city: map['city'],
      district: map['district'],
    );
  }
}

/// OCR Response Union
class OCRResponse {
  final String responseType;
  final IDCardOCRResponse? idCardResponse;
  final DriverLicenseOCRResponse? driverLicenseResponse;
  final bool? success;
  final String? transactionID;
  final double? timestamp;
  final String? documentType;
  final Map<String, dynamic>? extractedData;

  OCRResponse({
    required this.responseType,
    this.idCardResponse,
    this.driverLicenseResponse,
    this.success,
    this.transactionID,
    this.timestamp,
    this.documentType,
    this.extractedData,
  });

  factory OCRResponse.fromMap(Map<String, dynamic> map) {
    final responseType = map['responseType'] as String;

    return OCRResponse(
      responseType: responseType,
      idCardResponse: responseType == 'idCard' && map['idCardResponse'] != null
          ? IDCardOCRResponse.fromMap(map['idCardResponse'])
          : null,
      driverLicenseResponse: responseType == 'driverLicense' &&
              map['driverLicenseResponse'] != null
          ? DriverLicenseOCRResponse.fromMap(map['driverLicenseResponse'])
          : null,
      success: map['success'] as bool?,
      transactionID: map['transactionID'] as String?,
      timestamp: (map['timestamp'] as num?)?.toDouble(),
      documentType: map['documentType'] as String?,
      extractedData: map['extractedData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'OCRResponse{responseType: $responseType, success: $success, idCardResponse: ${idCardResponse != null ? 'Available' : 'null'}, driverLicenseResponse: ${driverLicenseResponse != null ? 'Available' : 'null'}, extractedData: ${extractedData != null ? 'Available' : 'null'}}';
  }
}

/// OCR Data
class OCRData {
  final OCRResponse? ocrResponse;
  final String? error;

  OCRData({
    this.ocrResponse,
    this.error,
  });

  factory OCRData.fromMap(Map<String, dynamic> map) {
    return OCRData(
      ocrResponse: map['ocrResponse'] != null
          ? OCRResponse.fromMap(map['ocrResponse'])
          : null,
      error: map['error'],
    );
  }
}

/// Document Liveness Pipeline Result
class DocumentLivenessPipelineResult {
  final String? name;
  final String? calibration;
  final String? documentLivenessScore;
  final String? documentLivenessProbability;
  final String? documentStatusCode;

  DocumentLivenessPipelineResult({
    this.name,
    this.calibration,
    this.documentLivenessScore,
    this.documentLivenessProbability,
    this.documentStatusCode,
  });

  factory DocumentLivenessPipelineResult.fromMap(Map<String, dynamic> map) {
    return DocumentLivenessPipelineResult(
      name: map['name'],
      calibration: map['calibration'],
      documentLivenessScore: map['documentLivenessScore'],
      documentLivenessProbability: map['documentLivenessProbability'],
      documentStatusCode: map['documentStatusCode'],
    );
  }
}

/// Document Liveness Response
class DocumentLivenessResponse {
  final List<DocumentLivenessPipelineResult>? pipelineResults;
  final String? aggregateDocumentLivenessProbability;
  final String? aggregateDocumentImageQualityWarnings;

  DocumentLivenessResponse({
    this.pipelineResults,
    this.aggregateDocumentLivenessProbability,
    this.aggregateDocumentImageQualityWarnings,
  });

  factory DocumentLivenessResponse.fromMap(Map<String, dynamic> map) {
    return DocumentLivenessResponse(
      pipelineResults: map['pipelineResults'] != null
          ? (map['pipelineResults'] as List)
              .map((item) => DocumentLivenessPipelineResult.fromMap(item))
              .toList()
          : null,
      aggregateDocumentLivenessProbability:
          map['aggregateDocumentLivenessProbability'],
      aggregateDocumentImageQualityWarnings:
          map['aggregateDocumentImageQualityWarnings'],
    );
  }
}

/// Document Liveness Data
class DocumentLivenessData {
  final DocumentLivenessResponse? documentLivenessResponse;
  final String? error;

  DocumentLivenessData({
    this.documentLivenessResponse,
    this.error,
  });

  factory DocumentLivenessData.fromMap(Map<String, dynamic> map) {
    return DocumentLivenessData(
      documentLivenessResponse: map['documentLivenessResponse'] != null
          ? DocumentLivenessResponse.fromMap(map['documentLivenessResponse'])
          : null,
      error: map['error'],
    );
  }
}

/// OCR and Document Liveness Response
class OCRAndDocumentLivenessResponse {
  final bool isFailed;
  final OCRData? ocrData;
  final DocumentLivenessData? documentLivenessDataFront;
  final DocumentLivenessData? documentLivenessDataBack;
  final bool? success;
  final String? transactionID;
  final double? timestamp;
  final double? frontSideProbability;
  final double? backSideProbability;
  final List<Map<String, dynamic>>? frontSideResults;
  final List<Map<String, dynamic>>? backSideResults;

  OCRAndDocumentLivenessResponse({
    required this.isFailed,
    this.ocrData,
    this.documentLivenessDataFront,
    this.documentLivenessDataBack,
    this.success,
    this.transactionID,
    this.timestamp,
    this.frontSideProbability,
    this.backSideProbability,
    this.frontSideResults,
    this.backSideResults,
  });

  factory OCRAndDocumentLivenessResponse.fromMap(Map<String, dynamic> map) {
    return OCRAndDocumentLivenessResponse(
      isFailed: map['isFailed'] ?? false,
      ocrData: map['ocrData'] != null ? OCRData.fromMap(map['ocrData']) : null,
      documentLivenessDataFront: map['documentLivenessDataFront'] != null
          ? DocumentLivenessData.fromMap(map['documentLivenessDataFront'])
          : null,
      documentLivenessDataBack: map['documentLivenessDataBack'] != null
          ? DocumentLivenessData.fromMap(map['documentLivenessDataBack'])
          : null,
      success: map['success'] as bool?,
      transactionID: map['transactionID'] as String?,
      timestamp: (map['timestamp'] as num?)?.toDouble(),
      frontSideProbability: (map['frontSideProbability'] as num?)?.toDouble(),
      backSideProbability: (map['backSideProbability'] as num?)?.toDouble(),
      frontSideResults: (map['frontSideResults'] as List?)?.cast<Map<String, dynamic>>(),
      backSideResults: (map['backSideResults'] as List?)?.cast<Map<String, dynamic>>(),
    );
  }
}
