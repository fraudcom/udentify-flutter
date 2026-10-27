import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_flutter/ocr_flutter.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOcrFlutterPlatform extends OcrFlutterPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String> takePhoto() => Future.value('mock-photo-base64');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final OcrFlutterPlatform initialPlatform = OcrFlutterPlatform.instance;

  test('$MethodChannelOcrFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOcrFlutter>());
  });

  test('takePhoto', () async {
    final MockOcrFlutterPlatform fakePlatform = MockOcrFlutterPlatform();
    OcrFlutterPlatform.instance = fakePlatform;

    expect(await OcrFlutter.takePhoto(), 'mock-photo-base64');
  });
}
