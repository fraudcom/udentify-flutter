import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ocr_flutter/ocr_flutter.dart';

class OptionItem {
  final String value;
  final String label;

  const OptionItem({required this.value, required this.label});
}

const List<OptionItem> placeholderTemplates = [
  OptionItem(value: 'hidden', label: 'Hidden'),
  OptionItem(value: 'defaultStyle', label: 'Default Style'),
  OptionItem(value: 'countrySpecificStyle', label: 'Country Specific Style'),
];

const List<OptionItem> orientations = [
  OptionItem(value: 'horizontal', label: 'Horizontal'),
  OptionItem(value: 'vertical', label: 'Vertical'),
];

const List<OptionItem> backgroundColors = [
  OptionItem(value: 'purple', label: 'Purple'),
  OptionItem(value: 'blue', label: 'Blue'),
  OptionItem(value: 'green', label: 'Green'),
  OptionItem(value: 'red', label: 'Red'),
  OptionItem(value: 'black', label: 'Black'),
  OptionItem(value: 'white', label: 'White'),
];

const List<OptionItem> borderColors = [
  OptionItem(value: 'white', label: 'White'),
  OptionItem(value: 'black', label: 'Black'),
  OptionItem(value: 'gray', label: 'Gray'),
  OptionItem(value: 'clear', label: 'Clear'),
];

const List<OptionItem> cornerRadiusOptions = [
  OptionItem(value: '0', label: '0 (Square)'),
  OptionItem(value: '8', label: '8 (Default)'),
  OptionItem(value: '12', label: '12 (Rounded)'),
  OptionItem(value: '20', label: '20 (Very Rounded)'),
];

const List<OptionItem> detectionAccuracyOptions = [
  OptionItem(value: '0', label: '0 (Lowest)'),
  OptionItem(value: '10', label: '10 (Default)'),
  OptionItem(value: '50', label: '50 (Medium)'),
  OptionItem(value: '100', label: '100 (Highest)'),
];

const List<OptionItem> iqaServiceOptions = [
  OptionItem(value: 'true', label: 'Enabled'),
  OptionItem(value: 'false', label: 'Disabled'),
];

class OCRUICustomizeDialog extends StatefulWidget {
  final Function(OCRUIConfig) onApply;

  const OCRUICustomizeDialog({
    super.key,
    required this.onApply,
  });

  @override
  State<OCRUICustomizeDialog> createState() => _OCRUICustomizeDialogState();
}

class _OCRUICustomizeDialogState extends State<OCRUICustomizeDialog> {
  String _placeholderTemplate = 'defaultStyle';
  String _orientation = 'horizontal';
  String _backgroundColor = 'purple';
  String _borderColor = 'white';
  String _cornerRadius = '8';
  String _detectionAccuracy = '10';
  String _backButtonEnabled = 'true';
  String _reviewScreenEnabled = 'true';
  String _reviewBackgroundColor = '';
  String _reviewBgImageBase64 = '';
  String _reviewBgContentMode = 'scaleAspectFill';
  String _reviewBgOpacity = '1.0';
  String _reviewBgBorderColor = 'clear';
  String _reviewBgBorderWidth = '0';
  String _reviewBgCornerRadius = '0';
  String _iqaServiceEnabled = 'true';

  void _handleApplyCustomization() {
    final config = OCRUIConfig(
      placeholderTemplate: _placeholderTemplate == 'hidden'
          ? OCRPlaceholderTemplate.hidden
          : _placeholderTemplate == 'countrySpecificStyle'
              ? OCRPlaceholderTemplate.countrySpecificStyle
              : OCRPlaceholderTemplate.defaultStyle,
      detectionAccuracy: int.parse(_detectionAccuracy),
      reviewScreenEnabled: _reviewScreenEnabled == 'true',
      reviewBackgroundColor: _reviewBackgroundColor.isNotEmpty ? _reviewBackgroundColor : null,
      reviewBackgroundStyle: _reviewBgImageBase64.isNotEmpty ? {
        'imageBase64': _reviewBgImageBase64,
        'contentMode': _reviewBgContentMode,
        'opacity': double.parse(_reviewBgOpacity),
        'borderColor': _reviewBgBorderColor,
        'borderWidth': double.parse(_reviewBgBorderWidth),
        'cornerRadius': double.parse(_reviewBgCornerRadius),
      } : null,
      iqaEnabled: _iqaServiceEnabled == 'true',
    );

    widget.onApply(config);
    Navigator.of(context).pop();
  }

