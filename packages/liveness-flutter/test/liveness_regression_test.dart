import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveness_flutter/liveness_flutter.dart' hide TextStyle;
import 'package:liveness_flutter/src/liveness_flutter_method_channel.dart';

/// Delivers a native -> Dart call the way the platform does, and fails the test if the Dart
/// handler answers with an error (which is how a throwing handler shows up to native).
Future<void> emit(String method, [Object? arguments]) async {
  Object? failure;
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    'liveness_flutter',
    const StandardMethodCodec().encodeMethodCall(MethodCall(method, arguments)),
    (ByteData? reply) {
      if (reply == null) return;
      try {
        const StandardMethodCodec().decodeEnvelope(reply);
      } catch (e) {
        failure = e;
      }
    },
  );
  if (failure != null) fail('Dart answered $method with an error: $failure');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = MethodChannelLivenessFlutter();
  const channel = MethodChannel('liveness_flutter');
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

  group('FaceRecognizerCredentials', () {
    const base = FaceRecognizerCredentials(serverURL: 's', transactionID: 't', userID: 'u');

    test('activeLivenessOpacity is not sent unless set (the plugin\'s own default stays)', () {
      expect(base.toMap().containsKey('activeLivenessOpacity'), isFalse);
    });

    test('activeLivenessOpacity is passed through when set, including 0', () {
      final map = const FaceRecognizerCredentials(
              serverURL: 's', transactionID: 't', userID: 'u', activeLivenessOpacity: 0)
          .toMap();
      expect(map['activeLivenessOpacity'], 0);
      expect(FaceRecognizerCredentials.fromMap(map).activeLivenessOpacity, 0);
    });

    test('the auto-next key is the one both native layers read', () {
      expect(base.toMap()['activeLivenessAutoNextEnabled'], isTrue);
    });
  });

  group('FaceRepeatConfig', () {
    test('only what was set is sent', () {
      final map = const FaceRepeatConfig(serverURL: 's', userID: 'u', transactionID: 't').toMap();
      expect(map.keys.toSet(), {'serverURL', 'userID', 'transactionID'});
    });

    test('the method name is what the native layer upper-cases and matches', () {
      final map = const FaceRepeatConfig(
              serverURL: 's', userID: 'u', transactionID: 't', method: FaceRepeatMethod.activeLiveness, isAuthenticate: true)
          .toMap();
      expect((map['method'] as String).toUpperCase(), 'ACTIVELIVENESS');
      expect(map['isAuthenticate'], isTrue);
    });

    test('opacity 0 is sent (it means "show the camera"), not dropped', () {
      final map = const FaceRepeatConfig(serverURL: 's', userID: 'u', transactionID: 't', activeLivenessOpacity: 0).toMap();
      expect(map['activeLivenessOpacity'], 0);
    });

    test('setRepeatConfig is Android only', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(await platform.setRepeatConfig(null), isFalse);
      expect(calls, isEmpty);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await platform.setRepeatConfig(null), isTrue);
      expect(calls.single.method, 'setRepeatConfig');
    });
  });

  group('permissions', () {
    test('recordAudio is reported but never required', () {
      final status = FaceRecognitionPermissionStatus.fromMap({
        'camera': 'granted',
        'readPhoneState': 'granted',
        'internet': 'granted',
        'recordAudio': 'denied',
      });
      expect(status.recordAudio, LivenessPermissionStatus.denied);
      expect(status.allGranted, isTrue);
    });

    test('a native layer that does not report it still parses', () {
      final status = FaceRecognitionPermissionStatus.fromMap({
        'camera': 'granted', 'readPhoneState': 'granted', 'internet': 'granted',
      });
      expect(status.recordAudio, isNull);
    });
  });

  group('events from the native layer', () {
    test('the iOS lifecycle events are answered, not thrown back at native', () async {
      await emit('onBackButtonPressed');
      await emit('onWillDismiss');
      await emit('onDidDismiss');
    });

    test('an unknown event is ignored instead of throwing', () async {
      await emit('somethingNewInAFutureSdk');
    });

    test('onVideoTaken reaches its callback', () async {
      var fired = 0;
      await platform.setOnVideoTakenCallback(() => fired++);
      await emit('onVideoTaken');
      expect(fired, 1);
    });

    test('the end of an active or hybrid recording fires the photo and the video callback once each', () async {
      final seen = <String>[];
      await platform.setOnPhotoTakenCallback(() => seen.add('photo'));
      await platform.setOnVideoTakenCallback(() => seen.add('video'));
      // Both platforms send these two events, in this order, when the recording ends.
      await emit('onPhotoTaken');
      await emit('onVideoTaken');
      expect(seen, ['photo', 'video']);
    });
  });

  group('typed results are populated from the flattened native map', () {
    Future<FaceRecognitionResult> resultFor(Map<String, Object?> raw) async {
      late FaceRecognitionResult captured;
      await platform.setOnResultCallback((r) => captured = r);
      await emit('onResult', raw);
      return captured;
    }

    test('face id fields', () async {
      final result = await resultFor({
        'isFailed': false,
        'verified': true,
        'matchScore': 0.93,
        'description': 'match',
        'transactionID': 'tx',
        'userID': 'u',
      });
      final message = result.faceIDMessage!;
      expect(message.success, isTrue);
      expect(message.faceIDResult?.verified, isTrue);
      expect(message.faceIDResult?.matchScore, 0.93);
      expect(message.faceIDResult?.transactionID, 'tx');
      expect(message.livenessResult, isNull);
    });

    test('liveness fields, and ints are accepted as doubles', () async {
      final result = await resultFor({
        'isFailed': false,
        'assessmentValue': 1,
        'assessmentDescription': 'live',
        'probability': 0.99,
        'quality': 0.8,
        'livenessScore': 1,
      });
      final liveness = result.faceIDMessage!.livenessResult!;
      expect(liveness.assessmentValue, 1.0);
      expect(liveness.livenessScore, 1.0);
      expect(liveness.probability, 0.99);
    });

    test('active liveness: the Android gesture results are "true"/"false" strings, iOS sends booleans', () async {
      late FaceRecognitionResult captured;
      await platform.setOnActiveLivenessResultCallback((r) => captured = r);
      // The map the Android plugin builds from FaceIDMessage: the enum is its name, nested results are
      // flattened to the top level, and gestureResult is a map with the SDK's string values.
      await emit('onActiveLivenessResult', {
        'isFailed': false,
        'method': 'ActiveLiveness',
        'transactionID': 'tx',
        'gestureResult': {'1': 'true', '2': 'false'},
      });
      final gestures = captured.faceIDMessage!.activeLivenessResult!.gestureResult;
      expect(gestures['1'], isTrue);
      expect(gestures['2'], isFalse);
      expect(captured.faceIDMessage!.data?['method'], 'ActiveLiveness');

      await emit('onActiveLivenessResult', {
        'isFailed': false,
        'gestureResult': {'1': true, '2': false},
      });
      final ios = captured.faceIDMessage!.activeLivenessResult!.gestureResult;
      expect(ios['1'], isTrue);
      expect(ios['2'], isFalse);
    });

    test('the raw map is still delivered untouched', () async {
      final raw = {'isFailed': false, 'verified': true, 'matchScore': 1.0, 'somethingElse': 7};
      final result = await resultFor(raw);
      expect(result.faceIDMessage!.data, raw);
    });

    test('a failure is reported as one', () async {
      final result = await resultFor({'isFailed': true, 'verified': false, 'matchScore': 0});
      expect(result.status, FaceRecognitionStatus.error);
      expect(result.faceIDMessage!.success, isFalse);
    });

    test('only an explicit isFailed: false is a success', () async {
      final result = await resultFor({'isFailed': false, 'verified': true, 'matchScore': 1.0});
      expect(result.status, FaceRecognitionStatus.success);
      expect(result.faceIDMessage!.success, isTrue);
      expect(result.faceIDMessage!.isFailed, isFalse);
    });

    test('a result without a verdict is a failure, never a success', () async {
      final unreadable = <Map<String, Object?>>[
        <String, Object?>{}, // a response that could not be read
        {'isFailed': null}, // the SDK's boxed Boolean left unset
        {'isFailed': 'false'}, // not a boolean
        {'verified': true, 'matchScore': 1.0}, // data, but no verdict
      ];
      for (final raw in unreadable) {
        final result = await resultFor(raw);
        expect(result.status, FaceRecognitionStatus.error, reason: '$raw');
        expect(result.faceIDMessage!.success, isFalse, reason: '$raw');
        expect(result.faceIDMessage!.isFailed, isTrue, reason: '$raw');
        expect(result.faceIDMessage!.message, 'The SDK result could not be read', reason: '$raw');
      }
    });

    test('the same rule holds for active and hybrid liveness results', () async {
      late FaceRecognitionResult captured;
      await platform.setOnActiveLivenessResultCallback((r) => captured = r);

      await emit('onActiveLivenessResult', <String, Object?>{});
      expect(captured.status, FaceRecognitionStatus.error);
      expect(captured.faceIDMessage!.isFailed, isTrue);

      await emit('onActiveLivenessResult', {
        'isFailed': false,
        'gestureResult': {'0': 'true'},
      });
      expect(captured.status, FaceRecognitionStatus.success);
      expect(captured.faceIDMessage!.activeLivenessResult!.gestureResult, {'0': true});
    });

    test('an unrecognised payload leaves the typed results null instead of throwing', () async {
      final result = await resultFor({'isFailed': false, 'unrelated': true});
      expect(result.faceIDMessage!.faceIDResult, isNull);
      expect(result.faceIDMessage!.livenessResult, isNull);
      expect(result.faceIDMessage!.activeLivenessResult, isNull);
    });
  });

  group('errors nested in a result keep the SDK\'s message', () {
    // The shape the iOS layer builds for a failed photo register/authenticate and for the ID-camera flow:
    // the SDK's FaceIDResult / LivenessResult carry the error at `faceIDResult.error` and `livenessResult.error`.
    const nested = {'code': 'ERR_FACEKEY_NO_FACE', 'message': 'No face was found in the photo'};

    test('FaceIDResult and LivenessResult read the nested error\'s code and message', () {
      final result = FaceRecognitionResult.fromMap({
        'status': 'failure',
        'faceIDMessage': {
          'success': false,
          'isFailed': true,
          'faceIDResult': {'verified': false, 'matchScore': 0, 'description': 'd', 'error': nested},
          'livenessResult': {'assessmentValue': 0, 'error': nested},
        },
      });
      for (final error in [result.faceIDMessage!.faceIDResult!.error!, result.faceIDMessage!.livenessResult!.error!]) {
        expect(error.code, 'ERR_FACEKEY_NO_FACE');
        expect(error.message, 'No face was found in the photo');
        expect(error.type, LivenessErrorType.facekeyNoFace);
      }
    });

    test('ActiveLivenessResult reads the nested error the same way', () {
      final result = ActiveLivenessResult.fromMap({'gestureResult': <String, bool>{}, 'error': nested});
      expect(result.error!.message, 'No face was found in the photo');
    });

    // Dart reads `message`, as every other error map of the plugin does. The Swift side must therefore send
    // `message`. This reads the Swift source because nothing else in a Dart-only run can see the keys the iOS
    // layer builds.
    test('every error map the iOS layer builds uses code and message, never description', () {
      final swift = File('ios/Classes/LivenessFlutterPlugin.swift').readAsStringSync();
      final blocks = RegExp(r'(?:\["error"\] = |"error": )\[([^\]]*)\]').allMatches(swift).toList();
      expect(blocks.length, greaterThanOrEqualTo(9), reason: 'the pattern no longer finds the error maps');
      for (final block in blocks) {
        final body = block.group(1)!;
        expect(body, contains('"code":'), reason: body);
        expect(body, contains('"message":'), reason: body);
        expect(body, isNot(contains('"description":')), reason: body);
      }
    });
  });

  group('LivenessErrorType', () {
    test('the SDK\'s own error names are typed', () {
      expect(const FaceRecognitionError(code: 'ERR_FACEKEY_NOT_ALIVE', message: 'm').type, LivenessErrorType.facekeyNotAlive);
      expect(const FaceRecognitionError(code: 'ERR_FACE_PHOTO_MISSING', message: 'm').type, LivenessErrorType.facePhotoMissing);
    });

    test('the codes the plugin sends itself are typed too', () {
      expect(LivenessErrorType.fromString('ERR_SDK'), LivenessErrorType.sdk);
      expect(LivenessErrorType.fromString('FACE_RECOGNITION_ERROR'), LivenessErrorType.faceRecognition);
    });

    test('an unlisted code is unknown and the raw code is kept', () {
      const e = FaceRecognitionError(code: 'SOMETHING_NEW', message: 'm');
      expect(e.type, LivenessErrorType.unknown);
      expect(e.code, 'SOMETHING_NEW');
    });
  });
}
