import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_call_flutter/video_call_flutter.dart';

Future<void> emit(String method, [Object? arguments]) async {
  Object? failure;
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
    'video_call_flutter',
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

  final platform = MethodChannelVideoCallFlutter();
  const channel = MethodChannel('video_call_flutter');
  final calls = <MethodCall>[];
  Future<Object?> Function(MethodCall call) handler = (_) async => null;

  setUp(() {
    calls.clear();
    handler = (_) async => null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  const base = VideoCallCredentials(
    serverURL: 's', wssURL: 'w', userID: 'u', transactionID: 't', clientName: 'c');

  group('VideoCallCredentials', () {
    test('sends nothing optional unless the app set it (the SDK defaults stand)', () {
      expect(base.toMap().keys.toSet(),
          {'serverURL', 'wssURL', 'userID', 'transactionID', 'clientName', 'idleTimeout'});
    });

    test('cameraFeedFrameRate, observationMode and liveKYCOptions are passed when set', () {
      final map = const VideoCallCredentials(
        serverURL: 's', wssURL: 'w', userID: 'u', transactionID: 't', clientName: 'c',
        cameraFeedFrameRate: 24,
        observationMode: VideoCallObservationMode.screenShare,
        liveKYCOptions: VideoCallLiveKYCOptions(ocrCountry: 'DEU'),
      ).toMap();
      expect(map['cameraFeedFrameRate'], 24);
      expect(map['observationMode'], 'SCREEN_SHARE');
      expect(map['liveKYCOptions'], {'ocrCountry': 'DEU'});
    });

    test('observationMode round-trips', () {
      final restored = VideoCallCredentials.fromMap(
          const VideoCallCredentials(serverURL: 's', wssURL: 'w', userID: 'u', transactionID: 't', clientName: 'c',
              observationMode: VideoCallObservationMode.progressOnly).toMap());
      expect(restored.observationMode, VideoCallObservationMode.progressOnly);
    });
  });

  group('VideoCallLiveKYCOptions uses the SDK\'s own spellings', () {
    test('enum values', () {
      final map = const VideoCallLiveKYCOptions(
        ocrDocumentType: VideoCallOCRDocumentType.driveLicence,
        ocrDocumentSide: VideoCallOCRDocumentSide.backSide,
        faceMethod: VideoCallFaceMethod.imageUpload,
        faceLivenessMode: VideoCallFaceLivenessMode.hybrid,
        nfcChipAnticloneMode: VideoCallNFCChipAnticloneMode.requireCA,
        observationMode: VideoCallObservationMode.cameraFeed,
      ).toMap();
      expect(map, {
        'ocrDocumentType': 'DRIVE_LICENCE',
        'ocrDocumentSide': 'backSide',
        'faceMethod': 'imageUpload',
        'faceLivenessMode': 'hybrid',
        'nfcChipAnticloneMode': 'requireCA',
        'observationMode': 'CAMERA_FEED',
      });
    });

    test('an empty options object is still an (empty) map: its presence is the iOS switch', () {
      expect(const VideoCallLiveKYCOptions().toMap(), isEmpty);
      expect(
        const VideoCallCredentials(serverURL: 's', wssURL: 'w', userID: 'u', transactionID: 't', clientName: 'c',
            liveKYCOptions: VideoCallLiveKYCOptions()).toMap()['liveKYCOptions'],
        isEmpty,
      );
    });
  });

  group('error types', () {
    test('ERR_SDK and the permission errors are typed, not unknown', () {
      expect(VideoCallErrorType.fromString('ERR_SDK'), VideoCallErrorType.sdk);
      expect(VideoCallErrorType.fromString('ERR_CAMERA_PERMISSION_DENIED'), VideoCallErrorType.cameraPermissionDenied);
      expect(VideoCallErrorType.fromString('ERR_CAMERA_PERMISSION_REQUIRED'), VideoCallErrorType.cameraPermissionRequired);
      expect(VideoCallErrorType.fromString('ERR_MICROPHONE_PERMISSION_DENIED'), VideoCallErrorType.microphonePermissionDenied);
      expect(VideoCallErrorType.fromString('ERR_MICROPHONE_PERMISSION_REQUIRED'), VideoCallErrorType.microphonePermissionRequired);
    });

    test('every type round-trips through its string', () {
      for (final type in VideoCallErrorType.values) {
        if (type == VideoCallErrorType.unknown) continue;
        expect(VideoCallErrorType.fromString(type.toString()), type);
      }
    });
  });

  group('status', () {
    test('failed and completed are distinct, known statuses', () {
      expect(VideoCallStatus.fromString('failed'), VideoCallStatus.failed);
      expect(VideoCallStatus.fromString('completed'), VideoCallStatus.completed);
    });

    test('a failed status reaches the status callback', () async {
      VideoCallStatus? seen;
      platform.setOnStatusChanged((s) => seen = s);
      await emit('onStatusChanged', 'failed');
      expect(seen, VideoCallStatus.failed);
    });
  });

  group('events from the native layer', () {
    test('onVideoCallEnded carries the success flag', () async {
      final seen = <bool>[];
      platform.setOnVideoCallEnded(seen.add);
      await emit('onVideoCallEnded', {'success': true});
      await emit('onVideoCallEnded', {'success': false});
      expect(seen, [true, false]);
    });

    test('onVideoCallDismissed reaches its callback (iOS sends it with no payload)', () async {
      var fired = 0;
      platform.setOnVideoCallDismissed(() => fired++);
      await emit('onVideoCallDismissed');
      expect(fired, 1);
    });

    test('microphone state', () async {
      final seen = <bool>[];
      platform.setOnMicrophoneStateChanged(seen.add);
      await emit('onMicrophoneStateChanged', {'enabled': false});
      await emit('onMicrophoneStateChanged', {'enabled': true});
      expect(seen, [false, true]);
    });

    test('phone call state, and an unrecognised one is treated as ended', () async {
      final seen = <VideoCallPhoneCallState>[];
      platform.setOnPhoneCallStateChanged(seen.add);
      await emit('onPhoneCallStateChanged', {'state': 'incoming'});
      await emit('onPhoneCallStateChanged', {'state': 'connected'});
      await emit('onPhoneCallStateChanged', {'state': 'whatever'});
      expect(seen, [VideoCallPhoneCallState.incoming, VideoCallPhoneCallState.connected, VideoCallPhoneCallState.ended]);
    });

    test('screen lock and unlock (no payload)', () async {
      var locked = 0, unlocked = 0;
      platform.setOnScreenLocked(() => locked++);
      platform.setOnScreenUnlocked(() => unlocked++);
      await emit('onScreenLocked');
      await emit('onScreenUnlocked');
      expect([locked, unlocked], [1, 1]);
    });

    test('participant type is delivered when the native layer knows it', () async {
      VideoCallParticipantState? seen;
      platform.setOnParticipantStateChanged((s) => seen = s);
      await emit('onParticipantStateChanged', {'participantType': 'agent', 'state': 'connected'});
      expect(seen?.participantType, 'agent');
      await emit('onParticipantStateChanged', {'participantType': null, 'state': 'disconnected'});
      expect(seen?.participantType, isNull);
    });

    test('an unknown event is ignored instead of throwing', () async {
      await emit('somethingNewInAFutureSdk');
    });
  });

  group('LiveKYC repeat events', () {
    test('started and result carry the role', () async {
      final started = <VideoCallRepeatRole>[], result = <VideoCallRepeatRole>[];
      platform.setOnRepeatStarted(started.add);
      platform.setOnRepeatResult(result.add);
      await emit('onRepeatStarted', {'role': 'OCR'});
      await emit('onRepeatResult', {'role': 'FACE'});
      expect(started, [VideoCallRepeatRole.ocr]);
      expect(result, [VideoCallRepeatRole.face]);
    });

    test('the hologram role the SDK can emit is surfaced, not dropped', () async {
      final started = <VideoCallRepeatRole>[];
      platform.setOnRepeatStarted(started.add);
      await emit('onRepeatStarted', {'role': 'HOLOGRAM'});
      expect(started, [VideoCallRepeatRole.hologram]);
    });

    test('a role this plugin does not know is ignored, not thrown', () async {
      final started = <VideoCallRepeatRole>[];
      platform.setOnRepeatStarted(started.add);
      await emit('onRepeatStarted', {'role': 'SOMETHING_NEW'});
      expect(started, isEmpty);
    });

    test('ended carries role, outcome and reason', () async {
      final ended = <VideoCallRepeatEndedEvent>[];
      platform.setOnRepeatEnded(ended.add);
      await emit('onRepeatEnded', {'role': 'NFC', 'outcome': 'FAILED', 'reason': 'timeout'});
      await emit('onRepeatEnded', {'role': 'OCR', 'outcome': 'COMPLETED'});
      expect(ended[0].role, VideoCallRepeatRole.nfc);
      expect(ended[0].outcome, VideoCallRepeatOutcome.failed);
      expect(ended[0].reason, 'timeout');
      expect(ended[1].outcome, VideoCallRepeatOutcome.completed);
      expect(ended[1].reason, isNull);
    });

    test('ended with no role (the SDK guarantees one, but a wrapper may send "")', () async {
      final ended = <VideoCallRepeatEndedEvent>[];
      platform.setOnRepeatEnded(ended.add);
      await emit('onRepeatEnded', {'role': '', 'outcome': 'CANCELLED'});
      expect(ended.single.role, isNull);
      expect(ended.single.outcome, VideoCallRepeatOutcome.cancelled);
    });

    test('NFC progress is an int percent', () async {
      final seen = <int>[];
      platform.setOnNfcProgress(seen.add);
      await emit('onNfcProgress', {'percent': 40});
      expect(seen, [40]);
    });
  });

  group('cancelVideoCall', () {
    test('success', () async {
      handler = (_) async => {'success': true, 'status': 'disconnected'};
      final result = await platform.cancelVideoCall();
      expect(result.success, isTrue);
      expect(calls.single.method, 'cancelVideoCall');
    });

    test('no active call is a failed result carrying the message, not an exception', () async {
      handler = (_) async => throw PlatformException(code: 'NO_ACTIVE_CALL', message: 'There is no active video call to cancel.');
      final result = await platform.cancelVideoCall();
      expect(result.success, isFalse);
      expect(result.error?.message, contains('no active video call'));
      // The code the plugin raised is readable; the typed value is unknown because it is not an SDK error name.
      expect(result.error?.code, 'NO_ACTIVE_CALL');
      expect(result.error?.type, VideoCallErrorType.unknown);
    });

    test('the native error detail is not replaced by the error code', () async {
      handler = (_) async => throw PlatformException(code: 'CANCEL_VIDEO_CALL_FAILED', message: 'x', details: 'server said no');
      final result = await platform.cancelVideoCall();
      expect(result.error?.details, 'server said no');
    });
  });

  group('the error code the native layer sent is kept', () {
    test('cancel: every code the plugin raises is readable on the result', () async {
      for (final code in ['NO_ACTIVE_CALL', 'ALREADY_IN_PROGRESS', 'CANCEL_VIDEO_CALL_FAILED']) {
        handler = (_) async => throw PlatformException(code: code, message: 'm');
        final result = await platform.cancelVideoCall();
        expect(result.success, isFalse, reason: code);
        expect(result.error?.code, code);
      }
    });

    test('start and end carry the code too', () async {
      handler = (_) async => throw PlatformException(code: 'ALREADY_IN_PROGRESS', message: 'a call is on screen');
      final started = await platform.startVideoCall(base);
      expect(started.error?.code, 'ALREADY_IN_PROGRESS');

      handler = (_) async => throw PlatformException(code: 'END_VIDEO_CALL_FAILED', message: 'x');
      final ended = await platform.endVideoCall();
      expect(ended.error?.code, 'END_VIDEO_CALL_FAILED');
    });

    test('an SDK error name is both the typed value and the code', () async {
      handler = (_) async => throw PlatformException(code: 'ERR_CAMERA_PERMISSION_DENIED', message: 'm');
      final result = await platform.startVideoCall(base);
      expect(result.error?.type, VideoCallErrorType.cameraPermissionDenied);
      expect(result.error?.code, 'ERR_CAMERA_PERMISSION_DENIED');
    });

    test('a failed start that arrives as a result map keeps the type string as its code', () async {
      handler = (_) async => {
            'success': false,
            'status': 'failed',
            'error': {'type': 'ERR_SDK', 'message': 'boom'},
          };
      final result = await platform.startVideoCall(base);
      expect(result.error?.type, VideoCallErrorType.sdk);
      expect(result.error?.code, 'ERR_SDK');
    });

    test('an asynchronous onError event carries it', () async {
      VideoCallError? seen;
      platform.setOnError((e) => seen = e);
      await emit('onError', {'type': 'ERR_MICROPHONE_PERMISSION_REQUIRED', 'message': 'mic'});
      expect(seen?.type, VideoCallErrorType.microphonePermissionRequired);
      expect(seen?.code, 'ERR_MICROPHONE_PERMISSION_REQUIRED');
    });

    test('an explicit code wins over the type, and survives toMap/fromMap', () {
      final error = VideoCallError.fromMap({'type': 'ERR_SDK', 'code': 'SOMETHING_ELSE', 'message': 'm'});
      expect(error.code, 'SOMETHING_ELSE');
      expect(VideoCallError.fromMap(error.toMap()).code, 'SOMETHING_ELSE');
    });

    test('a failure that never reached the native layer has no code', () async {
      // No native side answers, so the channel throws MissingPluginException: not an error the native layer sent.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
      final result = await platform.cancelVideoCall();
      expect(result.error?.code, isNull);
      expect(result.error?.type, VideoCallErrorType.unknown);
    });
  });

  group('microphone', () {
    test('setMicrophoneEnabled sends the flag and returns whether it was accepted', () async {
      handler = (_) async => true;
      expect(await platform.setMicrophoneEnabled(false), isTrue);
      expect(calls.single.arguments, {'enabled': false});
    });

    test('a failure is false, not an exception', () async {
      handler = (_) async => throw PlatformException(code: 'X');
      expect(await platform.setMicrophoneEnabled(true), isFalse);
      expect(await platform.isMicrophoneEnabled(), isFalse);
    });

    test('isMicrophoneEnabled returns the SDK\'s state', () async {
      handler = (_) async => true;
      expect(await platform.isMicrophoneEnabled(), isTrue);
    });
  });

  group('startVideoCall result', () {
    test('a failed start carries the nested error through the channel as a typed error', () async {
      // What the Android plugin replies when the call did not start: the error is a nested map, which the
      // channel delivers as Map<Object?, Object?>, not Map<String, dynamic>.
      handler = (_) async => {
            'success': false,
            'status': 'failed',
            'transactionID': 't',
            'error': {'type': 'ERR_CAMERA_PERMISSION_REQUIRED', 'message': 'camera permission is required'},
          };
      final result = await platform.startVideoCall(base);
      expect(result.success, isFalse);
      expect(result.status, VideoCallStatus.failed);
      expect(result.error?.type, VideoCallErrorType.cameraPermissionRequired);
      expect(result.error?.message, 'camera permission is required');
    });

    test('a successful start has no error', () async {
      handler = (_) async => {'success': true, 'status': 'connecting', 'transactionID': 't'};
      final result = await platform.startVideoCall(base);
      expect(result.success, isTrue);
      expect(result.error, isNull);
    });
  });

  group('VideoCallConfig (the styler)', () {
    test('an empty config sends nothing, so the SDK keeps its own look', () {
      expect(const VideoCallConfig().toMap(), isEmpty);
    });

    test('only what the app set is sent, including inside a style', () {
      final map = const VideoCallConfig(
        backgroundColor: '#112233',
        muteButtonStyle: VideoCallMuteButtonStyle(size: 60),
        pipViewStyle: VideoCallPipViewStyle(cornerRadius: 12),
      ).toMap();
      expect(map, {
        'backgroundColor': '#112233',
        'muteButtonStyle': {'size': 60.0},
        'pipViewStyle': {'cornerRadius': 12.0},
      });
      expect(map.containsKey('textColor'), isFalse);
      expect(map.containsKey('cameraSwitchButtonStyle'), isFalse);
    });

    test('positions and anchors use the spellings the native layers read', () {
      final map = const VideoCallConfig(
        pipViewStyle: VideoCallPipViewStyle(
          horizontalPosition: VideoCallHorizontalPosition(VideoCallHorizontalPositionType.center, offset: -8),
          verticalPosition: VideoCallVerticalPosition(VideoCallVerticalPositionType.custom, y: 40),
          verticalAnchors: VideoCallVerticalAnchors(top: 10, bottom: 20),
        ),
      ).toMap();
      final pip = map['pipViewStyle'] as Map;
      expect(pip['horizontalPosition'], {'type': 'center', 'offset': -8.0});
      expect(pip['verticalPosition'], {'type': 'custom', 'y': 40.0});
      expect(pip['verticalAnchors'], {'top': 10.0, 'bottom': 20.0});
    });

    test('the instruction label sends enum names and skips unset fields', () {
      final label = (const VideoCallConfig(
        instructionLabelStyle: VideoCallInstructionLabelStyle(
          fontWeight: VideoCallFontWeight.semibold,
          textAlign: VideoCallTextAlign.left,
          numberOfLines: 0,
        ),
      ).toMap()['instructionLabelStyle']) as Map;
      expect(label, {'fontWeight': 'semibold', 'textAlign': 'left', 'numberOfLines': 0});
    });

    test('flash button, tableName and requestTimeout are carried', () {
      final map = const VideoCallConfig(
        flashButtonStyle: VideoCallFlashButtonStyle(visible: true),
        tableName: 'VC',
        requestTimeout: 45,
      ).toMap();
      expect(map['flashButtonStyle'], {'visible': true});
      expect(map['tableName'], 'VC');
      expect(map['requestTimeout'], 45.0);
    });

    test('setVideoCallConfig sends that map to the native layer', () async {
      await platform.setVideoCallConfig(const VideoCallConfig(
        textColor: '#FFFFFF',
        cameraSwitchButtonStyle: VideoCallCameraSwitchButtonStyle(color: '#FF00FF00'),
      ));
      expect(calls.single.method, 'setVideoCallConfig');
      expect(Map<String, dynamic>.from(calls.single.arguments as Map), {
        'textColor': '#FFFFFF',
        'cameraSwitchButtonStyle': {'color': '#FF00FF00'},
      });
    });

    test('the flat colour fields round-trip', () {
      final config = VideoCallConfig.fromMap({'backgroundColor': '#000000', 'requestTimeout': 20});
      expect(config.backgroundColor, '#000000');
      expect(config.requestTimeout, 20.0);
      expect(config.pipViewStyle, isNull);
    });
  });

  group('log levels (iOS SDK logging)', () {
    test('nothing is sent unless the app sets one, so the SDK keeps its own', () {
      expect(base.toMap().containsKey('logLevel'), isFalse);
      expect(const VideoCallLiveKYCOptions().toMap(), isEmpty);
    });

    test('the credentials level and each LiveKYC step level use the SDK\'s case names', () {
      final creds = const VideoCallCredentials(
        serverURL: 's', wssURL: 'w', userID: 'u', transactionID: 't', clientName: 'c',
        logLevel: VideoCallLogLevel.debug,
        liveKYCOptions: VideoCallLiveKYCOptions(
          ocrLogLevel: VideoCallLogLevel.error,
          hologramLogLevel: VideoCallLogLevel.warning,
          faceLogLevel: VideoCallLogLevel.verbose,
          nfcLogLevel: VideoCallLogLevel.info,
        ),
      ).toMap();
      expect(creds['logLevel'], 'debug');
      final kyc = creds['liveKYCOptions'] as Map;
      expect(kyc['ocrLogLevel'], 'error');
      expect(kyc['hologramLogLevel'], 'warning');
      expect(kyc['faceLogLevel'], 'verbose');
      expect(kyc['nfcLogLevel'], 'info');
    });

    test('an unknown name parses to null instead of throwing', () {
      expect(VideoCallLogLevel.fromString('warning'), VideoCallLogLevel.warning);
      expect(VideoCallLogLevel.fromString('trace'), isNull);
      expect(VideoCallLogLevel.fromString(null), isNull);
    });
  });
}