  void _handleResetToDefaults() {
    setState(() {
      _placeholderTemplate = 'defaultStyle';
      _orientation = 'horizontal';
      _backgroundColor = 'purple';
      _borderColor = 'white';
      _cornerRadius = '8';
      _detectionAccuracy = '10';
      _backButtonEnabled = 'true';
      _reviewScreenEnabled = 'true';
      _reviewBackgroundColor = '';
      _reviewBgImageBase64 = '';
      _reviewBgContentMode = 'scaleAspectFill';
      _reviewBgOpacity = '1.0';
      _reviewBgBorderColor = 'clear';
      _reviewBgBorderWidth = '0';
      _reviewBgCornerRadius = '0';
      _iqaServiceEnabled = 'true';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All settings have been reset to defaults.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF6C757D), size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'OCR UI Customization',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: const Color(0xFFE9ECEF),
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Configure the appearance and behavior of the OCR camera interface',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C757D),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Placeholder Settings',
                      [
                        _buildOptionPicker(
                          'Placeholder Template',
                          placeholderTemplates,
                          _placeholderTemplate,
                          (value) => setState(() => _placeholderTemplate = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Orientation',
                          orientations,
                          _orientation,
                          (value) => setState(() => _orientation = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      'Visual Styling',
                      [
                        _buildOptionPicker(
                          'Background Color',
                          backgroundColors,
                          _backgroundColor,
                          (value) => setState(() => _backgroundColor = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Border Color',
                          borderColors,
                          _borderColor,
                          (value) => setState(() => _borderColor = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Corner Radius',
                          cornerRadiusOptions,
                          _cornerRadius,
                          (value) => setState(() => _cornerRadius = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      'Behavior Settings',
                      [
                        _buildOptionPicker(
                          'Detection Accuracy',
                          detectionAccuracyOptions,
                          _detectionAccuracy,
                          (value) => setState(() => _detectionAccuracy = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Back Button Enabled',
                          const [
                            OptionItem(value: 'true', label: 'Enabled'),
                            OptionItem(value: 'false', label: 'Disabled'),
                          ],
                          _backButtonEnabled,
                          (value) => setState(() => _backButtonEnabled = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Review Screen Enabled',
                          const [
                            OptionItem(value: 'true', label: 'Enabled'),
                            OptionItem(value: 'false', label: 'Disabled'),
                          ],
                          _reviewScreenEnabled,
                          (value) => setState(() => _reviewScreenEnabled = value),
                        ),
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'Review Background Color',
                          const [
                            OptionItem(value: '', label: 'Default'),
                            ...backgroundColors,
                          ],
                          _reviewBackgroundColor,
                          (value) => setState(() => _reviewBackgroundColor = value),
                        ),
                        if (Platform.isIOS) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Review Background Image (iOS only)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF495057),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _reviewBgImageBase64.isNotEmpty
                                          ? Colors.green
                                          : const Color(0xFF6C757D),
                                    ),
                                    onPressed: () async {
                                      try {
                                        final base64 = await OcrFlutter.takePhoto();
                                        setState(() => _reviewBgImageBase64 = base64);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Background image captured.')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      }
                                    },
                                    child: Text(_reviewBgImageBase64.isNotEmpty ? 'Retake Photo' : 'Take Photo'),
                                  ),
                                  if (_reviewBgImageBase64.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => setState(() => _reviewBgImageBase64 = ''),
                                      child: const Text('Clear'),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          if (_reviewBgImageBase64.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildOptionPicker(
                              'Image Content Mode',
                              const [
                                OptionItem(value: 'scaleAspectFill', label: 'Aspect Fill'),
                                OptionItem(value: 'scaleAspectFit', label: 'Aspect Fit'),
                                OptionItem(value: 'scaleToFill', label: 'Scale to Fill'),
                              ],
                              _reviewBgContentMode,
                              (value) => setState(() => _reviewBgContentMode = value),
                            ),
                            const SizedBox(height: 16),
                            _buildOptionPicker(
                              'Image Opacity',
                              const [
                                OptionItem(value: '1.0', label: '100%'),
                                OptionItem(value: '0.8', label: '80%'),
                                OptionItem(value: '0.5', label: '50%'),
                                OptionItem(value: '0.3', label: '30%'),
                              ],
                              _reviewBgOpacity,
                              (value) => setState(() => _reviewBgOpacity = value),
                            ),
                            const SizedBox(height: 16),
                            _buildOptionPicker(
                              'Image Border Color',
                              const [
                                OptionItem(value: 'clear', label: 'None'),
                                OptionItem(value: 'white', label: 'White'),
                                OptionItem(value: 'black', label: 'Black'),
                                OptionItem(value: 'gray', label: 'Gray'),
                              ],
                              _reviewBgBorderColor,
                              (value) => setState(() => _reviewBgBorderColor = value),
                            ),
                            const SizedBox(height: 16),
                            _buildOptionPicker(
                              'Image Border Width',
                              const [
                                OptionItem(value: '0', label: '0 (None)'),
                                OptionItem(value: '1', label: '1'),
                                OptionItem(value: '2', label: '2'),
                                OptionItem(value: '4', label: '4'),
                              ],
                              _reviewBgBorderWidth,
                              (value) => setState(() => _reviewBgBorderWidth = value),
                            ),
                            const SizedBox(height: 16),
                            _buildOptionPicker(
                              'Image Corner Radius',
                              const [
                                OptionItem(value: '0', label: '0 (Square)'),
                                OptionItem(value: '8', label: '8'),
                                OptionItem(value: '16', label: '16'),
                                OptionItem(value: '24', label: '24'),
                              ],
                              _reviewBgCornerRadius,
                              (value) => setState(() => _reviewBgCornerRadius = value),
                            ),
                          ],
                        ],
                        const SizedBox(height: 16),
                        _buildOptionPicker(
                          'IQA Service (Image Quality Analysis)',
                          iqaServiceOptions,
                          _iqaServiceEnabled,
                          (value) => setState(() => _iqaServiceEnabled = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleApplyCustomization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007BFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Apply Configuration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleResetToDefaults,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF6C757D),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              side: const BorderSide(color: Color(0xFF6C757D)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Reset to Defaults',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 3.84,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF495057),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildOptionPicker(
    String label,
    List<OptionItem> options,
    String selectedValue,
    Function(String) onValueChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF495057),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDEE2E6)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option.value,
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF212529),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onValueChange(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
