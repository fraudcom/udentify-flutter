import 'package:flutter/material.dart';

/// Widget that displays user registration status and management
class UserRegistrationWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> userRegistrationStatus;
  final String currentUserID;
  final bool currentUserRegistered;
  final VoidCallback onClearAllRegistrationData;

  const UserRegistrationWidget({
    super.key,
    required this.userRegistrationStatus,
    required this.currentUserID,
    required this.currentUserRegistered,
    required this.onClearAllRegistrationData,
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
              'User Registration Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            if (userRegistrationStatus.isNotEmpty) 
              ...userRegistrationStatus.entries.map((entry) {
                final userID = entry.key;
                final status = entry.value;
                final isRegistered = status['isRegistered'] ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRegistered ? Colors.green.shade50 : Colors.orange.shade50,
                    border: Border.all(
                      color: isRegistered ? Colors.green.shade200 : Colors.orange.shade200,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRegistered ? Icons.check_circle : Icons.pending,
                            color: isRegistered ? Colors.green.shade700 : Colors.orange.shade700,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${isRegistered ? '✅' : '⏳'} User $userID',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isRegistered ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isRegistered 
                            ? 'Registered on ${DateTime.parse(status['registrationDate']).toLocal().toString().split(' ')[0]} via ${status['registrationMethod']}'
                            : 'Not registered - Authentication will fail',
                        style: TextStyle(
                          fontSize: 12,
                          color: isRegistered ? Colors.green.shade600 : Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList()
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '⚠️ No users registered yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please complete face recognition registration before attempting authentication.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Current User Status Indicator
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '🎯 Selected User: $currentUserID - ${currentUserRegistered ? '✅ REGISTERED' : '❌ NOT REGISTERED'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            
            // Clear Registration Data Button (for testing)
            if (userRegistrationStatus.isNotEmpty) ...[
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear Registration Data'),
                      content: const Text('This will clear all user registration data. Use this for testing purposes only.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onClearAllRegistrationData();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('🗑️ Clear Registration Data (Testing)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
