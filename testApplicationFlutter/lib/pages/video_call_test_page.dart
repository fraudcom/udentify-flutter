import 'package:flutter/material.dart';
import 'package:video_call_flutter/video_call_flutter.dart';
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
  bool _isCameraEnabled = true;
  bool _isMicrophoneEnabled = true;

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
        }
      });
    });

    VideoCallFlutter.setOnError((error) {
      setState(() {
        _status = "Error: ${error.message}";
        _isInCall = false;
      });
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

  Future<void> _startVideoCall() async {
    if (_isInCall) return;

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

      final credentials = VideoCallCredentials(
        serverURL: _serverUrl,
        wssURL: _wssUrl,
        userID: _userIdController.text,
        transactionID: transactionId,
        clientName: _clientName,
        idleTimeout: _idleTimeout,
      );

      final result = await VideoCallFlutter.startVideoCall(credentials);

      setState(() {
        if (result.success) {
          _status = "Video call started successfully!";
          _currentStatus = result.status ?? VideoCallStatus.connecting;
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

  Future<void> _toggleCamera() async {
    try {
      final isEnabled = await VideoCallFlutter.toggleCamera();
      setState(() {
        _isCameraEnabled = isEnabled;
        _status = "Camera ${isEnabled ? "enabled" : "disabled"}";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to toggle camera: $e";
      });
    }
  }

  Future<void> _switchCamera() async {
    try {
      final success = await VideoCallFlutter.switchCamera();
      setState(() {
        _status = success ? "Camera switched" : "Failed to switch camera";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to switch camera: $e";
      });
    }
  }

  Future<void> _toggleMicrophone() async {
    try {
      final isEnabled = await VideoCallFlutter.toggleMicrophone();
      setState(() {
        _isMicrophoneEnabled = isEnabled;
        _status = "Microphone ${isEnabled ? "enabled" : "disabled"}";
      });
    } catch (e) {
      setState(() {
        _status = "Failed to toggle microphone: $e";
      });
    }
  }

  Future<void> _setVideoCallConfig() async {
    try {
      final config = VideoCallConfig(
        backgroundColor: "#FF000000",
        textColor: "#FFFFFFFF",
        pipViewBorderColor: "#FFFFFFFF",
        notificationLabelDefault: "Video Call will be starting, please wait...",
        notificationLabelCountdown: "Video Call will be started in %d sec/s.",
        notificationLabelTokenFetch: "Authorizing the user...",
      );

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
                            _isCameraEnabled
                                ? Icons.videocam
                                : Icons.videocam_off,
                            color: _isCameraEnabled ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
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

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isInCall ? _toggleCamera : null,
                            icon: Icon(_isCameraEnabled
                                ? Icons.videocam_off
                                : Icons.videocam),
                            label: Text(_isCameraEnabled
                                ? "Disable Camera"
                                : "Enable Camera"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isInCall ? _switchCamera : null,
                            icon: const Icon(Icons.switch_camera),
                            label: const Text("Switch Camera"),
                          ),
                        ),
                      ],
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
