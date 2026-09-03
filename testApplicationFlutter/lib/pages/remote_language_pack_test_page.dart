import 'package:flutter/material.dart';
import 'package:udentify_core_flutter/udentify_core_flutter.dart';
import '../models/app_constants.dart';
import '../utils/api_utils.dart';

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}

class RemoteLanguagePackTestPage extends StatefulWidget {
  const RemoteLanguagePackTestPage({super.key});

  @override
  State<RemoteLanguagePackTestPage> createState() =>
      _RemoteLanguagePackTestPageState();
}

class _RemoteLanguagePackTestPageState
    extends State<RemoteLanguagePackTestPage> {
  static const List<LanguageOption> supportedLanguages = [
    LanguageOption(code: 'EN', name: 'English', flag: '🇺🇸'),
    LanguageOption(code: 'ES', name: 'Spanish', flag: '🇪🇸'),
    LanguageOption(code: 'FR', name: 'French', flag: '🇫🇷'),
    LanguageOption(code: 'DE', name: 'German', flag: '🇩🇪'),
    LanguageOption(code: 'IT', name: 'Italian', flag: '🇮🇹'),
    LanguageOption(code: 'TR', name: 'Turkish', flag: '🇹🇷'),
    LanguageOption(code: 'PT', name: 'Portuguese', flag: '🇵🇹'),
    LanguageOption(code: 'RU', name: 'Russian', flag: '🇷🇺'),
    LanguageOption(code: 'AR', name: 'Arabic', flag: '🇸🇦'),
    LanguageOption(code: 'ZH', name: 'Chinese', flag: '🇨🇳'),
    LanguageOption(code: 'JA', name: 'Japanese', flag: '🇯🇵'),
    LanguageOption(code: 'KO', name: 'Korean', flag: '🇰🇷'),
  ];

  final TextEditingController _serverUrlController =
      TextEditingController(text: AppConstants.serverUrl);
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _timeoutController =
      TextEditingController(text: '30');

  String _selectedLanguage = 'EN';
  String _results = '';
  Map<String, String>? _localizationMap;
  bool _isFetchingTransactionId = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _transactionIdController.dispose();
    _timeoutController.dispose();
    super.dispose();
  }

  void _log(String message) {
    final timestamp = TimeOfDay.now().format(context);
    setState(() {
      _results = '[$timestamp] $message\n$_results';
    });
  }

  Future<void> _handleInstantiateLocalization() async {
    try {
      setState(() => _isLoading = true);
      _log('Starting localization instantiation...');
      _log('Language: $_selectedLanguage, Server: ${_serverUrlController.text}');

      await UdentifyCoreFlutter.instantiateServerBasedLocalization(
        _selectedLanguage,
        _serverUrlController.text,
        _transactionIdController.text,
        requestTimeout: double.parse(_timeoutController.text),
      );

      _log('✓ Localization instantiated successfully');

      _log('Fetching localization map...');
      final map = await UdentifyCoreFlutter.getLocalizationMap();

      if (map != null) {
        setState(() => _localizationMap = map);
        final entryCount = map.length;
        _log('✓ Retrieved localization map with $entryCount entries');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Localization loaded with $entryCount entries')),
          );
        }
      } else {
        _log('No localization map available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Localization instantiated but no map available')),
          );
        }
      }
    } catch (error) {
      _log('✗ Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGetLocalizationMap() async {
    try {
      _log('Fetching localization map...');

      final map = await UdentifyCoreFlutter.getLocalizationMap();

      if (map != null) {
        setState(() => _localizationMap = map);
        final entryCount = map.length;
        _log('✓ Retrieved localization map with $entryCount entries');

        final sampleEntries = map.entries.take(5);
        _log('Sample entries:');
        for (var entry in sampleEntries) {
          _log('  ${entry.key}: ${entry.value}');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Retrieved $entryCount localization entries')),
          );
        }
      } else {
        _log('No localization map available');
        setState(() => _localizationMap = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No localization map available')),
          );
        }
      }
    } catch (error) {
      _log('✗ Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _handleClearCache() async {
    try {
      _log('Clearing cache for language: $_selectedLanguage');

      await UdentifyCoreFlutter.clearLocalizationCache(_selectedLanguage);

      _log('✓ Cache cleared successfully');
      setState(() => _localizationMap = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared successfully')),
        );
      }
    } catch (error) {
      _log('✗ Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _handleMapSystemLanguage() async {
    try {
      _log('Detecting system language...');

      final systemLang = await UdentifyCoreFlutter.mapSystemLanguageToEnum();

      if (systemLang != null) {
        _log('✓ System language: $systemLang');
        setState(() => _selectedLanguage = systemLang);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('System language: $systemLang')),
          );
        }
      } else {
        _log('System language not supported');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('System language not supported')),
          );
        }
      }
    } catch (error) {
      _log('✗ Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    }
  }

  Future<void> _handleFetchTransactionId() async {
    try {
      setState(() => _isFetchingTransactionId = true);
      _log('Fetching transaction ID from server...');
      _log('Server: ${_serverUrlController.text}');

      final txId = await ApiUtils.getTransactionId(['OCR']);

      if (txId != null) {
        _transactionIdController.text = txId;
        _log('✓ Transaction ID received: ${txId.substring(0, 20)}...');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Transaction ID fetched successfully')),
          );
        }
      } else {
        _log('✗ No transaction ID returned from server');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No transaction ID returned from server')),
          );
        }
      }
    } catch (error) {
      _log('✗ Error fetching transaction ID: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch transaction ID: $error')),
        );
      }
    } finally {
      setState(() => _isFetchingTransactionId = false);
    }
  }

  Future<void> _handleQuickLoadLanguage(String langCode) async {
    try {
      setState(() {
        _selectedLanguage = langCode;
        _isLoading = true;
      });
      _log('=== Quick Load: $langCode ===');

      _log('Fetching fresh transaction ID...');
      final txId = await ApiUtils.getTransactionId(['OCR']);
      if (txId != null) {
        _transactionIdController.text = txId;
        _log('✓ Transaction ID: ${txId.substring(0, 20)}...');
      } else {
        throw Exception('Failed to get transaction ID');
      }

      _log('Clearing cache for $langCode...');
      await UdentifyCoreFlutter.clearLocalizationCache(langCode);
      _log('✓ Cache cleared');

      _log('Loading $langCode localization from server...');
      _log('Server: ${_serverUrlController.text}');
      _log('Transaction: ${txId.substring(0, 20)}...');
      await UdentifyCoreFlutter.instantiateServerBasedLocalization(
        langCode,
        _serverUrlController.text,
        txId,
        requestTimeout: double.parse(_timeoutController.text),
      );
      _log('✓ $langCode instantiated');

      _log('Fetching localization map for $langCode...');
      final map = await UdentifyCoreFlutter.getLocalizationMap();
      if (map != null) {
        setState(() => _localizationMap = map);
        final entries = map.length;
        _log('✓ $langCode loaded with $entries entries');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('$langCode localization loaded\n$entries entries')),
          );
        }
      } else {
        _log('✗ No localization map returned for $langCode');
        setState(() => _localizationMap = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '$langCode loaded but no localization data available. Server may not have this language pack.')),
          );
        }
      }
    } catch (error) {
      _log('✗ Error loading $langCode: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearResults() {
    setState(() {
      _results = '';
      _localizationMap = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Remote Language Pack Test',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildQuickLanguagePicker(),
            const SizedBox(height: 16),
            if (_localizationMap != null) _buildLocalizationDisplay(),
            const SizedBox(height: 16),
            _buildConfigurationSection(),
            const SizedBox(height: 16),
            _buildActionsSection(),
            const SizedBox(height: 16),
            if (_localizationMap != null) _buildMapStatusSection(),
            const SizedBox(height: 16),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLanguagePicker() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Load Language',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a language to fetch and display localizations',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: supportedLanguages.map((lang) {
                final isSelected = _selectedLanguage == lang.code;
                final isDisabled = _isLoading;
                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () => _handleQuickLoadLanguage(lang.code),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 64) / 3,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green[50] : Colors.grey[100],
                      border: Border.all(
                        color:
                            isSelected ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lang.flag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lang.code,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.green : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalizationDisplay() {
    final entries = _localizationMap!.entries.toList();
    final displayEntries = entries.take(15).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Localization Strings (${entries.length} total)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            ...displayEntries.map((entry) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(color: Colors.blue, width: 3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )),
            if (entries.length > 15)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${entries.length - 15} more entries',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: _selectedLanguage),
              onChanged: (value) => _selectedLanguage = value,
              decoration: const InputDecoration(
                labelText: 'Language Code',
                hintText: 'EN, FR, TR, etc.',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://api.udentify.com',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _transactionIdController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID',
                      hintText: 'Enter transaction ID or fetch from server',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      _isFetchingTransactionId ? null : _handleFetchTransactionId,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      _isFetchingTransactionId ? 'Fetching...' : 'Fetch ID'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeoutController,
              decoration: const InputDecoration(
                labelText: 'Timeout (seconds)',
                hintText: '30',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              '1. Detect System Language',
              _handleMapSystemLanguage,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              '2. Instantiate Localization',
              _handleInstantiateLocalization,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              '3. Get Localization Map',
              _handleGetLocalizationMap,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildActionButton(
              '4. Clear Cache',
              _handleClearCache,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              'Clear Results',
              _clearResults,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildMapStatusSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Map Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Entries: ${_localizationMap!.length}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results Log',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _results.isEmpty ? 'No results yet. Run a test above.' : _results,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

