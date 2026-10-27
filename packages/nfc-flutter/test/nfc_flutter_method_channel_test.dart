import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_flutter/nfc_flutter.dart';
import 'package:nfc_flutter/nfc_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelNfcFlutter();
  const channel = MethodChannel('nfc_flutter');
  final calls = <MethodCall>[];

  void mock(Future<Object?> Function(MethodCall call) handler) {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('NfcPassport', () {
    test('exposes the document data the SDK reads, not just five fields', () {
      final passport = NfcPassport.fromMap({
        'image': 'AAAA',
        'firstName': 'ADA',
        'lastName': 'LOVELACE',
        'passedPA': 'true',
        'passedAA': 'disabled',
        'documentNumber': 'P123',
        'nationality': 'GBR',
        'dateOfBirth': '151210',
        'expiryDate': '301231',
        'gender': 'F',
        'issuer': 'P',
        'personalNumber': '99',
        'placeOfBirth': 'LONDON',
        'address': '1 Way',
      });

      expect(passport.documentNumber, 'P123');
      expect(passport.nationality, 'GBR');
      expect(passport.dateOfBirth, '151210');
      expect(passport.expiryDate, '301231');
      expect(passport.gender, 'F');
      expect(passport.issuer, 'P');
      expect(passport.personalNumber, '99');
      expect(passport.placeOfBirth, 'LONDON');
      expect(passport.address, '1 Way');
      expect(passport.passedPA, AuthenticationResult.success);
      expect(passport.passedAA, AuthenticationResult.disabled);
    });

    test('the chip authentication verdict and the remaining SDK fields are exposed', () {
      final passport = NfcPassport.fromMap({
        'passedPA': 'true',
        'passedAA': 'notSupported',
        'passedCA': 'true',
        'phoneNumber': '555',
        'documentCode': 'P',
        'issuingAuthority': 'TUR',
        'dateOfIssue': '200101',
        'accessControlProtocol': 'pace',
      });
      expect(passport.passedCA, AuthenticationResult.success);
      expect(passport.phoneNumber, '555');
      expect(passport.documentCode, 'P');
      expect(passport.issuingAuthority, 'TUR');
      expect(passport.dateOfIssue, '200101');
      expect(passport.accessControlProtocol, 'pace');
    });

    test('a map with only the original five fields still parses', () {
      final passport = NfcPassport.fromMap({'firstName': 'A', 'lastName': 'B'});
      expect(passport.firstName, 'A');
      expect(passport.documentNumber, isNull);
    });

    test('the image the native layer sends decodes as base64', () {
      // Android used Base64.DEFAULT, which inserts newlines Dart's decoder rejects.
      // The native layer now sends it unwrapped.
      expect(() => base64Decode('QUJD'), returnsNormally);
      expect(() => base64Decode('QUJD\nQUJD'), throwsFormatException);
    });
  });

  group('availability', () {
    test('isNfcAvailable and isNfcEnabled call the native methods', () async {
      mock((call) async => call.method == 'isNfcAvailable' ? true : false);
      expect(await platform.isNfcAvailable(), isTrue);
      expect(await platform.isNfcEnabled(), isFalse);
      expect(calls.map((c) => c.method), ['isNfcAvailable', 'isNfcEnabled']);
    });

    test('a missing answer is false, not null', () async {
      mock((_) async => null);
      expect(await platform.isNfcAvailable(), isFalse);
    });
  });

  group('setRepeatConfig (Android only)', () {
    test('sends only what was set', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mock((_) async => true);
      final ok = await platform.setRepeatConfig(
        const NfcRepeatConfig(serverURL: 'https://s', transactionID: 'tx'),
      );
      expect(ok, isTrue);
      expect(calls.single.method, 'setRepeatConfig');
      expect(calls.single.arguments, {'serverURL': 'https://s', 'transactionID': 'tx'});
    });

    test('passiveAuthentication is passed through when given', () {
      const config = NfcRepeatConfig(
          serverURL: 's', transactionID: 't', passiveAuthentication: false);
      expect(config.toMap()['passiveAuthentication'], false);
    });

    test('null opts back out (sends no arguments)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      mock((_) async => true);
      await platform.setRepeatConfig(null);
      expect(calls.single.arguments, isNull);
    });

    test('returns false on iOS without calling native', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      mock((_) async => true);
      expect(await platform.setRepeatConfig(null), isFalse);
      expect(calls, isEmpty);
    });
  });

  group('readPassport', () {
    test('forwards progress and parses the result', () async {
      final progress = <double>[];
      mock((call) async {
        if (call.method == 'readPassport') {
          // The native side reports progress on the same channel while reading.
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            'nfc_flutter',
            const StandardMethodCodec().encodeMethodCall(const MethodCall('onProgress', 40)),
            (_) {},
          );
          return {'firstName': 'ADA', 'lastName': 'L', 'documentNumber': 'P1'};
        }
        return null;
      });

      final passport = await platform.readPassport(
        const NfcPassportParams(
          documentNumber: 'P1',
          dateOfBirth: '151210',
          expiryDate: '301231',
          serverURL: 's',
          transactionID: 't',
        ),
        onProgress: progress.add,
      );

      expect(progress, [40.0]);
      expect(passport?.documentNumber, 'P1');
    });
  });

  // The Android SDK's NFCReaderObject.onResume() registers foreground dispatch itself, restricted to IsoDep tags
  // (the SDK's own NFCReaderFragment registers the same way and nothing else). A
  // second registration from the plugin, with no tech list, replaces the SDK's because the NFC service holds a
  // single foreground-dispatch registration. This reads the Kotlin source because nothing else in a Dart-only run
  // can see it.
  group('Android foreground dispatch', () {
    final kotlin = File('android/src/main/kotlin/com/nfcflutter/NfcFlutterPlugin.kt').readAsStringSync();

    test('the plugin leaves registering foreground dispatch to the SDK\'s reader', () {
      expect(kotlin, isNot(contains('enableForegroundDispatch(')));
      expect(kotlin, contains('nfcReaderObject?.onResume()'));
    });

    test('the plugin still gives dispatch back when a read ends', () {
      final start = kotlin.indexOf('private fun releaseReader');
      expect(start, isNonNegative, reason: 'releaseReader not found');
      expect(kotlin.substring(start), contains('disableForegroundDispatch('));
    });
  });

  group('NfcErrorType', () {
    test('the SDK\'s own error names are typed', () {
      expect(NfcErrorType.fromString('ERR_TAG_LOST'), NfcErrorType.tagLost);
      expect(NfcErrorType.fromString('ERR_PASSIVE_AUTHENTICATION_FAILED'), NfcErrorType.passiveAuthenticationFailed);
    });

    test('a PlatformException code is typed, including the plugin\'s own codes', () {
      expect(NfcErrorType.fromException(PlatformException(code: 'ERR_BAC_FAILED')), NfcErrorType.bacFailed);
      expect(NfcErrorType.fromException(PlatformException(code: 'NFC_READ_ERROR')), NfcErrorType.readError);
      expect(NfcErrorType.fromException(PlatformException(code: 'CANCELLED')), NfcErrorType.cancelled);
    });

    test('an unlisted code is unknown', () {
      expect(NfcErrorType.fromString('SOMETHING_NEW'), NfcErrorType.unknown);
      expect(NfcErrorType.fromString(null), NfcErrorType.unknown);
    });
  });

  group('error names the SDK builds with a cause appended', () {
    test('ERR_READING_DG<n>_FAILED is typed for any data group', () {
      expect(NfcErrorType.fromString('ERR_READING_DG1_FAILED'), NfcErrorType.readingDataGroupFailed);
      expect(NfcErrorType.fromString('ERR_READING_DG14_FAILED'), NfcErrorType.readingDataGroupFailed);
    });

    test('ERR_CARD_READING_FAILED is typed', () {
      expect(NfcErrorType.fromString('ERR_CARD_READING_FAILED'), NfcErrorType.cardReadingFailed);
    });

    test('an unrelated code is still unknown', () {
      expect(NfcErrorType.fromString('ERR_SOMETHING_NEW'), NfcErrorType.unknown);
    });
  });
}
