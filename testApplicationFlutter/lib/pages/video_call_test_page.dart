import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveness_flutter/liveness_flutter.dart' hide TextStyle;
import 'package:nfc_flutter/nfc_flutter.dart';
import 'package:ocr_flutter/ocr_flutter.dart';
import 'package:video_call_flutter/video_call_flutter.dart';
import '../services/call_overlay.dart';
import '../utils/api_utils.dart';
import '../models/app_constants.dart';

class VideoCallTestPage extends StatefulWidget {
  final String pageId;
  
  const VideoCallTestPage({super.key, required this.pageId});

  @override
  State<VideoCallTestPage> createState() => _VideoCallTestPageState();
}

class _VideoCallTestPageState extends State<VideoCallTestPage> {
  // Server configuration from AppConstants
  static const String _serverUrl = AppConstants.serverUrl;
  static const String _wssUrl = AppConstants.wssUrl;
  static const String _clientName = AppConstants.clientName;
  static const String _idleTimeout = AppConstants.idleTimeout;

  // Form controller for user ID (needs to be unique per test)
  final TextEditingController _userIdController = TextEditingController(
      text: "user_${DateTime.now().millisecondsSinceEpoch}");

  // Note: Transaction ID should be obtained from API when needed

  // State variables
  String _status = "Ready";
  VideoCallStatus _currentStatus = VideoCallStatus.idle;
  VideoCallPermissionStatus? _permissions;
  bool _isInCall = false;
  bool _isMicrophoneEnabled = true;
  bool _liveKycEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupCallbacks();
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  void _setupCallbacks() {
    VideoCallFlutter.setOnStatusChanged((status) {
      setState(() {
        _currentStatus = status;
        _status = "Status: ${status.toString()}";
        if (status == VideoCallStatus.connected) {
          _isInCall = true;
        } else if (status == VideoCallStatus.disconnected ||
            status == VideoCallStatus.completed ||
            status == VideoCallStatus.failed) {
          _isInCall = false;
          CallOverlay.hide();
        }
      });
    });

    VideoCallFlutter.setOnError((error) {
      CallOverlay.hide();
      setState(() {
        _status = "Error: ${error.message}";
        _isInCall = false;
      });
      // The safety net: a permission revoked after the pre-flight check, or refused in between.
      if (error.type == VideoCallErrorType.cameraPermissionRequired ||
          error.type == VideoCallErrorType.cameraPermissionDenied ||
          error.type == VideoCallErrorType.microphonePermissionRequired ||
          error.type == VideoCallErrorType.microphonePermissionDenied) {
        _showPermissionDialog();
      }
    });

    // The SDK reports every microphone change (in-call button, agent signal,
    // automatic mutes), so the UI follows this event rather than assuming a
    // setMicrophoneEnabled request was applied.
    VideoCallFlutter.setOnMicrophoneStateChanged((enabled) {
      setState(() {
        _isMicrophoneEnabled = enabled;
        _status = "Microphone ${enabled ? "enabled" : "disabled"}";
      });
    });

    VideoCallFlutter.setOnPhoneCallStateChanged((state) {
      setState(() => _status = "Phone call: ${state.name}");
    });

    // The end-call button is the app's own native overlay (see CallOverlay); it only reports the tap.
    CallOverlay.setOnPressed(_onEndCallPressed);
    VideoCallFlutter.setOnVideoCallEnded((_) => CallOverlay.hide());
    VideoCallFlutter.setOnVideoCallDismissed(() => CallOverlay.hide());

    // The SDK's capture screen takes over the call while a LiveKYC repeat runs, so the app's end-call button goes
    // away for it and comes back when the repeat ends. It returns on ended, not on
    // result: a repeat the operator cancels never produces a result, and the call would be left without a button.
    VideoCallFlutter.setOnRepeatStarted((role) {
      CallOverlay.hide();
      setState(() => _status = "Repeat started: ${role.name}");
    });

    VideoCallFlutter.setOnRepeatEnded((event) {
      if (_isInCall && !_endingFromButton) CallOverlay.show();
      setState(() => _status =
          "Repeat ended: ${event.role?.name} ${event.outcome?.name}${event.reason != null ? ' (${event.reason})' : ''}");
    });

    VideoCallFlutter.setOnNfcProgress((percent) {
      setState(() => _status = "NFC read: $percent%");
    });

    VideoCallFlutter.setOnScreenLocked(() {
      setState(() => _status = "Screen locked");
    });

    VideoCallFlutter.setOnScreenUnlocked(() {
      setState(() => _status = "Screen unlocked");
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await VideoCallFlutter.checkPermissions();
      setState(() {
        _permissions = permissions;
        _status = "Permissions checked";
      });
    } catch (e) {
      setState(() {
        _status = "Permission check failed: $e";
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final result = await VideoCallFlutter.requestPermissions();
      print("Permission request result: $result");
      await _checkPermissions();
    } catch (e) {
      print("Error requesting permissions: $e");
      setState(() {
        _status = "Permission request failed: $e";
      });
    }
  }

  /// Asked when the user starts a call, not at launch: check camera and microphone, and request only
  /// what is still undecided (iOS shows each system prompt once, and the iOS SDKs never ask themselves).
  /// A refusal is final until the user changes it in Settings, so it stops the call and says so.
  Future<bool> _ensureCallPermissions() async {
    bool granted(VideoCallPermissionStatus p) =>
        p.hasCameraPermission && p.hasRecordAudioPermission;

    var permissions = await VideoCallFlutter.checkPermissions();
    if (granted(permissions)) return true;

    await VideoCallFlutter.requestPermissions();
    permissions = await VideoCallFlutter.checkPermissions();
    if (mounted) setState(() => _permissions = permissions);
    if (granted(permissions)) return true;

    _showPermissionDialog();
    return false;
  }

  bool _permissionDialogOpen = false;

  Future<void> _showPermissionDialog() async {
    if (!mounted || _permissionDialogOpen) return;
    _permissionDialogOpen = true;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Camera and microphone needed'),
        content: const Text(
            'The video call needs camera and microphone access. The system only asks once, so turn them '
            'on in Settings \u2192 this app (Camera, Microphone), then start the call again.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK')),
        ],
      ),
    );
    _permissionDialogOpen = false;
  }

  Future<void> _startVideoCall() async {
    if (_isInCall) return;

    try {
      if (!await _ensureCallPermissions()) {
        setState(() => _status = "Camera / microphone permission required");
        return;
      }
    } catch (e) {
      setState(() => _status = "Permission check failed: $e");
      return;
    }

    setState(() {
      _status = "Getting transaction ID...";
    });

    try {
      final transactionId = await ApiUtils.getVideoCallTransactionId();
      if (transactionId == null) {
        setState(() {
          _status = 'Failed to get transaction ID';
        });
        return;
      }

      setState(() {
        _status = "Starting video call...";
      });

      // LiveKYC (in-call OCR / face / NFC repeats). Android is opted in per capture package
      // before the call; iOS is enabled by passing liveKYCOptions with the call.
      if (defaultTargetPlatform == TargetPlatform.android) {
        if (_liveKycEnabled) {
          await OcrFlutter.setRepeatConfig(OCRRepeatConfig(
            serverURL: _serverUrl,
            userID: _userIdController.text,
            transactionID: transactionId,
          ));
          await LivenessFlutter.setRepeatConfig(FaceRepeatConfig(
            serverURL: _serverUrl,
            userID: _userIdController.text,
            transactionID: transactionId,
          ));
          await NfcFlutter().setRepeatConfig(NfcRepeatConfig(
            serverURL: _serverUrl,
            transactionID: transactionId,
          ));
        } else {
          await OcrFlutter.setRepeatConfig(null);
          await LivenessFlutter.setRepeatConfig(null);
          await NfcFlutter().setRepeatConfig(null);
        }
      }

      await VideoCallFlutter.setVideoCallConfig(_buildVideoCallConfig());

      final credentials = VideoCallCredentials(
        serverURL: _serverUrl,
        wssURL: _wssUrl,
        userID: _userIdController.text,
        transactionID: transactionId,
        clientName: _clientName,
        idleTimeout: _idleTimeout,
        liveKYCOptions: _liveKycEnabled &&
                defaultTargetPlatform == TargetPlatform.iOS
            ? const VideoCallLiveKYCOptions(ocrCountry: 'TUR')
            : null,
      );

      final result = await VideoCallFlutter.startVideoCall(credentials);

      setState(() {
        if (result.success) {
          _status = "Video call started successfully!";
          _currentStatus = result.status ?? VideoCallStatus.connecting;
          CallOverlay.show();
        } else {
          _status =
              "Video call failed: ${result.error?.message ?? "Unknown error"}";
        }
      });
    } catch (e) {
      setState(() {
        _status = "Video call failed: $e";
      });
    }
  }

  Future<void> _endVideoCall() async {
    if (!_isInCall) return;
    CallOverlay.hide();

    setState(() {
      _status = "Ending video call...";
    });

    try {
      final result = await VideoCallFlutter.endVideoCall();

      setState(() {
        _isInCall = false;
        _currentStatus = VideoCallStatus.disconnected;
        if (result.success) {
          _status = "Video call ended successfully";
        } else {
          _status =
              "Failed to end video call: ${result.error?.message ?? "Unknown error"}";
        }
      });
    } catch (e) {
      setState(() {
        _status = "Failed to end video call: $e";
        _isInCall = false;
      });
    }
  }

  bool _endingFromButton = false;

  /// The app's end-call button was tapped. Cancel the transaction on the server, which also dismisses the
  /// screen, and fall back to ending the call locally when the cancel is not confirmed.
  Future<void> _onEndCallPressed() async {
    if (_endingFromButton) return;
    _endingFromButton = true;
    try {
      final result = await VideoCallFlutter.cancelVideoCall();
      if (!result.success) await _endVideoCall();
    } catch (_) {
      await _endVideoCall();
    } finally {
      _endingFromButton = false;
      CallOverlay.hide();
      if (mounted) setState(() => _isInCall = false);
    }
  }

  Future<void> _cancelVideoCall() async {
    CallOverlay.hide();
    setState(() => _status = "Cancelling video call...");
    final result = await VideoCallFlutter.cancelVideoCall();
    setState(() {
      if (result.success) {
        _isInCall = false;
        _currentStatus = VideoCallStatus.disconnected;
        _status = "Video call cancelled";
      } else {
        _status =
            "Cancel failed: ${result.error?.message ?? "not confirmed by the server"}";
      }
    });
  }

  Future<void> _getVideoCallStatus() async {
    try {
      final status = await VideoCallFlutter.getVideoCallStatus();
      setState(() {
        _currentStatus = status;
        _status = "Current status: ${status.toString()}";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to get status: $e";
      });
    }
  }

  Future<void> _toggleMicrophone() async {
    try {
      // Accepted is not applied: the onMicrophoneStateChanged callback updates the UI.
      final accepted =
          await VideoCallFlutter.setMicrophoneEnabled(!_isMicrophoneEnabled);
      setState(() {
        _status = accepted
            ? "Microphone request accepted"
            : "Microphone request not taken up (no connected call)";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to toggle microphone: $e";
      });
    }
  }

  /// Call-screen styling: the self-view in the top
  /// left, the two in-call controls centered as one group at the bottom. Positions are measured from the
  /// call view's edges, not the safe area, so top-anchored elements add the status bar / notch inset.
  VideoCallConfig _buildVideoCallConfig() {
    // 16 below the status bar / notch: the same distance the end-call button keeps from the top, so the
    // self-view and the button line up.
    const topMargin = 16.0;
    // Positions are measured from the call view's own top edge, which is the top of the display whenever
    // the window draws under the status bar / notch (the iOS call screen always does; Android's does on
    // an edge-to-edge activity). Read that inset from the view, not from `MediaQuery.of(context)`: inside
    // a Scaffold with an app bar it has already been consumed and reads 0. The view reports 0 itself
    // when the window starts below the status bar, so the same value is right on both platforms.
    final statusBarInset = MediaQueryData.fromView(View.of(context)).padding.top;
    final topInset = statusBarInset + topMargin;
    const controlSize = 50.0;
    const controlGap = 24.0;
    const controlShift = (controlSize + controlGap) / 2;
    const controlBottom = 20.0;

    return VideoCallConfig(
      backgroundColor: '#000000',
      pipViewStyle: VideoCallPipViewStyle(
        visible: true,
        horizontalPosition: const VideoCallHorizontalPosition(
            VideoCallHorizontalPositionType.left,
            offset: 20),
        verticalPosition: VideoCallVerticalPosition(
            VideoCallVerticalPositionType.top,
            offset: topInset),
        width: 120,
        height: 160,
        backgroundColor: '#00000000',
        borderColor: '#FFFFFF',
        borderWidth: 2,
        cornerRadius: 10,
      ),
      // Right half of the centered pair.
      muteButtonStyle: const VideoCallMuteButtonStyle(
        visible: true,
        size: controlSize,
        mutedColor: '#FF0000',
        // Green rather than the SDKs' white on purpose: it matches no fallback, so this colour on
        // screen proves the config reached the native side.
        unmutedColor: '#00FF00',
        horizontalPosition: VideoCallHorizontalPosition(
            VideoCallHorizontalPositionType.center,
            offset: controlShift),
        verticalPosition: VideoCallVerticalPosition(
            VideoCallVerticalPositionType.bottom,
            offset: controlBottom),
      ),
      // Left half of the centered pair.
      cameraSwitchButtonStyle: const VideoCallCameraSwitchButtonStyle(
        visible: true,
        size: controlSize,
        color: '#FFFFFF',
        horizontalPosition: VideoCallHorizontalPosition(
            VideoCallHorizontalPositionType.center,
            offset: -controlShift),
        verticalPosition: VideoCallVerticalPosition(
            VideoCallVerticalPositionType.bottom,
            offset: controlBottom),
      ),
      // Android only; hidden so both platforms look the same.
      flashButtonStyle: const VideoCallFlashButtonStyle(
        visible: false,
        size: controlSize,
        color: '#FFFFFF',
        horizontalPosition: VideoCallHorizontalPosition(
            VideoCallHorizontalPositionType.right,
            offset: 16),
        verticalPosition: VideoCallVerticalPosition(
            VideoCallVerticalPositionType.bottom,
            offset: controlBottom),
      ),
      instructionLabelStyle: const VideoCallInstructionLabelStyle(
        fontSize: 20,
        fontWeight: VideoCallFontWeight.medium,
        textColor: '#FFFFFF',
        textAlign: VideoCallTextAlign.center,
        numberOfLines: 0,
        lineHeightMultiple: 0,
        leading: 35,
        trailing: 35,
        verticalPosition:
            VideoCallVerticalPosition(VideoCallVerticalPositionType.center),
      ),
      requestTimeout: 30,
    );
  }

  Future<void> _setVideoCallConfig() async {
    try {
      final config = _buildVideoCallConfig();

      await VideoCallFlutter.setVideoCallConfig(config);
      setState(() {
        _status = "Video call configuration set";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to set configuration: $e";
      });
    }
  }

  Color _getStatusColor(VideoCallStatus status) {
    switch (status) {
      case VideoCallStatus.idle:
        return Colors.grey;
      case VideoCallStatus.connecting:
        return Colors.orange;
      case VideoCallStatus.connected:
        return Colors.green;
      case VideoCallStatus.disconnected:
        return Colors.blue;
      case VideoCallStatus.failed:
        return Colors.red;
      case VideoCallStatus.completed:
        return Colors.purple;
      case VideoCallStatus.initiating:
      case VideoCallStatus.tokenFetching:
      case VideoCallStatus.tokenFetched:
      case VideoCallStatus.reconnecting:
        return Colors.orange;
      case VideoCallStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _currentStatus
                                .toString()
                                .split(".")
                                .last
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (_isInCall) ...[
                          Icon(
                            _isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
                            color: _isMicrophoneEnabled
                                ? Colors.green
                                : Colors.red,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Permissions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Permissions",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_permissions != null) ...[
                      Text(
                          "Camera: ${_permissions!.hasCameraPermission ? "✓" : "✗"}"),
                      Text(
                          "Phone State: ${_permissions!.hasPhoneStatePermission ? "✓" : "✗"}"),
                      Text(
                          "Internet: ${_permissions!.hasInternetPermission ? "✓" : "✗"}"),
                    ] else
                      const Text("Checking permissions..."),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _checkPermissions,
                          child: const Text("Check"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _requestPermissions,
                          child: const Text("Request"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Video Call Configuration",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: "User ID",
                        border: OutlineInputBorder(),
                        helperText: "Unique identifier for this test session",
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "📡 Server: $_serverUrl",
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade700),
                          ),
                          Text(
                            "🔌 WebSocket: $_wssUrl",
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade700),
                          ),
                          Text(
                            "📱 Client: $_clientName",
                            style: TextStyle(
                                fontSize: 12, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Actions",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Main call controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInCall ? null : _startVideoCall,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Start Video Call"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isInCall ? _endVideoCall : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("End Video Call"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("LiveKYC repeats (OCR / Face / NFC)"),
                      value: _liveKycEnabled,
                      onChanged:
                          _isInCall ? null : (v) => setState(() => _liveKycEnabled = v),
                    ),

                    ElevatedButton(
                      onPressed: _isInCall ? _cancelVideoCall : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Cancel Video Call (server-side)"),
                    ),

                    const SizedBox(height: 8),

                    // Status and config
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _getVideoCallStatus,
                            child: const Text("Get Status"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _setVideoCallConfig,
                            child: const Text("Set Config"),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Call controls (only enabled during call)
                    Text(
                      "Call Controls",
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: _isInCall ? _toggleMicrophone : null,
                      icon: Icon(
                          _isMicrophoneEnabled ? Icons.mic_off : Icons.mic),
                      label: Text(_isMicrophoneEnabled
                          ? "Disable Microphone"
                          : "Enable Microphone"),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About Video Call",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "This video call feature uses Udentify's SDK to establish secure video connections for identity verification.\n\n"
                      "Features:\n"
                      "• Real-time video communication\n"
                      "• Camera and microphone controls\n"
                      "• Customizable UI\n"
                      "• WebSocket-based connection\n"
                      "• Transaction-based sessions\n\n"
                      "Note: This implementation requires Udentify SDK frameworks to be added for full functionality.",
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
