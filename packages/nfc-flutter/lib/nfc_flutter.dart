import 'package:flutter/services.dart' show PlatformException;

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

  /// Opts this app into in-call NFC repeats (Android only, off by default). Pass `null` to opt
  /// back out. Call it before starting the video call. Returns `false` where it does not apply.
  Future<bool> setRepeatConfig(NfcRepeatConfig? config) {
    return NfcFlutterPlatform.instance.setRepeatConfig(config);
  }

  /// Whether the device has NFC hardware
  Future<bool> isNfcAvailable() {
    return NfcFlutterPlatform.instance.isNfcAvailable();
  }

  /// Whether NFC is switched on. On iOS there is no user-facing switch, so this
  /// matches [isNfcAvailable].
  Future<bool> isNfcEnabled() {
    return NfcFlutterPlatform.instance.isNfcEnabled();
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
  final bool? isPassiveAuthenticationEnabled;
  final NfcChipAnticloneMode? chipAnticloneMode;

  const NfcPassportParams({
    required this.documentNumber,
    required this.dateOfBirth,
    required this.expiryDate,
    required this.transactionID,
    required this.serverURL,
    this.requestTimeout,
    this.isPassiveAuthenticationEnabled,
    this.chipAnticloneMode,
  });

  Map<String, dynamic> toMap() {
    return {
      'documentNumber': documentNumber,
      'dateOfBirth': dateOfBirth,
      'expiryDate': expiryDate,
      'transactionID': transactionID,
      'serverURL': serverURL,
      'requestTimeout': requestTimeout,
      'isPassiveAuthenticationEnabled': isPassiveAuthenticationEnabled,
      'chipAnticloneMode': chipAnticloneMode?.toString(),
    };
  }
}

/// Chip anti-cloning mode, mirroring the native SDK's `ChipAnticloneMode`
enum NfcChipAnticloneMode {
  /// Disables both Chip Authentication (CA) and Active Authentication (AA).
  none,
  /// Prefer CA when DG14 is present; fall back to AA when unavailable.
  auto,
  /// CA only.
  requireCA,
  /// AA only (legacy behavior).
  requireAA;

  static NfcChipAnticloneMode fromString(String value) {
    switch (value) {
      case 'none':
        return NfcChipAnticloneMode.none;
      case 'requireCA':
        return NfcChipAnticloneMode.requireCA;
      case 'requireAA':
        return NfcChipAnticloneMode.requireAA;
      default:
        return NfcChipAnticloneMode.auto;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NfcChipAnticloneMode.none:
        return 'none';
      case NfcChipAnticloneMode.auto:
        return 'auto';
      case NfcChipAnticloneMode.requireCA:
        return 'requireCA';
      case NfcChipAnticloneMode.requireAA:
        return 'requireAA';
    }
  }
}

/// Passport data returned from NFC reading
class NfcPassport {
  final String? image; // Base64 encoded JPEG
  final String? firstName;
  final String? lastName;
  final AuthenticationResult? passedPA;
  final AuthenticationResult? passedAA;

  /// Chip Authentication result. With the default `chipAnticloneMode` (`auto`) the SDK prefers Chip
  /// Authentication when the chip has DG14, so this is the verdict to read; [passedAA] then reports not
  /// supported or disabled.
  final AuthenticationResult? passedCA;

  // Document data read from the chip, as the native SDK reports it.
  final String? documentNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? gender;

  /// The SDK's document type (reported under `issuer` by the native layer).
  final String? issuer;
  final String? personalNumber;
  final String? placeOfBirth;
  final String? address;

  final String? phoneNumber;
  final String? documentCode;
  final String? issuingAuthority;
  final String? dateOfIssue;

  /// How access to the chip was authorised: `none`, `bac` or `pace` (iOS spelling; Android's enum names).
  final String? accessControlProtocol;

