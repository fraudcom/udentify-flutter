import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_flutter/nfc_flutter.dart';
import 'package:nfc_flutter/nfc_flutter_platform_interface.dart';
import 'package:nfc_flutter/nfc_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNfcFlutterPlatform
    with MockPlatformInterfaceMixin
    implements NfcFlutterPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NfcFlutterPlatform initialPlatform = NfcFlutterPlatform.instance;

  test('$MethodChannelNfcFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNfcFlutter>());
  });

  test('getPlatformVersion', () async {
    NfcFlutter nfcFlutterPlugin = NfcFlutter();
    MockNfcFlutterPlatform fakePlatform = MockNfcFlutterPlatform();
    NfcFlutterPlatform.instance = fakePlatform;

    expect(await nfcFlutterPlugin.getPlatformVersion(), '42');
  });
}
