import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_flutter/ocr_flutter_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelOcrFlutter platform = MethodChannelOcrFlutter();
  const MethodChannel channel = MethodChannel('ocr_flutter');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('takePhoto', () async {
    expect(await platform.takePhoto(), '42');
  });
}
