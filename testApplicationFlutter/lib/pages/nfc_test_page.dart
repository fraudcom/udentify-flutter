import 'package:flutter/material.dart';
import 'package:nfc_flutter/nfc_flutter.dart';
import '../utils/api_utils.dart';

class NfcTestPage extends StatefulWidget {
  final String pageId;
  final String? mrzDocumentNumber;
  final String? mrzDateOfBirth;
  final String? mrzDateOfExpiration;

  const NfcTestPage({
    super.key,
    required this.pageId,
    this.mrzDocumentNumber,
    this.mrzDateOfBirth,
    this.mrzDateOfExpiration,
  });

  @override
  State<NfcTestPage> createState() => _NfcTestPageState();
}

class _NfcTestPageState extends State<NfcTestPage> {
  final NfcFlutter _nfcFlutter = NfcFlutter();

  // Form controllers
  final TextEditingController _documentNumberController =
      TextEditingController(text: "123456789");
  final TextEditingController _dateOfBirthController =
      TextEditingController(text: "900101");
  final TextEditingController _expiryDateController =
      TextEditingController(text: "300101");

  // Hardcoded server configuration
  static const String _serverUrl = "https://demo.udentify.io/api";

  // State variables
  String _status = "Ready";
  double _progress = 0.0;
  NfcPassport? _passport;
  PermissionStatus? _permissions;
  NfcLocation? _nfcLocation;
  String? _nfcLocationRawResponse; // Store raw JSON response
  bool _isReading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _populateFromMrz();
  }

  void _populateFromMrz() {
    // Populate form fields with MRZ data if available
    if (widget.mrzDocumentNumber != null) {
      _documentNumberController.text = widget.mrzDocumentNumber!;
    }
    if (widget.mrzDateOfBirth != null) {
      _dateOfBirthController.text = widget.mrzDateOfBirth!;
    }
    if (widget.mrzDateOfExpiration != null) {
      _expiryDateController.text = widget.mrzDateOfExpiration!;
    }
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    _dateOfBirthController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final permissions = await _nfcFlutter.checkPermissions();
      setState(() {
        _permissions = permissions;
        _status = 'Permissions checked';
      });
    } catch (e) {
      setState(() {
        _status = 'Permission check failed: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final result = await _nfcFlutter.requestPermissions();
      print('Permission request result: $result');
      await _checkPermissions();
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _status = 'Permission request failed: $e';
      });
    }
  }

  Future<void> _readPassport() async {
    if (_isReading) return;

    setState(() {
      _isReading = true;
      _status = 'Getting transaction ID...';
      _progress = 0.0;
      _passport = null;
    });

    try {
      // Get transaction ID from API
      final transactionId = await ApiUtils.getTransactionId(['NFC']);
      if (transactionId == null) {
        setState(() {
          _status = 'Failed to get transaction ID';
          _isReading = false;
        });
        return;
      }

      setState(() {
        _status = 'Starting NFC read...';
      });

      final params = NfcPassportParams(
        documentNumber: _documentNumberController.text,
        dateOfBirth: _dateOfBirthController.text,
        expiryDate: _expiryDateController.text,
        transactionID: transactionId,
        serverURL: _serverUrl,
        requestTimeout: 30,
        isActiveAuthenticationEnabled: true,
        isPassiveAuthenticationEnabled: true,
      );

      final passport = await _nfcFlutter.readPassport(
        params,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      // Log PA/AA status for debugging
      print('=== NFC READ SUCCESS ===');
      print('PA Status: ${passport?.passedPA}');
      print('AA Status: ${passport?.passedAA}');
      print('First Name: ${passport?.firstName}');
      print('Last Name: ${passport?.lastName}');
      print('=======================');

      setState(() {
        _passport = passport;
        _status = 'Passport read successfully!';
        _isReading = false;
      });
    } catch (e) {
      String errorMessage = 'NFC read failed: $e';

      // Provide specific guidance for common errors
      if (e.toString().contains('ERR_BAC_FAILED')) {
        errorMessage = 'BAC Authentication Failed!\n\n'
            'This usually means the document number, date of birth, or expiry date '
            'don\'t match the passport exactly.\n\n'
            'Please:\n'
            '1. Use the MRZ tab to scan the passport first\n'
            '2. Check that all dates are in YYMMDD format\n'
            '3. Ensure document number matches exactly (including any letters)';
      } else if (e.toString().contains('ERR_TAG_LOST')) {
        errorMessage = 'NFC Tag Lost!\n\n'
            'The passport was moved away from the phone during reading.\n\n'
            'Please:\n'
            '1. Keep the passport steady against the phone\n'
            '2. Don\'t move the passport during reading\n'
            '3. Try again with the passport held firmly in place';
      }

      setState(() {
        _status = errorMessage;
        _isReading = false;
      });
    }
  }

  Future<void> _cancelReading() async {
    try {
      await _nfcFlutter.cancelReading();
      setState(() {
        _status = 'Reading cancelled';
        _isReading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Cancel failed: $e';
      });
    }
  }

  Future<void> _getNfcLocation() async {
    setState(() {
      _status = 'Getting NFC location...';
    });

    try {
      final location = await _nfcFlutter.getNfcLocation(_serverUrl);
      
      // Also get the raw JSON response like React Native
      try {
        final rawResponse = await _nfcFlutter.getNfcLocationRaw(_serverUrl);
        
        setState(() {
          _nfcLocation = location;
          _nfcLocationRawResponse = rawResponse;
          _status = 'NFC location detected successfully';
        });
      } catch (rawError) {
        setState(() {
          _nfcLocation = location;
          _nfcLocationRawResponse = null;
          _status = 'NFC location: ${location.name}';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Get NFC location failed: $e';
      });
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
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _progress / 100),
                    Text('Progress: ${_progress.toStringAsFixed(1)}%'),
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
                      'Permissions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_permissions != null) ...[
                      Text(
                          'Phone State: ${_permissions!.hasPhoneStatePermission ? "✓" : "✗"}'),
                      Text(
                          'NFC: ${_permissions!.hasNfcPermission ? "✓" : "✗"}'),
                    ] else
                      const Text('Checking permissions...'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _checkPermissions,
                          child: const Text('Check'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _requestPermissions,
                          child: const Text('Request'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Form Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Passport Parameters',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (widget.mrzDocumentNumber != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'MRZ Data',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                          Row(
                            children: [
                              Icon(Icons.info,
                                  color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Important: Use Real MRZ Data',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'For NFC reading to work, you must enter the EXACT values from the passport\'s MRZ (Machine Readable Zone).\n\n'
                            '💡 Tip: Use the MRZ tab first to automatically extract these values!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _documentNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Document Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _dateOfBirthController,
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth (YYMMDD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _expiryDateController,
                      decoration: const InputDecoration(
                        labelText: 'Expiry Date (YYMMDD)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isReading ? null : _readPassport,
                      child: Text(_isReading ? 'Reading...' : 'Read Passport'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isReading ? _cancelReading : null,
                      child: const Text('Cancel Reading'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _getNfcLocation,
                      child: const Text('Get NFC Location'),
                    ),
                    const SizedBox(height: 8),
                    if (_nfcLocation != null)
                      Text('NFC Location: ${_nfcLocation!.name}'),
                    
                    // Raw JSON Response Card (like React Native)
                    if (_nfcLocationRawResponse != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'NFC Location Raw Response',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: SelectableText(
                                  _nfcLocationRawResponse!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Card
            if (_passport != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passport Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_passport!.firstName != null)
                        Text('First Name: ${_passport!.firstName}'),
                      if (_passport!.lastName != null)
                        Text('Last Name: ${_passport!.lastName}'),
                      Text('PA Status: ${_passport!.passedPA}'),
                      Text('AA Status: ${_passport!.passedAA}'),
                      if (_passport!.image != null) ...[
                        const SizedBox(height: 8),
                        const Text('Photo:'),
                        const SizedBox(height: 4),
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Center(
                            child: Text('Base64 Image Available'),
                          ),
                        ),
                      ],
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
