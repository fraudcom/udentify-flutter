/// A Flutter plugin for Udentify Core SSL certificate pinning.
///
/// This plugin provides SSL certificate pinning functionality
/// using the Udentify SDK. It allows you to configure SSL pinning
/// to secure communication with your servers.
library udentify_core_flutter;

import 'udentify_core_platform_interface.dart';

/// The main class for interacting with the Udentify Core Flutter plugin.
///
/// SSL pinning must be configured BEFORE using any other Udentify modules
/// to ensure the configurations are applied correctly from the start.
class UdentifyCoreFlutter {
  UdentifyCoreFlutter._();

  static UdentifyCorePlatform get _platform => UdentifyCorePlatform.instance;

  /// Load a certificate from the app bundle (iOS) or assets folder (Android)
  /// and automatically set it for SSL pinning.
  /// 
  /// The certificate must be in DER format with .cer or .der extension.
  /// 
  /// Place your certificate file in:
  /// - **iOS**: Add to your Xcode project bundle
  /// - **Android**: Place in `android/app/src/main/assets/`
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await UdentifyCoreFlutter.loadCertificateFromAssets('MyServerCertificate', 'cer');
  ///   print('SSL Pinning configured successfully');
  /// } catch (error) {
  ///   print('Failed to setup SSL pinning: $error');
  /// }
  /// ```
  /// 
  /// [certificateName] - Name of the certificate file without extension (e.g., 'MyServerCertificate')
  /// [extension] - File extension, typically 'cer' or 'der'
  /// 
  /// Returns true if certificate was loaded and set successfully
  static Future<bool> loadCertificateFromAssets(
    String certificateName,
    String extension,
  ) {
    return _platform.loadCertificateFromAssets(certificateName, extension);
  }

  /// Set SSL certificate using base64 encoded certificate data.
  /// The certificate must be in DER format.
  /// 
  /// Example:
  /// ```dart
  /// const base64Cert = "MIIDXTCCAkWgAwIBAgIJAK...";
  /// await UdentifyCoreFlutter.setSSLCertificateBase64(base64Cert);
  /// ```
  /// 
  /// [certificateBase64] - Base64 encoded certificate data
  /// 
  /// Returns true if certificate was set successfully
  static Future<bool> setSSLCertificateBase64(String certificateBase64) {
    return _platform.setSSLCertificateBase64(certificateBase64);
  }

  /// Remove the currently set SSL certificate, disabling SSL pinning.
  /// 
  /// Example:
  /// ```dart
  /// await UdentifyCoreFlutter.removeSSLCertificate();
  /// ```
  /// 
  /// Returns true if certificate was removed successfully
  static Future<bool> removeSSLCertificate() {
    return _platform.removeSSLCertificate();
  }

  /// Get the currently set SSL certificate as a base64 encoded string.
  /// 
  /// Example:
  /// ```dart
  /// final cert = await UdentifyCoreFlutter.getSSLCertificateBase64();
  /// if (cert != null) {
  ///   print('Certificate is set');
  /// }
  /// ```
  /// 
  /// Returns base64 string or null if no certificate is set
  static Future<String?> getSSLCertificateBase64() {
    return _platform.getSSLCertificateBase64();
  }

  /// Check if SSL pinning is currently enabled.
  /// 
  /// Example:
  /// ```dart
  /// final isEnabled = await UdentifyCoreFlutter.isSSLPinningEnabled();
  /// print('SSL Pinning enabled: $isEnabled');
  /// ```
  /// 
  /// Returns true if SSL pinning is enabled
  static Future<bool> isSSLPinningEnabled() {
    return _platform.isSSLPinningEnabled();
  }

  /// Instantiate server-based localization by downloading the localization file from the server.
  /// This should be called before using any Udentify modules to ensure localization is available.
  /// 
  /// Example:
  /// ```dart
  /// final language = await UdentifyCoreFlutter.mapSystemLanguageToEnum() ?? 'EN';
  /// await UdentifyCoreFlutter.instantiateServerBasedLocalization(
  ///   language,
  ///   'https://api.udentify.com',
  ///   'transaction-id-123',
  ///   30.0,
  /// );
  /// ```
  /// 
  /// [language] - Language code (e.g., 'EN', 'FR', 'TR', 'DE', 'ES', 'IT', 'PT', 'RU', 'AR', 'ZH', 'JA', 'KO')
  /// [serverUrl] - URL of the Udentify API Server where the localization file is hosted
  /// [transactionId] - Transaction ID received from Udentify API Server
  /// [requestTimeout] - Timeout duration for the network request in seconds (default: 30)
  static Future<void> instantiateServerBasedLocalization(
    String language,
    String serverUrl,
    String transactionId, {
    double requestTimeout = 30.0,
  }) {
    return _platform.instantiateServerBasedLocalization(
      language,
      serverUrl,
      transactionId,
      requestTimeout,
    );
  }

  /// Get the localization map downloaded from the server.
  /// This map contains the localization content for the current language.
  /// 
  /// Note: The localization map is used automatically by the SDK in the background.
  /// This method is primarily for debugging purposes.
  /// 
  /// Example:
  /// ```dart
  /// final map = await UdentifyCoreFlutter.getLocalizationMap();
  /// if (map != null) {
  ///   print('Localization entries: ${map.length}');
  /// }
  /// ```
  /// 
  /// Returns localization map or null if not available
  static Future<Map<String, String>?> getLocalizationMap() {
    return _platform.getLocalizationMap();
  }

  /// Clear the localization cache for a specific language.
  /// This removes the localization content saved locally and updates the localization map to null.
  /// 
  /// Example:
  /// ```dart
  /// await UdentifyCoreFlutter.clearLocalizationCache('EN');
  /// ```
  /// 
  /// [language] - Language code to clear cache for
  static Future<void> clearLocalizationCache(String language) {
    return _platform.clearLocalizationCache(language);
  }

  /// Map the system language to the enum value used by the SDK.
  /// This is useful for automatically detecting the user's preferred language.
  /// 
  /// Example:
  /// ```dart
  /// final systemLanguage = await UdentifyCoreFlutter.mapSystemLanguageToEnum();
  /// final language = systemLanguage ?? 'EN';
  /// await UdentifyCoreFlutter.instantiateServerBasedLocalization(
  ///   language,
  ///   serverUrl,
  ///   transactionId,
  /// );
  /// ```
  /// 
  /// Returns language code or null if system language is not supported
  static Future<String?> mapSystemLanguageToEnum() {
    return _platform.mapSystemLanguageToEnum();
  }
}

