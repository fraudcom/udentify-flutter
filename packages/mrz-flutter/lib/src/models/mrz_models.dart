/// MRZ (Machine Readable Zone) data models for Flutter plugin

/// Complete MRZ data extracted from document
class MrzData {
  final String documentType;
  final String issuingCountry;
  final String documentNumber;
  final String? optionalData1;
  final String dateOfBirth;
  final String gender;
  final String dateOfExpiration;
  final String nationality;
  final String? optionalData2;
  final String surname;
  final String givenNames;

  MrzData({
    required this.documentType,
    required this.issuingCountry,
    required this.documentNumber,
    this.optionalData1,
    required this.dateOfBirth,
    required this.gender,
    required this.dateOfExpiration,
    required this.nationality,
    this.optionalData2,
    required this.surname,
    required this.givenNames,
  });

  factory MrzData.fromMap(Map<String, dynamic> map) {
    return MrzData(
      documentType: map['documentType'] ?? '',
      issuingCountry: map['issuingCountry'] ?? '',
      documentNumber: map['documentNumber'] ?? '',
      optionalData1: map['optionalData1'],
      dateOfBirth: map['dateOfBirth'] ?? '',
      gender: map['gender'] ?? '',
      dateOfExpiration: map['dateOfExpiration'] ?? '',
      nationality: map['nationality'] ?? '',
      optionalData2: map['optionalData2'],
      surname: map['surname'] ?? '',
      givenNames: map['givenNames'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentType': documentType,
      'issuingCountry': issuingCountry,
      'documentNumber': documentNumber,
      'optionalData1': optionalData1,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'dateOfExpiration': dateOfExpiration,
      'nationality': nationality,
      'optionalData2': optionalData2,
      'surname': surname,
      'givenNames': givenNames,
    };
  }

  /// Get full name (surname + given names)
  String get fullName => '$givenNames $surname'.trim();

  @override
  String toString() {
    return 'MrzData(documentType: $documentType, documentNumber: $documentNumber, fullName: $fullName, nationality: $nationality)';
  }
}

/// BAC Credentials needed for NFC reading
class BACCredentials {
  final String documentNumber;
  final String dateOfBirth;
  final String dateOfExpiration;

  BACCredentials({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.dateOfExpiration,
  });

  /// Create BACCredentials from MrzData
  factory BACCredentials.fromMrzData(MrzData mrzData) {
    return BACCredentials(
      documentNumber: mrzData.documentNumber,
      dateOfBirth: mrzData.dateOfBirth,
      dateOfExpiration: mrzData.dateOfExpiration,
    );
  }

  factory BACCredentials.fromMap(Map<String, dynamic> map) {
    return BACCredentials(
      documentNumber: map['documentNumber'] ?? '',
      dateOfBirth: map['dateOfBirth'] ?? '',
      dateOfExpiration: map['dateOfExpiration'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'dateOfExpiration': dateOfExpiration,
    };
  }

  @override
  String toString() {
    return 'BACCredentials(documentNumber: $documentNumber, dateOfBirth: $dateOfBirth, dateOfExpiration: $dateOfExpiration)';
  }
}

/// MRZ Error types
enum MrzErrorType {
  mrzNotFound,
  invalidDateOfBirth,
  invalidDateOfBirthSize,
  invalidDateOfExpire,
  invalidDateOfExpireSize,
  invalidDocumentNumber,
  cameraError,
  permissionDenied,
  unknown,
}

/// MRZ Error class
class MrzError {
  final MrzErrorType type;
  final String message;
  final String? details;

  MrzError({
    required this.type,
    required this.message,
    this.details,
  });

  factory MrzError.fromMap(Map<String, dynamic> map) {
    return MrzError(
      type: _parseErrorType(map['type'] ?? ''),
      message: map['message'] ?? 'Unknown error',
      details: map['details'],
    );
  }

  static MrzErrorType _parseErrorType(String typeString) {
    switch (typeString) {
      case 'ERR_MRZ_NOT_FOUND':
        return MrzErrorType.mrzNotFound;
      case 'ERR_INVALID_DATE_OF_BIRTH':
        return MrzErrorType.invalidDateOfBirth;
      case 'ERR_INVALID_DATE_OF_BIRTH_SIZE':
        return MrzErrorType.invalidDateOfBirthSize;
      case 'ERR_INVALID_DATE_OF_EXPIRE':
        return MrzErrorType.invalidDateOfExpire;
      case 'ERR_INVALID_DATE_OF_EXPIRE_SIZE':
        return MrzErrorType.invalidDateOfExpireSize;
      case 'ERR_INVALID_DOC_NO':
        return MrzErrorType.invalidDocumentNumber;
      case 'CAMERA_ERROR':
        return MrzErrorType.cameraError;
      case 'PERMISSION_DENIED':
        return MrzErrorType.permissionDenied;
      default:
        return MrzErrorType.unknown;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString(),
      'message': message,
      'details': details,
    };
  }

  @override
  String toString() {
    return 'MrzError(type: $type, message: $message, details: $details)';
  }
}
