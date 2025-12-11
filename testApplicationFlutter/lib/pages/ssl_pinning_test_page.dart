import 'package:flutter/material.dart';
import 'package:udentify_core_flutter/udentify_core_flutter.dart';

/// SSL Pinning Test Page
/// Tests all SSL pinning functionality from udentify-core-flutter
class SSLPinningTestPage extends StatefulWidget {
  const SSLPinningTestPage({super.key});

  @override
  State<SSLPinningTestPage> createState() => _SSLPinningTestPageState();
}

class _SSLPinningTestPageState extends State<SSLPinningTestPage> {
  bool _loading = false;
  bool? _isPinningEnabled;
  String? _certificateInfo;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  void _addLog(String message) {
    final timestamp = TimeOfDay.now().format(context);
    setState(() {
      _logs.insert(0, '[$timestamp] $message');
      if (_logs.length > 20) {
        _logs.removeLast();
      }
    });
    print('SSLPinningTestPage - $message');
  }

  Future<void> _checkInitialStatus() async {
    try {
      final enabled = await UdentifyCoreFlutter.isSSLPinningEnabled();
      setState(() {
        _isPinningEnabled = enabled;
      });
      _addLog('Initial SSL pinning status: ${enabled ? 'ENABLED' : 'DISABLED'}');

      if (enabled) {
        final cert = await UdentifyCoreFlutter.getSSLCertificateBase64();
        if (cert != null) {
          setState(() {
            _certificateInfo = 'Certificate set (${cert.length} chars)';
          });
          _addLog('Certificate is currently set');
        }
      }
    } catch (error) {
      _addLog('Error checking initial status: $error');
    }
  }

  Future<void> _handleLoadFromAssets() async {
    setState(() => _loading = true);
    _addLog('Attempting to load certificate from assets...');

    try {
      // Try to load a test certificate from assets
      // Certificate should be named 'test_certificate.cer' in iOS bundle and Android assets
      final success = await UdentifyCoreFlutter.loadCertificateFromAssets(
          'test_certificate', 'cer');

      if (success) {
        _addLog('Certificate loaded successfully from assets');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Certificate loaded and set successfully!')),
          );
        }
        await _checkStatus();
      } else {
        _addLog('Failed to load certificate from assets');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load certificate from assets')),
          );
        }
      }
    } catch (error) {
      _addLog('Error: $error');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Make sure test_certificate.cer is in:\n'
              '- iOS: Added to Xcode project\n'
              '- Android: android/app/src/main/assets/\n\n'
              'Error: $error',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleRemoveCertificate() async {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Certificate'),
          content:
              const Text('Are you sure you want to remove the SSL certificate?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _loading = true);
                _addLog('Removing SSL certificate...');

                try {
                  final success = await UdentifyCoreFlutter.removeSSLCertificate();
                  if (success) {
                    _addLog('Certificate removed successfully');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SSL certificate removed')),
                      );
                    }
                    await _checkStatus();
                  }
                } catch (error) {
                  _addLog('Error: $error');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $error')),
                    );
                  }
                } finally {
                  setState(() => _loading = false);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleGetCertificate() async {
    setState(() => _loading = true);
    _addLog('Retrieving current certificate...');

    try {
      final cert = await UdentifyCoreFlutter.getSSLCertificateBase64();

      if (cert != null) {
        final certInfo =
            'Certificate: ${cert.substring(0, cert.length > 50 ? 50 : cert.length)}...\nLength: ${cert.length} characters';
        setState(() {
          _certificateInfo = certInfo;
        });
        _addLog('Certificate retrieved (${cert.length} chars)');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Certificate Retrieved'),
              content: Text(certInfo),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          _certificateInfo = null;
        });
        _addLog('No certificate is currently set');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('No Certificate'),
              content: const Text('No SSL certificate is currently set'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (error) {
      _addLog('Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _handleCheckStatus() async {
    setState(() => _loading = true);
    _addLog('Checking SSL pinning status...');
    await _checkStatus();
    setState(() => _loading = false);
  }

  Future<void> _checkStatus() async {
    try {
      final enabled = await UdentifyCoreFlutter.isSSLPinningEnabled();
      setState(() {
        _isPinningEnabled = enabled;
      });
      _addLog('SSL pinning is ${enabled ? 'ENABLED' : 'DISABLED'}');

      if (enabled) {
        final cert = await UdentifyCoreFlutter.getSSLCertificateBase64();
        if (cert != null) {
          setState(() {
            _certificateInfo =
                '${cert.substring(0, cert.length > 50 ? 50 : cert.length)}... (${cert.length} chars)';
          });
        }
      } else {
        setState(() {
          _certificateInfo = null;
        });
      }
    } catch (error) {
      _addLog('Error checking status: $error');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
    _addLog('Logs cleared');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SSL Pinning Test',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Test SSL certificate pinning functionality from udentify-core-flutter',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Section
              _buildSection(
                title: 'Current Status',
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SSL Pinning:',
                            style: TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isPinningEnabled == null
                                  ? Colors.grey
                                  : _isPinningEnabled!
                                      ? Colors.green
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _isPinningEnabled == null
                                  ? 'UNKNOWN'
                                  : _isPinningEnabled!
                                      ? 'ENABLED'
                                      : 'DISABLED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_certificateInfo != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _certificateInfo!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Actions Section
              _buildSection(
                title: 'Actions',
                child: Column(
                  children: [
                    _buildButton(
                      'Load Certificate from Assets',
                      Colors.blue,
                      _handleLoadFromAssets,
                    ),
                    const SizedBox(height: 10),
                    _buildButton(
                      'Get Current Certificate',
                      Colors.green,
                      _handleGetCertificate,
                    ),
                    const SizedBox(height: 10),
                    _buildButton(
                      'Check SSL Pinning Status',
                      Colors.green,
                      _handleCheckStatus,
                    ),
                    const SizedBox(height: 10),
                    _buildButton(
                      'Remove Certificate',
                      Colors.red,
                      _handleRemoveCertificate,
                    ),
                  ],
                ),
              ),

              // Logs Section
              _buildSection(
                title: 'Activity Log',
                trailing: TextButton(
                  onPressed: _clearLogs,
                  child: const Text('Clear'),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e1e1e),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: _logs.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No activity yet',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                _logs[index],
                                style: const TextStyle(
                                  color: Color(0xFF00ff00),
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),

              // Instructions Section
              _buildSection(
                title: 'Setup Instructions',
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Colors.blue, width: 4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'iOS:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '1. Add test_certificate.cer to Xcode project\n'
                        '2. Ensure it\'s added to the app target\n'
                        '3. Certificate must be in DER format',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Android:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '1. Place test_certificate.cer in:\n'
                        '   android/app/src/main/assets/\n'
                        '2. Certificate must be in DER format',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Convert PEM to DER:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'openssl x509 -in cert.pem -outform der -out test_certificate.cer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildButton(String text, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.all(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

