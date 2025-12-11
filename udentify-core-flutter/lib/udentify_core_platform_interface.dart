import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'udentify_core_method_channel.dart';

/// Platform interface for Udentify Core SSL Pinning functionality
abstract class UdentifyCorePlatform extends PlatformInterface {
  /// Constructs a UdentifyCorePlatform.
  UdentifyCorePlatform() : super(token: _token);

  static final Object _token = Object();

  static UdentifyCorePlatform _instance = MethodChannelUdentifyCore();

  /// The default instance of [UdentifyCorePlatform] to use.
  ///
  /// Defaults to [MethodChannelUdentifyCore].
  static UdentifyCorePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [UdentifyCorePlatform] when
  /// they register themselves.
  static set instance(UdentifyCorePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Load a certificate from the app bundle (iOS) or assets folder (Android)
  /// and automatically set it for SSL pinning.
  /// 
  /// The certificate must be in DER format with .cer or .der extension.
  /// 
  /// [certificateName] - Name of the certificate file without extension (e.g., 'MyServerCertificate')
  /// [extension] - File extension, typically 'cer' or 'der'
  /// 
  /// Returns true if certificate was loaded and set successfully
  Future<bool> loadCertificateFromAssets(
    String certificateName,
    String extension,
  ) {
    throw UnimplementedError('loadCertificateFromAssets() has not been implemented.');
  }

  /// Set SSL certificate using base64 encoded certificate data.
  /// The certificate must be in DER format.
  /// 
  /// [certificateBase64] - Base64 encoded certificate data
  /// 
  /// Returns true if certificate was set successfully
  Future<bool> setSSLCertificateBase64(String certificateBase64) {
    throw UnimplementedError('setSSLCertificateBase64() has not been implemented.');
  }

  /// Remove the currently set SSL certificate, disabling SSL pinning.
  /// 
  /// Returns true if certificate was removed successfully
  Future<bool> removeSSLCertificate() {
    throw UnimplementedError('removeSSLCertificate() has not been implemented.');
  }

  /// Get the currently set SSL certificate as a base64 encoded string.
  /// 
  /// Returns base64 string or null if no certificate is set
  Future<String?> getSSLCertificateBase64() {
    throw UnimplementedError('getSSLCertificateBase64() has not been implemented.');
  }

  /// Check if SSL pinning is currently enabled.
  /// 
  /// Returns true if SSL pinning is enabled
  Future<bool> isSSLPinningEnabled() {
    throw UnimplementedError('isSSLPinningEnabled() has not been implemented.');
  }

  /// Instantiate server-based localization by downloading the localization file from the server.
  /// This should be called before using any Udentify modules to ensure localization is available.
  /// 
  /// [language] - Language code (e.g., 'EN', 'FR', 'TR', 'DE', 'ES', 'IT', 'PT', 'RU', 'AR', 'ZH', 'JA', 'KO')
  /// [serverUrl] - URL of the Udentify API Server where the localization file is hosted
  /// [transactionId] - Transaction ID received from Udentify API Server
  /// [requestTimeout] - Timeout duration for the network request in seconds (default: 30)
  /// 
  /// Returns a Future that completes when localization is instantiated
  Future<void> instantiateServerBasedLocalization(
    String language,
    String serverUrl,
    String transactionId,
    double requestTimeout,
  ) {
    throw UnimplementedError('instantiateServerBasedLocalization() has not been implemented.');
  }

  /// Get the localization map downloaded from the server.
  /// This map contains the localization content for the current language.
  /// 
  /// Note: The localization map is used automatically by the SDK in the background.
  /// This method is primarily for debugging purposes.
  /// 
  /// Returns localization map or null if not available
  Future<Map<String, String>?> getLocalizationMap() {
    throw UnimplementedError('getLocalizationMap() has not been implemented.');
  }

  /// Clear the localization cache for a specific language.
  /// This removes the localization content saved locally and updates the localization map to null.
  /// 
  /// [language] - Language code to clear cache for
  /// 
  /// Returns a Future that completes when cache is cleared
  Future<void> clearLocalizationCache(String language) {
    throw UnimplementedError('clearLocalizationCache() has not been implemented.');
  }

  /// Map the system language to the enum value used by the SDK.
  /// This is useful for automatically detecting the user's preferred language.
  /// 
  /// Returns language code or null if system language is not supported
  Future<String?> mapSystemLanguageToEnum() {
    throw UnimplementedError('mapSystemLanguageToEnum() has not been implemented.');
  }
}

