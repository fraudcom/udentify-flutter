import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_flutter/ocr_flutter.dart';
import 'package:ocr_flutter/ocr_flutter_platform_interface.dart';
import 'package:ocr_flutter/ocr_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOcrFlutterPlatform
    with MockPlatformInterfaceMixin
    implements OcrFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final OcrFlutterPlatform initialPlatform = OcrFlutterPlatform.instance;

  test('$MethodChannelOcrFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOcrFlutter>());
  });

  test('getPlatformVersion', () async {
    OcrFlutter ocrFlutterPlugin = OcrFlutter();
    MockOcrFlutterPlatform fakePlatform = MockOcrFlutterPlatform();
    OcrFlutterPlatform.instance = fakePlatform;

    expect(await ocrFlutterPlugin.getPlatformVersion(), '42');
  });
}
