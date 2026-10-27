import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrz_flutter/mrz_flutter.dart';
import 'package:mrz_flutter/mrz_flutter_method_channel.dart';
import 'package:mrz_flutter/src/models/mrz_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('error types', () {
    test('the SDK\'s SDK_NOT_AVAILABLE and USER_CANCELLED are no longer "unknown"', () {
      expect(MrzError.fromMap({'type': 'SDK_NOT_AVAILABLE'}).type, MrzErrorType.sdkNotAvailable);
      expect(MrzError.fromMap({'type': 'USER_CANCELLED'}).type, MrzErrorType.userCancelled);
    });

    test('the existing types still parse', () {
      expect(MrzError.fromMap({'type': 'ERR_MRZ_NOT_FOUND'}).type, MrzErrorType.mrzNotFound);
      expect(MrzError.fromMap({'type': 'PERMISSION_DENIED'}).type, MrzErrorType.permissionDenied);
      expect(MrzError.fromMap({'type': 'CAMERA_ERROR'}).type, MrzErrorType.cameraError);
    });

    test('anything else is unknown', () {
      expect(MrzError.fromMap({'type': 'SOMETHING_NEW'}).type, MrzErrorType.unknown);
    });
  });

  group('a failure keeps the SDK\'s error name', () {
    final platform = MethodChannelMrzFlutter();
    const channel = MethodChannel('mrz_flutter');

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('processMrzImage reports ERR_MRZ_NOT_FOUND as a typed failure, not a cancel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'ERR_MRZ_NOT_FOUND', message: 'The MRZ could not be read: ERR_MRZ_NOT_FOUND');
      });
      final result = await platform.processMrzImage(imageBase64: 'abc');
      expect(result.success, isFalse);
      expect(result.errorCode, 'ERR_MRZ_NOT_FOUND');
      expect(result.errorType, MrzErrorType.mrzNotFound);
    });

    test('a user cancel is still a cancel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'USER_CANCELLED', message: 'MRZ scanning was cancelled');
      });
      final result = await platform.startMrzCamera();
      expect(result.errorType, MrzErrorType.userCancelled);
    });

    test('a success has no error code', () async {
      expect(MrzResult.success(MrzData(documentType: 'P', issuingCountry: 'TUR', documentNumber: '1', dateOfBirth: '900101', gender: 'M', dateOfExpiration: '300101', nationality: 'TUR', surname: 'S', givenNames: 'G')).errorCode, isNull);
    });
  });

  group('MrzUICustomization', () {
    test('sends only what was set, so omitted fields keep the default look', () {
      expect(const MrzUICustomization().toMap(), isEmpty);
      expect(
        const MrzUICustomization(instructionText: 'Scan', showCancelButton: false, focusViewStrokeWidth: 5).toMap(),
        {'instructionText': 'Scan', 'showCancelButton': false, 'focusViewStrokeWidth': 5},
      );
    });

    test('colors are sent as the hex strings the native layer parses', () {
      final map = const MrzUICustomization(focusViewBorderColor: '#007AFF', cancelButtonColor: '#FF0000').toMap();
      expect(map['focusViewBorderColor'], '#007AFF');
      expect(map['cancelButtonColor'], '#FF0000');
    });
  });

  group('startMrzCamera', () {
    final platform = MethodChannelMrzFlutter();
    const channel = MethodChannel('mrz_flutter');
    final calls = <MethodCall>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return {'success': false, 'errorMessage': 'USER_CANCELLED', 'cancelled': true};
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('passes the appearance to the native layer', () async {
      await platform.startMrzCamera(uiCustomization: const MrzUICustomization(instructionText: 'Scan'));
      final args = calls.single.arguments as Map;
      expect(args['mode'], 'accurate');
      expect(args['uiCustomization'], {'instructionText': 'Scan'});
    });

    test('sends none when not given', () async {
      await platform.startMrzCamera();
      expect((calls.single.arguments as Map).containsKey('uiCustomization'), isFalse);
    });

    test('a cancelled scan is a failed result, not an exception', () async {
      final result = await platform.startMrzCamera();
      expect(result.success, isFalse);
    });
  });
}
