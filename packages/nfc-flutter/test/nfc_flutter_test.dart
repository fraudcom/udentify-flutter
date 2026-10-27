import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_flutter/nfc_flutter_method_channel.dart';
import 'package:nfc_flutter/nfc_flutter_platform_interface.dart';

void main() {
  test('the method channel is the default platform instance', () {
    expect(NfcFlutterPlatform.instance, isInstanceOf<MethodChannelNfcFlutter>());
  });
}
