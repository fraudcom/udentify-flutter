import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveness_flutter/liveness_flutter.dart' as liveness;

/// Flutter UI Customization Dialog (matches React Native LivenessUICustomizeModal)
class LivenessUICustomizeDialog extends StatefulWidget {
  final Function(liveness.UISettings) onApply;
  final liveness.UISettings? currentConfig;

  const LivenessUICustomizeDialog({
    super.key,
    required this.onApply,
    this.currentConfig,
  });

  @override
  State<LivenessUICustomizeDialog> createState() => _LivenessUICustomizeDialogState();
}

class _LivenessUICustomizeDialogState extends State<LivenessUICustomizeDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Predefined color options for easy selection (matching React Native)
  static const List<ColorOption> _colorOptions = [
    ColorOption(value: '#844EE3', label: 'Purple (Default)', color: Color(0xFF844EE3)),
    ColorOption(value: '#007AFF', label: 'iOS Blue', color: Color(0xFF007AFF)),
    ColorOption(value: '#34C759', label: 'Green', color: Color(0xFF34C759)),
    ColorOption(value: '#FF3B30', label: 'Red', color: Color(0xFFFF3B30)),
    ColorOption(value: '#FF9500', label: 'Orange', color: Color(0xFFFF9500)),
    ColorOption(value: '#5856D6', label: 'Indigo', color: Color(0xFF5856D6)),
    ColorOption(value: '#AF52DE', label: 'Purple', color: Color(0xFFAF52DE)),
    ColorOption(value: '#FF2D92', label: 'Pink', color: Color(0xFFFF2D92)),
    ColorOption(value: '#8E8E93', label: 'Gray', color: Color(0xFF8E8E93)),
    ColorOption(value: '#000000', label: 'Black', color: Color(0xFF000000)),
    ColorOption(value: '#FFFFFF', label: 'White', color: Color(0xFFFFFFFF)),
    ColorOption(value: '#1C1C1E', label: 'Dark Gray', color: Color(0xFF1C1C1E)),
    ColorOption(value: '#F2F2F7', label: 'Light Gray', color: Color(0xFFF2F2F7)),
    ColorOption(value: '#0A84FF', label: 'Light Blue', color: Color(0xFF0A84FF)),
    ColorOption(value: '#30D158', label: 'Light Green', color: Color(0xFF30D158)),
    ColorOption(value: '#64D2FF', label: 'Cyan', color: Color(0xFF64D2FF)),
    ColorOption(value: '#FFFF00', label: 'Yellow (Android Demo)', color: Color(0xFFFFFF00)),
  ];

  // Font size options (matching React Native)
  static const List<DropdownOption> _fontSizeOptions = [
    DropdownOption(value: '12', label: '12pt (Small)'),
    DropdownOption(value: '14', label: '14pt'),
    DropdownOption(value: '16', label: '16pt (Default)'),
    DropdownOption(value: '18', label: '18pt'),
    DropdownOption(value: '20', label: '20pt'),
    DropdownOption(value: '24', label: '24pt (Large)'),
    DropdownOption(value: '28', label: '28pt (XL)'),
    DropdownOption(value: '30', label: '30pt (XXL)'),
    DropdownOption(value: '32', label: '32pt (XXXL)'),
  ];

  // Button height options (matching React Native)
  static const List<DropdownOption> _buttonHeightOptions = [
    DropdownOption(value: '40', label: '40dp (Small)'),
    DropdownOption(value: '48', label: '48dp (Default)'),
    DropdownOption(value: '56', label: '56dp (Material)'),
    DropdownOption(value: '64', label: '64dp (Large)'),
    DropdownOption(value: '70', label: '70dp (XL)'),
  ];

  // Corner radius options (matching React Native)
  static const List<DropdownOption> _cornerRadiusOptions = [
    DropdownOption(value: '0', label: '0 (Square)'),
    DropdownOption(value: '4', label: '4 (Slight)'),
    DropdownOption(value: '8', label: '8 (Default)'),
    DropdownOption(value: '12', label: '12 (Rounded)'),
    DropdownOption(value: '16', label: '16 (Very Rounded)'),
    DropdownOption(value: '24', label: '24 (Pill)'),
  ];

  // Camera position options (matching React Native)
  static const List<DropdownOption> _cameraPositionOptions = [
    DropdownOption(value: 'front', label: 'Front Camera'),
    DropdownOption(value: 'back', label: 'Back Camera'),
  ];

  // Timeout options (matching React Native)
  static const List<DropdownOption> _timeoutOptions = [
    DropdownOption(value: '10', label: '10 seconds'),
    DropdownOption(value: '15', label: '15 seconds'),
    DropdownOption(value: '20', label: '20 seconds'),
    DropdownOption(value: '30', label: '30 seconds'),
    DropdownOption(value: '45', label: '45 seconds'),
    DropdownOption(value: '60', label: '60 seconds'),
  ];

  // Delay options (matching React Native)
  static const List<DropdownOption> _delayOptions = [
    DropdownOption(value: '0.1', label: '0.1 seconds'),
    DropdownOption(value: '0.25', label: '0.25 seconds'),
    DropdownOption(value: '0.3', label: '0.3 seconds'),
    DropdownOption(value: '0.5', label: '0.5 seconds'),
    DropdownOption(value: '0.75', label: '0.75 seconds'),
    DropdownOption(value: '1.0', label: '1.0 second'),
  ];

  // Confidence options (matching React Native)
  static const List<DropdownOption> _confidenceOptions = [
    DropdownOption(value: '0.8', label: '0.8 (80%)'),
    DropdownOption(value: '0.85', label: '0.85 (85%)'),
    DropdownOption(value: '0.9', label: '0.9 (90%)'),
    DropdownOption(value: '0.95', label: '0.95 (95%)'),
    DropdownOption(value: '0.98', label: '0.98 (98%)'),
    DropdownOption(value: '0.99', label: '0.99 (99%)'),
  ];

  // Button margin options (matching React Native)
  static const List<DropdownOption> _buttonMarginOptions = [
    DropdownOption(value: '10', label: '10px'),
    DropdownOption(value: '15', label: '15px'),
    DropdownOption(value: '20', label: '20px'),
    DropdownOption(value: '25', label: '25px'),
    DropdownOption(value: '30', label: '30px'),
    DropdownOption(value: '40', label: '40px'),
    DropdownOption(value: '50', label: '50px'),
  ];

  // Color state - using exact iOS documentation names (matching React Native)
  String _titleColor = '#FFFFFF';
  String _titleBG = '#844EE3';
  String _buttonErrorColor = '#FF3B30';
  String _buttonSuccessColor = '#4CD964';
  String _buttonColor = '#844EE3';
  String _buttonTextColor = '#FFFFFF';
  String _buttonErrorTextColor = '#FFFFFF';
  String _buttonSuccessTextColor = '#FFFFFF';
  String _buttonBackColor = '#000000';
  String _footerTextColor = '#FFFFFF';
  String _checkmarkTintColor = '#FFFFFF';
  String _backgroundColor = '#844EE3';

  // Font configuration state (matching React Native)
  String _titleFontSize = '30';
  String _buttonFontSize = '30';
  String _footerFontSize = '24';
  String _gestureFontSize = '20';

  // Dimensions state (matching React Native)
  String _buttonHeight = '48';
  String _buttonCornerRadius = '8';
  String _buttonMarginLeft = '20';
  String _buttonMarginRight = '20';

  // Camera and timing configuration (matching React Native)
  String _cameraPosition = 'front';
  String _requestTimeout = '15';
  String _errorDelay = '0.25';
  String _successDelay = '0.75';
  String _maskConfidence = '0.95';

  // Behavior state (matching React Native)
  bool _autoTake = true;
  bool _backButtonEnabled = true;
  bool _maskDetection = false;
  bool _invertedAnimation = false;
  bool _multipleFacesRejected = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: Platform.isAndroid ? 1 : 5, vsync: this);
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadCurrentConfig() {
    if (widget.currentConfig != null) {
      final config = widget.currentConfig!;
      
      // Load colors
      if (config.colors != null) {
        _titleColor = config.colors!.titleColor ?? _titleColor;
        _titleBG = config.colors!.titleBG ?? _titleBG;
        _buttonErrorColor = config.colors!.buttonErrorColor ?? _buttonErrorColor;
        _buttonSuccessColor = config.colors!.buttonSuccessColor ?? _buttonSuccessColor;
        _buttonColor = config.colors!.buttonColor ?? _buttonColor;
        _buttonTextColor = config.colors!.buttonTextColor ?? _buttonTextColor;
        _buttonErrorTextColor = config.colors!.buttonErrorTextColor ?? _buttonErrorTextColor;
        _buttonSuccessTextColor = config.colors!.buttonSuccessTextColor ?? _buttonSuccessTextColor;
        _buttonBackColor = config.colors!.buttonBackColor ?? _buttonBackColor;
        _footerTextColor = config.colors!.footerTextColor ?? _footerTextColor;
        _checkmarkTintColor = config.colors!.checkmarkTintColor ?? _checkmarkTintColor;
        _backgroundColor = config.colors!.backgroundColor ?? _backgroundColor;
      }

      // Load dimensions
      if (config.dimensions != null) {
        _buttonHeight = config.dimensions!.buttonHeight?.toString() ?? _buttonHeight;
        _buttonCornerRadius = config.dimensions!.buttonCornerRadius?.toString() ?? _buttonCornerRadius;
        _gestureFontSize = config.dimensions!.gestureFontSize?.toString() ?? _gestureFontSize;
      }

      // Load configs
      if (config.configs != null) {
        _autoTake = config.configs!.autoTake ?? _autoTake;
        _backButtonEnabled = config.configs!.backButtonEnabled ?? _backButtonEnabled;
        _maskDetection = config.configs!.maskDetection ?? _maskDetection;
        _invertedAnimation = config.configs!.invertedAnimation ?? _invertedAnimation;
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF844EE3);
    }
  }

  Widget _buildColorSelector({
    required String title,
    required String description,
    required String selectedColor,
    required Function(String) onColorChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF495057)),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _parseColor(selectedColor),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: _colorOptions.map((option) => DropdownMenuItem(
                    value: option.value,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: option.color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(option.label),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onColorChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector({
    required String title,
    required String selectedValue,
    required List<DropdownOption> options,
    required Function(String) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: options.map((option) => DropdownMenuItem(
              value: option.value,
              child: Text(option.label),
            )).toList(),
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF495057)),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6C757D)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF844EE3),
            activeTrackColor: const Color(0xFF844EE3).withOpacity(0.3),
            inactiveThumbColor: const Color(0xFF6C757D),
            inactiveTrackColor: const Color(0xFFE9ECEF),
          ),
        ],
      ),
    );
  }

  Widget _buildAndroidInstructions() {
    const xmlInstructions = '''
To customize UI on Android, manually update these XML files:

📁 android/app/src/main/res/values/colors.xml:

<!-- UdentifyFACE Button Background Colors -->
<color name="udentifyface_btn_color">#844EE3</color>
<color name="udentifyface_btn_color_success">#4CD964</color>
<color name="udentifyface_btn_color_error">#FFFF00</color>
<color name="udentifyface_progress_background_color">#808080</color>

<!-- UdentifyFACE Button Text Colors -->
<color name="udentifyface_btn_text_color">#FFFFFF</color>
<color name="udentifyface_btn_text_color_success">#FFFFFF</color>
<color name="udentifyface_btn_text_color_error">#FFFFFF</color>

<!-- UdentifyFACE Background Colors -->
<color name="udentifyface_bg_color">#FF844EE3</color>
<color name="udentifyface_gesture_text_bg_color">#66808080</color>

📁 android/app/src/main/res/values/dimens.xml:

<!-- UdentifyFACE Button Dimensions -->
<dimen name="udentify_selfie_button_height">70dp</dimen>
<dimen name="udentify_selfie_button_horizontal_margin">16dp</dimen>
<dimen name="udentify_selfie_button_bottom_margin">40dp</dimen>
<dimen name="udentify_face_selfie_button_corner_radius">8dp</dimen>
<dimen name="udentifyface_gesture_font_size">30sp</dimen>

📁 android/app/src/main/res/values/strings.xml:

<!-- UdentifyFACE Strings -->
<string name="udentifyface_footer_button_text_default">Take Selfie</string>
<string name="udentifyface_footer_button_text_progressing">Liveness Check</string>
<string name="udentifyface_message_face_too_big">Move Back</string>
<string name="udentifyface_message_face_too_small">Move Closer</string>

⚡ After updating XML files:
Run "flutter clean && flutter build android" to rebuild the app

📖 For complete XML reference, check the UdentifyFACE Android documentation.
''';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Android Limitation Warning
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFEAA7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Android Limitation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF856404),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Android UdentifyFACE SDK only supports static XML resource customization.\n\n'
                  'Dynamic UI changes are not supported on Android platform.\n\n'
                  'To apply UI customization on Android:\n'
                  '• Update XML files in android/app/src/main/res/values/\n'
                  '• Rebuild the app with "flutter build android"\n\n'
                  'For dynamic UI customization, use iOS platform.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF856404),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: xmlInstructions));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('XML instructions copied to clipboard!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text('📋 Copy XML Instructions', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF856404),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // XML Instructions Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Android XML Customization Instructions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF495057),
                  ),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  xmlInstructions,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF495057),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌈 Colors (iOS Documentation Names)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildColorSelector(
            title: 'Title Color',
            description: 'Title\'s font color',
            selectedColor: _titleColor,
            onColorChanged: (color) => setState(() => _titleColor = color),
          ),
          
          _buildColorSelector(
            title: 'Title Background',
            description: 'Title\'s background color',
            selectedColor: _titleBG,
            onColorChanged: (color) => setState(() => _titleBG = color),
          ),
          
          _buildColorSelector(
            title: 'Button Error Color',
            description: 'The color of the process when the operation fails',
            selectedColor: _buttonErrorColor,
            onColorChanged: (color) => setState(() => _buttonErrorColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Success Color',
            description: 'The color of the process when the operation succeeds',
            selectedColor: _buttonSuccessColor,
            onColorChanged: (color) => setState(() => _buttonSuccessColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Color',
            description: 'Background color of the button',
            selectedColor: _buttonColor,
            onColorChanged: (color) => setState(() => _buttonColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Text Color',
            description: 'Font color of the button text',
            selectedColor: _buttonTextColor,
            onColorChanged: (color) => setState(() => _buttonTextColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Error Text Color',
            description: 'Font color of the button text when the operation fails',
            selectedColor: _buttonErrorTextColor,
            onColorChanged: (color) => setState(() => _buttonErrorTextColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Success Text Color',
            description: 'Font color of the button text when the operation succeeds',
            selectedColor: _buttonSuccessTextColor,
            onColorChanged: (color) => setState(() => _buttonSuccessTextColor = color),
          ),
          
          _buildColorSelector(
            title: 'Button Back Color',
            description: 'The color of back button',
            selectedColor: _buttonBackColor,
            onColorChanged: (color) => setState(() => _buttonBackColor = color),
          ),
          
          _buildColorSelector(
            title: 'Footer Text Color',
            description: 'Footer label\'s font color',
            selectedColor: _footerTextColor,
            onColorChanged: (color) => setState(() => _footerTextColor = color),
          ),
          
          _buildColorSelector(
            title: 'Checkmark Tint Color',
            description: 'The color of the checkmark',
            selectedColor: _checkmarkTintColor,
            onColorChanged: (color) => setState(() => _checkmarkTintColor = color),
          ),
          
          _buildColorSelector(
            title: 'Background Color',
            description: 'Background color of the view, currently used for the background of Active Liveness',
            selectedColor: _backgroundColor,
            onColorChanged: (color) => setState(() => _backgroundColor = color),
          ),
        ],
      ),
    );
  }

  Widget _buildFontsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔤 Fonts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildDropdownSelector(
            title: 'Title Font Size',
            selectedValue: _titleFontSize,
            options: _fontSizeOptions,
            onChanged: (value) => setState(() => _titleFontSize = value),
          ),
          
          _buildDropdownSelector(
            title: 'Button Font Size',
            selectedValue: _buttonFontSize,
            options: _fontSizeOptions,
            onChanged: (value) => setState(() => _buttonFontSize = value),
          ),
          
          _buildDropdownSelector(
            title: 'Footer Font Size',
            selectedValue: _footerFontSize,
            options: _fontSizeOptions,
            onChanged: (value) => setState(() => _footerFontSize = value),
          ),
          
          _buildDropdownSelector(
            title: 'Gesture Font Size (Active Liveness)',
            selectedValue: _gestureFontSize,
            options: _fontSizeOptions,
            onChanged: (value) => setState(() => _gestureFontSize = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📏 Dimensions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildDropdownSelector(
            title: 'Button Height',
            selectedValue: _buttonHeight,
            options: _buttonHeightOptions,
            onChanged: (value) => setState(() => _buttonHeight = value),
          ),
          
          _buildDropdownSelector(
            title: 'Button Corner Radius',
            selectedValue: _buttonCornerRadius,
            options: _cornerRadiusOptions,
            onChanged: (value) => setState(() => _buttonCornerRadius = value),
          ),
          
          _buildDropdownSelector(
            title: 'Button Margin Left',
            selectedValue: _buttonMarginLeft,
            options: _buttonMarginOptions,
            onChanged: (value) => setState(() => _buttonMarginLeft = value),
          ),
          
          _buildDropdownSelector(
            title: 'Button Margin Right',
            selectedValue: _buttonMarginRight,
            options: _buttonMarginOptions,
            onChanged: (value) => setState(() => _buttonMarginRight = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraTimingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📷 Camera & Timing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildDropdownSelector(
            title: 'Camera Position',
            selectedValue: _cameraPosition,
            options: _cameraPositionOptions,
            onChanged: (value) => setState(() => _cameraPosition = value),
          ),
          
          _buildDropdownSelector(
            title: 'Request Timeout',
            selectedValue: _requestTimeout,
            options: _timeoutOptions,
            onChanged: (value) => setState(() => _requestTimeout = value),
          ),
          
          _buildDropdownSelector(
            title: 'Error Delay',
            selectedValue: _errorDelay,
            options: _delayOptions,
            onChanged: (value) => setState(() => _errorDelay = value),
          ),
          
          _buildDropdownSelector(
            title: 'Success Delay',
            selectedValue: _successDelay,
            options: _delayOptions,
            onChanged: (value) => setState(() => _successDelay = value),
          ),
          
          _buildDropdownSelector(
            title: 'Mask Detection Confidence',
            selectedValue: _maskConfidence,
            options: _confidenceOptions,
            onChanged: (value) => setState(() => _maskConfidence = value),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Behavior',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          _buildSwitchTile(
            title: 'Auto Take Photo',
            description: 'Automatically capture when face is positioned correctly',
            value: _autoTake,
            onChanged: (value) => setState(() => _autoTake = value),
          ),
          
          _buildSwitchTile(
            title: 'Back Button',
            description: 'Show back button in the interface',
            value: _backButtonEnabled,
            onChanged: (value) => setState(() => _backButtonEnabled = value),
          ),
          
          _buildSwitchTile(
            title: 'Mask Detection',
            description: 'Detect and reject faces wearing masks',
            value: _maskDetection,
            onChanged: (value) => setState(() => _maskDetection = value),
          ),
          
          _buildSwitchTile(
            title: 'Inverted Animation',
            description: 'Interchange near and far animations',
            value: _invertedAnimation,
            onChanged: (value) => setState(() => _invertedAnimation = value),
          ),
          
          _buildSwitchTile(
            title: 'Multiple Faces Rejected',
            description: 'Reject capture when multiple faces are detected',
            value: _multipleFacesRejected,
            onChanged: (value) => setState(() => _multipleFacesRejected = value),
          ),
        ],
      ),
    );
  }

  liveness.UISettings _getCurrentConfig() {
    return liveness.UISettings(
      colors: liveness.UIColors(
        titleColor: _titleColor,
        titleBG: _titleBG,
        buttonErrorColor: _buttonErrorColor,
        buttonSuccessColor: _buttonSuccessColor,
        buttonColor: _buttonColor,
        buttonTextColor: _buttonTextColor,
        buttonErrorTextColor: _buttonErrorTextColor,
        buttonSuccessTextColor: _buttonSuccessTextColor,
        buttonBackColor: _buttonBackColor,
        footerTextColor: _footerTextColor,
        checkmarkTintColor: _checkmarkTintColor,
        backgroundColor: _backgroundColor,
      ),
      dimensions: liveness.UIDimensions(
        buttonHeight: double.parse(_buttonHeight),
        buttonCornerRadius: double.parse(_buttonCornerRadius),
        gestureFontSize: double.parse(_gestureFontSize),
      ),
      configs: liveness.UIConfigs(
        autoTake: _autoTake,
        backButtonEnabled: _backButtonEnabled,
        maskDetection: _maskDetection,
        invertedAnimation: _invertedAnimation,
      ),
    );
  }

  void _handleApplyCustomization() {
    final config = _getCurrentConfig();
    
    if (Platform.isAndroid) {
      // Show Android limitation dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Android UI Customization'),
          content: const Text(
            'Android UdentifyFACE SDK only supports static XML resource customization.\n\n'
            'Dynamic UI changes are not supported on Android platform.\n\n'
            'Would you like to see the XML update instructions?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Show XML instructions
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Android XML Instructions'),
                    content: const SingleChildScrollView(
                      child: SelectableText(
                        'To customize UI on Android, update XML files manually.\n\n'
                        'Use the XML Instructions tab for complete details.'
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('View Instructions'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _applyConfiguration(config);
              },
              child: const Text('Apply Anyway'),
            ),
          ],
        ),
      );
    } else {
      // iOS supports dynamic changes
      _applyConfiguration(config);
    }
  }

  void _applyConfiguration(liveness.UISettings config) {
    print('🎨 Applying Liveness UI Configuration: ${config.toMap()}');
    widget.onApply(config);
    Navigator.pop(context);
  }

  void _handleResetToDefaults() {
    setState(() {
      _titleColor = '#FFFFFF';
      _titleBG = '#844EE3';
      _buttonErrorColor = '#FF3B30';
      _buttonSuccessColor = '#4CD964';
      _buttonColor = '#844EE3';
      _buttonTextColor = '#FFFFFF';
      _buttonErrorTextColor = '#FFFFFF';
      _buttonSuccessTextColor = '#FFFFFF';
      _buttonBackColor = '#000000';
      _footerTextColor = '#FFFFFF';
      _checkmarkTintColor = '#FFFFFF';
      _backgroundColor = '#844EE3';
      
      _titleFontSize = '30';
      _buttonFontSize = '30';
      _footerFontSize = '24';
      _gestureFontSize = '20';
      
      _buttonHeight = '48';
      _buttonCornerRadius = '8';
      _buttonMarginLeft = '20';
      _buttonMarginRight = '20';
      
      _cameraPosition = 'front';
      _requestTimeout = '15';
      _errorDelay = '0.25';
      _successDelay = '0.75';
      _maskConfidence = '0.95';
      
      _autoTake = true;
      _backButtonEnabled = true;
      _maskDetection = false;
      _invertedAnimation = false;
      _multipleFacesRejected = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reset Complete - All settings have been reset to defaults.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liveness UI Customization'),
        backgroundColor: const Color(0xFF844EE3),
        foregroundColor: Colors.white,
        actions: [
          if (Platform.isIOS)
            IconButton(
              onPressed: _handleResetToDefaults,
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to Defaults',
            ),
        ],
        bottom: Platform.isAndroid ? null : TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: '🌈 Colors'),
            Tab(text: '🔤 Fonts'),
            Tab(text: '📏 Dimensions'),
            Tab(text: '📷 Camera'),
            Tab(text: '⚙️ Behavior'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Platform-specific subtitle
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Text(
              Platform.isAndroid 
                ? 'Android UdentifyFACE SDK UI customization requires manual XML resource file updates'
                : 'Comprehensive customization of the Face Recognition & Liveness Detection interface with real-time preview',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // iOS Success Message
          if (Platform.isIOS)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD4EDDA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC3E6CB)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✅ iOS Dynamic UI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF155724),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'iOS platform supports full dynamic UI customization. Changes will be applied immediately.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF155724),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: Platform.isAndroid 
              ? _buildAndroidInstructions()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildColorsTab(),
                    _buildFontsTab(),
                    _buildDimensionsTab(),
                    _buildCameraTimingTab(),
                    _buildBehaviorTab(),
                  ],
                ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Platform.isAndroid 
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  const xmlInstructions = '''
To customize UI on Android, manually update these XML files:

📁 android/app/src/main/res/values/colors.xml:

<!-- UdentifyFACE Button Background Colors -->
<color name="udentifyface_btn_color">#844EE3</color>
<color name="udentifyface_btn_color_success">#4CD964</color>
<color name="udentifyface_btn_color_error">#FFFF00</color>

<!-- UdentifyFACE Button Text Colors -->
<color name="udentifyface_btn_text_color">#FFFFFF</color>
<color name="udentifyface_btn_text_color_success">#FFFFFF</color>
<color name="udentifyface_btn_text_color_error">#FFFFFF</color>

<!-- UdentifyFACE Background Colors -->
<color name="udentifyface_bg_color">#FF844EE3</color>

📁 android/app/src/main/res/values/dimens.xml:

<!-- UdentifyFACE Button Dimensions -->
<dimen name="udentify_selfie_button_height">70dp</dimen>
<dimen name="udentify_selfie_button_horizontal_margin">16dp</dimen>
<dimen name="udentify_selfie_button_bottom_margin">40dp</dimen>
<dimen name="udentify_face_selfie_button_corner_radius">8dp</dimen>
<dimen name="udentifyface_gesture_font_size">30sp</dimen>

⚡ After updating XML files:
Run "flutter clean && flutter build android" to rebuild the app
''';
                  
                  Clipboard.setData(const ClipboardData(text: xmlInstructions));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('XML instructions copied to clipboard!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.white),
                label: const Text('📋 Generate XML Instructions', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF844EE3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _handleApplyCustomization,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF844EE3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Apply Configuration'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleResetToDefaults,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C757D),
                      side: const BorderSide(color: Color(0xFFE9ECEF), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

// Helper classes matching React Native structure
class ColorOption {
  final String value;
  final String label;
  final Color color;

  const ColorOption({
    required this.value,
    required this.label,
    required this.color,
  });
}

class DropdownOption {
  final String value;
  final String label;

  const DropdownOption({
    required this.value,
    required this.label,
  });
}