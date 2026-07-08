import 'nfc_flutter_platform_interface.dart';

/// Flutter plugin for NFC passport reading using Udentify's SDK
class NfcFlutter {
  /// Read passport data using NFC
  Future<NfcPassport?> readPassport(
    NfcPassportParams params, {
    Function(double progress)? onProgress,
  }) {
    return NfcFlutterPlatform.instance
        .readPassport(params, onProgress: onProgress);
  }

  /// Cancel ongoing NFC reading operation
  Future<void> cancelReading() {
    return NfcFlutterPlatform.instance.cancelReading();
  }

  /// Get NFC antenna location on the device
  Future<NfcLocation> getNfcLocation(String serverURL) {
    return NfcFlutterPlatform.instance.getNfcLocation(serverURL);
  }

  Future<String> getNfcLocationRaw(String serverURL) {
    return NfcFlutterPlatform.instance.getNfcLocationRaw(serverURL);
  }

  /// Check current permissions status
  Future<PermissionStatus> checkPermissions() {
    return NfcFlutterPlatform.instance.checkPermissions();
  }

  /// Request necessary permissions for NFC functionality
  Future<String> requestPermissions() {
    return NfcFlutterPlatform.instance.requestPermissions();
  }
}

/// Parameters required for NFC passport reading
class NfcPassportParams {
  final String documentNumber;
  final String dateOfBirth; // YYMMDD format
  final String expiryDate; // YYMMDD format
  final String transactionID;
  final String serverURL;
  final int? requestTimeout;
  final bool? isActiveAuthenticationEnabled;
  final bool? isPassiveAuthenticationEnabled;

  const NfcPassportParams({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.transactionID,
    required this.serverURL,
    this.requestTimeout,
    this.isActiveAuthenticationEnabled,
    this.isPassiveAuthenticationEnabled,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'expiryDate': expiryDate,
      'transactionID': transactionID,
      'serverURL': serverURL,
      'requestTimeout': requestTimeout,
      'isActiveAuthenticationEnabled': isActiveAuthenticationEnabled,
      'isPassiveAuthenticationEnabled': isPassiveAuthenticationEnabled,
    };
  }
}

/// Passport data returned from NFC reading
class NfcPassport {
  final String? image; // Base64 encoded
  final String? firstName;
  final String? lastName;
  final AuthenticationResult? passedPA;
  final AuthenticationResult? passedAA;

  const NfcPassport({
    this.image,
    this.firstName,
    this.lastName,
    this.passedPA,
    this.passedAA,
  });

  factory NfcPassport.fromMap(Map<String, dynamic> map) {
    return NfcPassport(
      image: map['image'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      passedPA: map['passedPA'] != null
          ? AuthenticationResult.fromString(map['passedPA'])
          : null,
      passedAA: map['passedAA'] != null
          ? AuthenticationResult.fromString(map['passedAA'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'firstName': firstName,
      'lastName': lastName,
      'passedPA': passedPA?.toString(),
      'passedAA': passedAA?.toString(),
    };
  }
}

/// Authentication result for PA/AA
enum AuthenticationResult {
  disabled,
  success,
  failed,
  notSupported;

  static AuthenticationResult fromString(String value) {
    switch (value) {
      case 'disabled':
        return AuthenticationResult.disabled;
      case 'true':
        return AuthenticationResult.success;
      case 'false':
        return AuthenticationResult.failed;
      case 'notSupported':
        return AuthenticationResult.notSupported;
      default:
        return AuthenticationResult.notSupported;
    }
  }

  @override
  String toString() {
    switch (this) {
      case AuthenticationResult.disabled:
        return 'disabled';
      case AuthenticationResult.success:
        return 'true';
      case AuthenticationResult.failed:
        return 'false';
      case AuthenticationResult.notSupported:
        return 'notSupported';
    }
  }
}

/// NFC antenna location on the device
enum NfcLocation {
  unknown,
  frontTop,
  frontCenter,
  frontBottom,
  rearTop,
  rearCenter,
  rearBottom;

  static NfcLocation fromString(String value) {
    switch (value) {
      case 'frontTop':
        return NfcLocation.frontTop;
      case 'frontCenter':
        return NfcLocation.frontCenter;
      case 'frontBottom':
        return NfcLocation.frontBottom;
      case 'rearTop':
        return NfcLocation.rearTop;
      case 'rearCenter':
        return NfcLocation.rearCenter;
      case 'rearBottom':
        return NfcLocation.rearBottom;
      default:
        return NfcLocation.unknown;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NfcLocation.unknown:
        return 'unknown';
      case NfcLocation.frontTop:
        return 'frontTop';
      case NfcLocation.frontCenter:
        return 'frontCenter';
      case NfcLocation.frontBottom:
        return 'frontBottom';
      case NfcLocation.rearTop:
        return 'rearTop';
      case NfcLocation.rearCenter:
        return 'rearCenter';
      case NfcLocation.rearBottom:
        return 'rearBottom';
    }
  }
}

/// Permission status for NFC functionality
class PermissionStatus {
  final bool hasPhoneStatePermission;
  final bool hasNfcPermission;

  const PermissionStatus({
    required this.hasPhoneStatePermission,
    required this.hasNfcPermission,
  });

  factory PermissionStatus.fromMap(Map<String, dynamic> map) {
    return PermissionStatus(
      hasPhoneStatePermission: map['hasPhoneStatePermission'] ?? false,
      hasNfcPermission: map['hasNfcPermission'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hasPhoneStatePermission': hasPhoneStatePermission,
      'hasNfcPermission': hasNfcPermission,
    };
  }
}
