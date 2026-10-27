import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udentify_core_flutter/udentify_core_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelUdentifyCore();
  const channel = MethodChannel('udentify_core_flutter');
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('native error codes survive the Dart layer', () {
    test('a native error keeps its code and message', () async {
      mock((_) async => throw PlatformException(
          code: 'LOAD_CERT_ERROR', message: 'certificate not found'));

      await expectLater(
        platform.loadCertificateFromAssets('cert', 'cer'),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'LOAD_CERT_ERROR')
            .having((e) => e.message, 'message',
                allOf(contains('Failed to load certificate'), contains('certificate not found')))),
      );
    });

    test('it is still catchable as a plain Exception (existing catch blocks)', () async {
      mock((_) async => throw PlatformException(code: 'X', message: 'boom'));
      await expectLater(platform.resetTransactionProperties(), throwsA(isA<Exception>()));
    });
  });

  group('device info sub-path', () {
    test('getDeviceInfoSubPath returns the native value', () async {
      mock((call) async => call.method == 'getDeviceInfoSubPath' ? '/custom/path' : null);
      expect(await platform.getDeviceInfoSubPath(), '/custom/path');
    });

    test('getDeviceInfoSubPath returns null when none is set', () async {
      mock((_) async => null);
      expect(await platform.getDeviceInfoSubPath(), isNull);
    });

    test('setDeviceInfoSubPath sends the sub-path under "subPath"', () async {
      mock((_) async => null);
      await platform.setDeviceInfoSubPath('/api');
      expect(calls.single.method, 'setDeviceInfoSubPath');
      expect(calls.single.arguments, {'subPath': '/api'});
    });

    test('a native failure keeps its code', () async {
      mock((_) async => throw PlatformException(code: 'GET_DEVICE_INFO_SUB_PATH_ERROR', message: 'nope'));
      await expectLater(
        platform.getDeviceInfoSubPath(),
        throwsA(isA<PlatformException>().having((e) => e.code, 'code', 'GET_DEVICE_INFO_SUB_PATH_ERROR')),
      );
    });
  });

  test('fetchTransactionProperties returns the names the native side resolves', () async {
    mock((_) async => ['U18']);
    expect(await platform.fetchTransactionProperties('https://s', 'tx'), ['U18']);
    expect(calls.single.arguments, {'serverURL': 'https://s', 'transactionID': 'tx'});
  });
}
