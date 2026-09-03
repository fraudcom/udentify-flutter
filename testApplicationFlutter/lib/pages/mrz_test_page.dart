import 'package:flutter/material.dart';
import 'package:mrz_flutter/mrz_flutter.dart';

class MrzTestPage extends StatefulWidget {
  final String pageId;
  final Function(String?, String?, String?)? onMrzDataExtracted;
  final TabController? tabController;

  const MrzTestPage({
    super.key,
    required this.pageId,
    this.onMrzDataExtracted,
    this.tabController,
  });

  @override
  State<MrzTestPage> createState() => _MrzTestPageState();
}

class _MrzTestPageState extends State<MrzTestPage> {
  // State variables
  String _status = "Ready";
  MrzResult? _mrzResult;
  bool _isScanning = false;
  MrzReaderMode _selectedMode = MrzReaderMode.accurate;

  // MRZ data for NFC integration
  String? _documentNumber;
  String? _dateOfBirth;
  String? _dateOfExpiration;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await MrzFlutter.checkPermissions();
      setState(() {
        _status = hasPermissions
            ? 'Camera permissions granted'
            : 'Camera permissions required';
      });
    } catch (e) {
      setState(() {
        _status = 'Permission check failed: $e';
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final result = await MrzFlutter.requestPermissions();
      print('Permission request result: $result');
      await _checkPermissions();
    } catch (e) {
      print('Error requesting permissions: $e');
      setState(() {
        _status = 'Permission request failed: $e';
      });
    }
  }

  Future<void> _startMrzCamera() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _status = 'Starting MRZ camera...';
      _mrzResult = null;
    });

    try {
      final result = await MrzFlutter.startMrzCamera(
        mode: _selectedMode,
        onProgress: (progress) {
          setState(() {
            _status = 'Scanning... ${progress.toStringAsFixed(1)}%';
          });
        },
      );

      setState(() {
        _mrzResult = result;
        _isScanning = false;
        if (result.success) {
          _documentNumber = result.documentNumber;
          _dateOfBirth = result.dateOfBirth;
          _dateOfExpiration = result.dateOfExpiration;
          _status = 'MRZ scan successful!';

          // Notify parent widget about the extracted data
          if (widget.onMrzDataExtracted != null) {
            widget.onMrzDataExtracted!(
                _documentNumber, _dateOfBirth, _dateOfExpiration);
          }
        } else {
          _status =
              'MRZ scan failed: ${result.errorMessage ?? "Unknown error"}';
        }
      });
    } catch (e) {
      setState(() {
        _status = 'MRZ scan failed: $e';
        _isScanning = false;
      });
    }
  }

  Future<void> _cancelMrzScanning() async {
    try {
      await MrzFlutter.cancelMrzScanning();
      setState(() {
        _status = 'MRZ scanning cancelled';
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Cancel failed: $e';
      });
    }
  }

  void _useForNfc() {
    if (_mrzResult != null && _mrzResult!.success) {
      // Switch to NFC tab and populate the form
      if (widget.tabController != null) {
        widget.tabController!.animateTo(3); // Switch to NFC tab (index 3: SSL=0, Language=1, OCR=2, NFC=3)
      }

      // Show a snackbar with the extracted data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'MRZ data populated in NFC tab!\n'
            'Doc: ${_documentNumber ?? 'N/A'}\n'
            'DOB: ${_dateOfBirth ?? 'N/A'}\n'
            'Exp: ${_dateOfExpiration ?? 'N/A'}',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
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
                    if (_isScanning) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
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
                      'MRZ Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<MrzReaderMode>(
                      value: _selectedMode,
                      decoration: const InputDecoration(
                        labelText: 'Reader Mode',
                        border: OutlineInputBorder(),
                      ),
                      items: MrzReaderMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(
                              mode == MrzReaderMode.fast ? 'Fast' : 'Accurate'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMode = value;
                          });
                        }
                      },
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
                      'Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkPermissions,
                            child: const Text('Check Permissions'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _requestPermissions,
                            child: const Text('Request Permissions'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isScanning ? null : _startMrzCamera,
                      child: Text(
                          _isScanning ? 'Scanning...' : 'Start MRZ Camera'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isScanning ? _cancelMrzScanning : null,
                      child: const Text('Cancel Scanning'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Results Card
            if (_mrzResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MRZ Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Success: ${_mrzResult!.success}'),
                      if (_mrzResult!.success) ...[
                        const SizedBox(height: 8),
                        Text(
                            'Document Number: ${_mrzResult!.documentNumber ?? 'N/A'}'),
                        Text(
                            'Date of Birth: ${_mrzResult!.dateOfBirth ?? 'N/A'}'),
                        Text(
                            'Date of Expiration: ${_mrzResult!.dateOfExpiration ?? 'N/A'}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _useForNfc,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Use for NFC Reading'),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                            'Error: ${_mrzResult!.errorMessage ?? 'Unknown error'}'),
                      ],
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
                      'About MRZ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Machine Readable Zone (MRZ) is a standardized format found on the bottom of ID cards and passports. '
                      'It contains essential information needed for NFC reading including document number, date of birth, and expiration date.\n\n'
                      'Fast Mode: Quicker scanning but may be less accurate\n'
                      'Accurate Mode: Slower but more reliable results\n\n'
                      'After successful MRZ scanning, you can use the extracted data to automatically populate the NFC reading form.',
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
