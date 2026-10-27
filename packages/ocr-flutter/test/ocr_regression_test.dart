import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_flutter/ocr_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('requestTimeout on the perform params', () {
    test('is sent as given, and as 30 (the SDKs\' own default) when the app sets none', () {
      expect(
        OCRProcessParams(serverURL: 's', transactionID: 't', documentType: OCRDocumentType.idCard, requestTimeout: 45)
            .toMap()['requestTimeout'],
        45,
      );
      expect(
        OCRProcessParams(serverURL: 's', transactionID: 't', documentType: OCRDocumentType.idCard).toMap()['requestTimeout'],
        30,
      );
      expect(DocumentLivenessParams(serverURL: 's', transactionID: 't', requestTimeout: 60).toMap()['requestTimeout'], 60);
      expect(DocumentLivenessParams(serverURL: 's', transactionID: 't').toMap()['requestTimeout'], 30);
      expect(
        OCRAndDocumentLivenessParams(serverURL: 's', transactionID: 't', documentType: OCRDocumentType.idCard, requestTimeout: 20)
            .toMap()['requestTimeout'],
        20,
      );
    });
  });

  group('IQA feedback', () {
    // One vocabulary for both platforms: the earlier Android spellings (chipAbsent /
    // signatureAbsent / hiddenPhotoAbsent) read as "other".
    const sdkNames = [
      'success', 'blurDetected', 'glareDetected', 'hologramGlare', 'cardNotDetected',
      'cardClassificationMismatch', 'cardNotIntact', 'faceNotDetected',
      'multipleDocumentsDetected', 'chipNotDetected', 'signatureNotDetected', 'modelFailed',
      'hiddenPhotoNotDetected', 'photoCheatDetected', 'other',
    ];

    test('the enum covers every value the native layers send', () {
      expect(IQAFeedback.values.map((e) => e.value).toSet(), sdkNames.toSet());
    });

    for (final name in sdkNames) {
      test('"$name" is not collapsed to other', () {
        final result = IQAResult.fromMap({'feedback': name, 'documentSide': 'frontSide'});
        expect(result.feedback.value, name);
      });
    }

    test('the old Android spellings are unknown, so they fall back to other', () {
      for (final legacy in ['chipAbsent', 'signatureAbsent', 'hiddenPhotoAbsent']) {
        expect(IQAResult.fromMap({'feedback': legacy}).feedback, IQAFeedback.other);
      }
    });

    test('the SDK\'s displayMessage is preferred over the wrapper\'s text', () {
      final result = IQAResult.fromMap({
        'feedback': 'blurDetected',
        'message': 'Image is blurry',
        'displayMessage': 'Hold the phone steady',
      });
      expect(result.message, 'Hold the phone steady');
    });

    test('the wrapper\'s text is the fallback when the SDK supplies none', () {
      expect(IQAResult.fromMap({'feedback': 'x', 'message': 'Image is blurry', 'displayMessage': ''}).message,
          'Image is blurry');
      expect(IQAResult.fromMap({'feedback': 'x', 'rawMessage': 'raw'}).message, 'raw');
      expect(IQAResult.fromMap({'feedback': 'x'}).message, '');
    });
  });

  group('OCRRepeatConfig', () {
    test('defaults to Turkey / ID card, the SDK\'s own defaults', () {
      final map = const OCRRepeatConfig(serverURL: 's', userID: 'u', transactionID: 't').toMap();
      expect(map['country'], 'TUR');
      expect(map['documentType'], 'ID_CARD');
      expect(map.containsKey('documentSide'), isFalse);
      expect(map.containsKey('cardOrientation'), isFalse);
    });

    test('documentSide is sent in the spelling the native layer parses', () {
      expect(
        const OCRRepeatConfig(serverURL: 's', userID: 'u', transactionID: 't', documentSide: OCRRepeatDocumentSide.back)
            .toMap()['documentSide'],
        'BACK',
      );
    });
  });

  group('setRepeatConfig (Android only)', () {
    final platform = MethodChannelOcrFlutter();
    const channel = MethodChannel('ocr_flutter');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return true;
      });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('opts in on Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final ok = await platform.setRepeatConfig(const OCRRepeatConfig(serverURL: 's', userID: 'u', transactionID: 't'));
      expect(ok, isTrue);
      expect(calls.single.method, 'setRepeatConfig');
      expect((calls.single.arguments as Map)['transactionID'], 't');
    });

    test('null opts back out', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await platform.setRepeatConfig(null);
      expect(calls.single.arguments, isNull);
    });

    test('is a no-op returning false on iOS', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await platform.setRepeatConfig(null), isFalse);
      expect(calls, isEmpty);
    });
  });

  group('performIQA country', () {
    final platform = MethodChannelOcrFlutter();
    const channel = MethodChannel('ocr_flutter');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return {'qualified': true};
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    Future<void> iqa({String? country}) => country == null
        ? platform.performIQA(
            serverURL: 's', transactionID: 't', imageBase64: 'i', documentType: 'ID_CARD', documentSide: 'FRONT')
        : platform.performIQA(
            serverURL: 's',
            transactionID: 't',
            imageBase64: 'i',
            documentType: 'ID_CARD',
            documentSide: 'FRONT',
            country: country);

    test('the country the app passes goes to the native layer, and TUR when it passes none', () async {
      await iqa(country: 'GBR');
      expect((calls.last.arguments as Map)['country'], 'GBR');
      await iqa();
      expect((calls.last.arguments as Map)['country'], 'TUR');
    });

    // Dart sends the country; the iOS layer must hand it to the SDK and not a fixed country. This reads the Swift
    // source because nothing else in a Dart-only run can see what the iOS layer passes.
    test('the iOS layer passes the requested country to the SDK, not a fixed one', () {
      final swift = File('ios/Classes/OcrFlutterPlugin.swift').readAsStringSync();
      final start = swift.indexOf('private func handlePerformIQA');
      final end = swift.indexOf('// MARK: - Take Photo');
      expect(start, isNonNegative, reason: 'handlePerformIQA not found');
      expect(end, greaterThan(start), reason: 'the end of handlePerformIQA not found');
      final body = swift.substring(start, end);
      expect(body, contains('CountryCodeMapper.toCountry(country)'));
      expect(body, isNot(matches(RegExp(r'forCountry:\s*\.\w+'))), reason: 'a country literal is passed to the SDK');
      expect(body, isNot(matches(RegExp(r'Country\s*=\s*\.[A-Z]{3}'))), reason: 'a country literal is assigned');
    });
  });

  group('rawPhotoCropRatio', () {
    test('the UI config and the camera params both send the value they were given, and null when unset', () {
      expect(OCRUIConfig(rawPhotoCropRatio: 0.5).toMap()['rawPhotoCropRatio'], 0.5);
      expect(OCRCameraParams(serverURL: 's', transactionID: 't', documentType: OCRDocumentType.idCard, rawPhotoCropRatio: 0.29)
              .toMap()['rawPhotoCropRatio'],
          0.29);
      expect(OCRUIConfig().toMap()['rawPhotoCropRatio'], isNull);
    });

    // The Android SDK takes the crop as a whole percentage, the Dart API as the 0.0-1.0 ratio iOS uses. The
    // UI-config value and the camera param both reach the builder, and the conversion rounds (0.29 * 100 is
    // 28.999999999999996, which must give 29%, not 28%). This reads the Kotlin sources because nothing else in a
    // Dart-only run can see what the Android layer hands to the SDK.
    group('the Android layer', () {
      final ui = File('android/src/main/kotlin/com/ocrflutter/UIConfigurationManager.kt').readAsStringSync();
      final camera = File('android/src/main/kotlin/com/ocrflutter/OcrCameraManager.kt').readAsStringSync();

      test('reads the UI-config value and hands it to the credentials builder', () {
        final start = ui.indexOf('fun applyUIConfigToBuilder');
        expect(start, isNonNegative, reason: 'applyUIConfigToBuilder not found');
        final body = ui.substring(start);
        expect(body, contains('"rawPhotoCropRatio"'));
        expect(body, contains('builder.rawPhotoCropRatio('));
      });

      test('the camera param still applies, after the UI config, so it wins as it does on iOS', () {
        final applyUi = camera.indexOf('uiConfigManager.applyUIConfigToBuilder(builder)');
        final applyParam = camera.indexOf('builder.rawPhotoCropRatio(');
        expect(applyUi, isNonNegative);
        expect(applyParam, greaterThan(applyUi));
      });

      test('both convert the ratio to a percentage by rounding, never by truncating', () {
        expect(ui, contains('roundToInt()'));
        expect(camera, isNot(contains('* 100).toInt()')));
        expect(ui, isNot(contains('* 100).toInt()')));
      });
    });
  });

  group('driver licence response', () {
    test('booleans that arrive as strings do not throw a cast error', () {
      final response = DriverLicenseOCRResponse.fromMap({
        'documentType': 'DRIVE_LICENCE',
        'isOCRDocumentExpired': 'true',
        'isOCRIDValid': 'false',
        'hasOCRSignature': true,
        'ocrQRApproved': 'true',
      });
      expect(response.isOCRDocumentExpired, isTrue);
      expect(response.isOCRIDValid, isFalse);
      expect(response.hasOCRSignature, isTrue);
      expect(response.ocrQRApproved, isTrue);
    });
  });

  group('OCR + document liveness result shape (the one every Android path sends)', () {
    test('parses the camera, performDocumentLiveness and performOCRAndDocumentLiveness shape', () {
      // Built by OcrCameraManager.buildLivenessResultMap on Android, which now serves all three paths.
      final response = OCRAndDocumentLivenessResponse.fromMap({
        'isFailed': false,
        'ocrData': {
          'ocrResponse': {'responseType': 'idCard', 'success': true},
        },
        'documentLivenessDataFront': {
          'documentLivenessResponse': {
            'aggregateDocumentLivenessProbability': '0.91',
            'aggregateDocumentImageQualityWarnings': 'none',
            'pipelineResults': [
              {
                'name': 'front',
                'calibration': 'c1',
                'documentLivenessScore': '12.5',
                'documentLivenessProbability': '0.91',
                'documentStatusCode': '0',
              }
            ],
          },
          'error': null,
        },
        'documentLivenessDataBack': null,
      });
      expect(response.isFailed, isFalse);
      expect(response.ocrData?.ocrResponse?.success, isTrue);
      final front = response.documentLivenessDataFront?.documentLivenessResponse;
      expect(front?.aggregateDocumentLivenessProbability, '0.91');
      expect(front?.pipelineResults?.single.name, 'front');
      expect(front?.pipelineResults?.single.documentStatusCode, '0');
      expect(response.documentLivenessDataBack, isNull);
    });
  });

  group('error codes', () {
    // The names the Android SDK ships as string resources and the iOS SDK's OCRError maps to.
    const sdkCodes = {
      'ERR_OCR_API_ERROR': OCRErrorType.ocrApiError,
      'ERR_OCR_OTHER_ERROR': OCRErrorType.ocrOtherError,
      'ERR_OCR_MISSING_RESPONSE': OCRErrorType.ocrMissingResponse,
      'ERR_OCR_MISSING_DOCUMENT_LIVENESS_RESPONSE': OCRErrorType.ocrMissingDocumentLivenessResponse,
      'ERR_OCR_MISSING_PARAMETERS': OCRErrorType.ocrMissingParameters,
      'ERR_FAILED_DUE_TO_THRESHOLD': OCRErrorType.failedDueToThreshold,
      'ERR_FAILED_TO_TAKE_PHOTO': OCRErrorType.failedToTakePhoto,
      'ERR_ID_CARD_PHOTO_MISSING': OCRErrorType.idCardPhotoMissing,
      'ERR_PHONE_STATE_PERMISSION_REQUIRED': OCRErrorType.phoneStatePermissionRequired,
    };

    test('the SDK\'s own error names are typed, not unknown', () {
      sdkCodes.forEach((code, type) {
        expect(OCRErrorType.fromString(code), type, reason: code);
        expect(OCRException.fromError(code, 'm').type, type, reason: code);
      });
    });

    test('the codes the enum had before still parse', () {
      expect(OCRErrorType.fromString('ERR_CAMERA_PERMISSION_REQUIRED'), OCRErrorType.cameraPermissionRequired);
      expect(OCRErrorType.fromString('ERR_UNKNOWN'), OCRErrorType.unknown);
    });

    test('a code the enum does not list stays readable on the exception', () {
      final e = OCRException.fromError('INVALID_ARGUMENTS', 'bad');
      expect(e.type, OCRErrorType.unknown);
      expect(e.code, 'INVALID_ARGUMENTS');
    });
  });

  group('failure events carry the SDK error name', () {
    Future<void> emitToPlugin(String method, Object? args) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
        'ocr_flutter',
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );
    }

    setUp(() => MethodChannelOcrFlutter());
    tearDown(() => MethodChannelOcrFlutter.clearAllCallbacks());

    test('the typed callback gets code and type, the string callback still gets the message', () async {
      OCRFailure? typed;
      String? plain;
      OcrFlutter.setOnOCRErrorCallback((f) => typed = f);
      OcrFlutter.setOnOCRFailureCallback((m) => plain = m);
      await emitToPlugin('onOCRFailure', {'error': 'ERR_OCR_API_ERROR', 'errorCode': 'ERR_OCR_API_ERROR'});
      expect(plain, 'ERR_OCR_API_ERROR');
      expect(typed?.code, 'ERR_OCR_API_ERROR');
      expect(typed?.type, OCRErrorType.ocrApiError);
    });

    test('a failure with no SDK name has no code and reads unknown', () async {
      OCRFailure? typed;
      OcrFlutter.setOnHologramErrorCallback((f) => typed = f);
      await emitToPlugin('onHologramFailure', {'error': 'Failed to convert result'});
      expect(typed?.code, isNull);
      expect(typed?.type, OCRErrorType.unknown);
      expect(typed?.message, 'Failed to convert result');
    });

    test('the camera progress events (onCardScanFinished, onPhotoTaken) are accepted and fire no callback', () async {
      var fired = false;
      OcrFlutter.setOnOCRFailureCallback((_) => fired = true);
      OcrFlutter.setOnBackButtonPressedCallback(() => fired = true);
      await emitToPlugin('onCardScanFinished', null);
      await emitToPlugin('onPhotoTaken', null);
      expect(fired, isFalse);
    });

    test('only the typed callback registered still works', () async {
      OCRFailure? typed;
      OcrFlutter.setOnOCRAndDocumentLivenessErrorCallback((f) => typed = f);
      await emitToPlugin('onOCRAndDocumentLivenessFailure', {'error': 'ERR_FAILED_DUE_TO_THRESHOLD', 'errorCode': 'ERR_FAILED_DUE_TO_THRESHOLD'});
      expect(typed?.type, OCRErrorType.failedDueToThreshold);
    });
  });

  test('the dead IQA listener stubs are still callable (deprecated, source compatible)', () {
    // ignore: deprecated_member_use_from_same_package, deprecated_member_use
    final remove = addIQAResultListener((_) {});
    expect(remove, isA<Function>());
  });
}
