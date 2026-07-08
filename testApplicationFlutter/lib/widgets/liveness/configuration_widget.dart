import 'package:flutter/material.dart';

/// Widget that handles liveness configuration inputs
class LivenessConfigurationWidget extends StatelessWidget {
  final TextEditingController userIDController;
  final String selectedOperation;
  final Function(String) onOperationChanged;
  final VoidCallback onShowUICustomizeDialog;

  const LivenessConfigurationWidget({
    super.key,
    required this.userIDController,
    required this.selectedOperation,
    required this.onOperationChanged,
    required this.onShowUICustomizeDialog,
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
              'Liveness Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            // User ID Input
            TextField(
              controller: userIDController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
                helperText: 'Unique identifier for this test session',
              ),
            ),
            const SizedBox(height: 16),
            
            // Operation Type Picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operation Type (for Active & Hybrid Liveness)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedOperation,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'registration', child: Text('Registration')),
                    DropdownMenuItem(value: 'authentication', child: Text('Authentication')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onOperationChanged(value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // UI Customization Button
            ElevatedButton.icon(
              onPressed: onShowUICustomizeDialog,
              icon: const Icon(Icons.palette),
              label: const Text('🎨 Customize UI Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