  const NfcPassport({
    this.image,
    this.firstName,
    this.lastName,
    this.passedPA,
    this.passedAA,
    this.passedCA,
    this.documentNumber,
    this.nationality,
    this.dateOfBirth,
    this.expiryDate,
    this.gender,
    this.issuer,
    this.personalNumber,
    this.placeOfBirth,
    this.address,
    this.phoneNumber,
    this.documentCode,
    this.issuingAuthority,
    this.dateOfIssue,
    this.accessControlProtocol,
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
      passedCA: map['passedCA'] != null
          ? AuthenticationResult.fromString(map['passedCA'])
          : null,
      documentNumber: map['documentNumber'],
      nationality: map['nationality'],
      dateOfBirth: map['dateOfBirth'],
      expiryDate: map['expiryDate'],
      gender: map['gender'],
      issuer: map['issuer'],
      personalNumber: map['personalNumber'],
      placeOfBirth: map['placeOfBirth'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      documentCode: map['documentCode'],
      issuingAuthority: map['issuingAuthority'],
      dateOfIssue: map['dateOfIssue'],
      accessControlProtocol: map['accessControlProtocol'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': image,
      'firstName': firstName,
      'lastName': lastName,
      'passedPA': passedPA?.toString(),
      'passedAA': passedAA?.toString(),
      'passedCA': passedCA?.toString(),
      'documentNumber': documentNumber,
      'nationality': nationality,
      'dateOfBirth': dateOfBirth,
      'expiryDate': expiryDate,
      'gender': gender,
      'issuer': issuer,
      'personalNumber': personalNumber,
      'placeOfBirth': placeOfBirth,
      'address': address,
      'phoneNumber': phoneNumber,
      'documentCode': documentCode,
      'issuingAuthority': issuingAuthority,
      'dateOfIssue': dateOfIssue,
      'accessControlProtocol': accessControlProtocol,
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
  /// Whether `READ_PHONE_STATE` is granted. The NFC SDK documents it as essential and to be requested at
  /// runtime, which is what `requestPermissions()` does. Always `true` on iOS.
  final bool hasPhoneStatePermission;

  /// Despite the name, this is **not** a runtime permission: `android.permission.NFC` is granted at install
  /// time. On Android it reports whether the device has NFC hardware (the same as `isNfcAvailable()`); on
  /// iOS it is always `true`. The name is kept so existing code keeps compiling.
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

/// Credentials for an in-call NFC repeat, supplied to `NfcFlutter.setRepeatConfig`.
///
/// An NFC repeat derives its BAC key material from a completed OCR repeat in the same call, so the
/// operator must run OCR first. Repeats are off until the app opts in with this configuration.
class NfcRepeatConfig {
  final String serverURL;
  final String transactionID;

  /// Whether to run passive authentication on the chip's signed data objects. Omitted, the
  /// native SDK's own default applies.
  final bool? passiveAuthentication;

  const NfcRepeatConfig({
    required this.serverURL,
    required this.transactionID,
    this.passiveAuthentication,
  });

  Map<String, dynamic> toMap() => {
        'serverURL': serverURL,
        'transactionID': transactionID,
        if (passiveAuthentication != null)
          'passiveAuthentication': passiveAuthentication,
      };
}

/// The error names of the NFC SDK (its `ERR_*` string resources; on iOS the plugin names the matching
/// `TagError` cases with them), plus the codes the plugin itself sends. `readPassport` and the location
/// calls fail with a [PlatformException]; type its code with [NfcErrorType.fromException].
enum NfcErrorType {
  activeAuthenticationFailed('ERR_ACTIVE_AUTHENTICATION_FAILED'),
  bacFailed('ERR_BAC_FAILED'),
  cardReadingFailed('ERR_CARD_READING_FAILED'),
  failedToConnectServer('ERR_FAILED_TO_CONNECT_SERVER'),
  nfcCredentialsMissing('ERR_NFC_CREDENTIALS_MISSING'),
  nfcInvalidInput('ERR_NFC_INVALID_INPUT'),
  nfcReaderNotAvailable('ERR_NFC_READER_NOT_AVAILABLE'),
  passiveAuthenticationFailed('ERR_PASSIVE_AUTHENTICATION_FAILED'),
  problemOccured('ERR_PROBLEM_OCCURED'),
  /// `ERR_READING_DG<n>_FAILED` for any data group `n` (Android).
  readingDataGroupFailed('ERR_READING_DG_FAILED'),
  tagLost('ERR_TAG_LOST'),
  transactionExpired('ERR_TRANSACTION_EXPIRED'),
  transactionFailed('ERR_TRANSACTION_FAILED'),
  transactionNotFound('ERR_TRANSACTION_NOT_FOUND'),
  // Codes the plugin sends when the SDK's failure carried no error name.
  readError('NFC_READ_ERROR'),
  iosReadError('NFC_ERROR'),
  disabled('NFC_DISABLED'),
  cancelled('CANCELLED'),
  locationError('NFC_LOCATION_ERROR'),
  iosLocationError('LOCATION_ERROR'),
  missingParameters('MISSING_PARAMETERS'),
  unknown('UNKNOWN');

  const NfcErrorType(this.value);
  final String value;

  static NfcErrorType fromString(String? code) {
    for (final type in NfcErrorType.values) {
      if (type.value == code) return type;
    }
    if (code != null && RegExp(r'^ERR_READING_DG[0-9]+_FAILED$').hasMatch(code)) {
      return NfcErrorType.readingDataGroupFailed;
    }
    return NfcErrorType.unknown;
  }

  static NfcErrorType fromException(PlatformException e) => fromString(e.code);
}
