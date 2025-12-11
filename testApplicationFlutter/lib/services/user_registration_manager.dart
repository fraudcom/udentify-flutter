/// Manages user registration state and tracking
class UserRegistrationManager {
  // User registration status tracking
  final Map<String, Map<String, dynamic>> _userRegistrationStatus = {};
  
  // Getters
  Map<String, Map<String, dynamic>> get userRegistrationStatus => Map.unmodifiable(_userRegistrationStatus);
  
  /// Mark user as registered
  void markUserAsRegistered(String userID, String transactionID, String method) {
    print('\n🎯 ========== MARKING USER AS REGISTERED ==========');
    print('👤 User ID: $userID');
    print('🆔 Transaction ID: $transactionID');
    print('🔧 Method: $method');
    print('⏰ Timestamp: ${DateTime.now().toIso8601String()}');
    
    final newRegistrationData = {
      'isRegistered': true,
      'registrationTransactionID': transactionID,
      'registrationDate': DateTime.now().toIso8601String(),
      'registrationMethod': method
    };
    
    _userRegistrationStatus[userID] = newRegistrationData;
    
    print('✅ User $userID marked as registered');
    print('===============================================\n');
  }
  
  /// Check user registration status
  bool checkUserRegistrationStatus(String userID) {
    final userStatus = _userRegistrationStatus[userID];
    final isRegistered = userStatus?['isRegistered'] ?? false;
    print('\n🔍 Checking registration status for $userID: ${isRegistered ? 'REGISTERED' : 'NOT REGISTERED'}');
    return isRegistered;
  }
  
  /// Get user registration details
  Map<String, dynamic>? getUserRegistrationDetails(String userID) {
    return _userRegistrationStatus[userID];
  }
  
  /// Clear all registration data
  void clearAllRegistrationData() {
    print('🗑️ Clearing all registration data');
    _userRegistrationStatus.clear();
  }
  
  /// Clear specific user registration
  void clearUserRegistration(String userID) {
    print('🗑️ Clearing registration data for user: $userID');
    _userRegistrationStatus.remove(userID);
  }
  
  /// Get all registered users
  List<String> getAllRegisteredUsers() {
    return _userRegistrationStatus.keys
        .where((userID) => checkUserRegistrationStatus(userID))
        .toList();
  }
  
  /// Check if any users are registered
  bool hasAnyRegisteredUsers() {
    return _userRegistrationStatus.isNotEmpty && 
           _userRegistrationStatus.values.any((status) => status['isRegistered'] == true);
  }
  
  /// Get registration summary
  Map<String, dynamic> getRegistrationSummary() {
    final totalUsers = _userRegistrationStatus.length;
    final registeredUsers = getAllRegisteredUsers().length;
    
    return {
      'totalUsers': totalUsers,
      'registeredUsers': registeredUsers,
      'pendingUsers': totalUsers - registeredUsers,
      'registrationDetails': Map.from(_userRegistrationStatus),
    };
  }
}
