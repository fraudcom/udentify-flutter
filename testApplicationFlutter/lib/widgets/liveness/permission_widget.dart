import 'package:flutter/material.dart';
import 'package:liveness_flutter/liveness_flutter.dart';

/// Widget that handles permission status display and controls
class LivenessPermissionWidget extends StatelessWidget {
  final FaceRecognitionPermissionStatus? permissionStatus;
  final VoidCallback onCheckPermissions;
  final VoidCallback onRequestPermissions;

  const LivenessPermissionWidget({
    super.key,
    required this.permissionStatus,
    required this.onCheckPermissions,
    required this.onRequestPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permission Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (permissionStatus != null) ...[
              _buildPermissionRow('Camera', permissionStatus!.camera),
              _buildPermissionRow('Phone State', permissionStatus!.readPhoneState),
              _buildPermissionRow('Internet', permissionStatus!.internet),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onCheckPermissions,
                    child: const Text('Check Permissions'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRequestPermissions,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Request Permissions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String name, LivenessPermissionStatus status) {
    Color color;
    IconData icon;
    switch (status) {
      case LivenessPermissionStatus.granted:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case LivenessPermissionStatus.denied:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case LivenessPermissionStatus.permanentlyDenied:
        color = Colors.red;
        icon = Icons.block;
        break;
      case LivenessPermissionStatus.unknown:
        color = Colors.grey;
        icon = Icons.help;
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text('$name: ${status.name}'),
      ],
    );
  }
}
