import 'package:flutter/material.dart';
import 'package:ocr_flutter/ocr_flutter.dart';
import 'package:udentify_core_flutter/udentify_core_flutter.dart';
import '../utils/api_utils.dart';
import '../models/app_constants.dart';
import '../models/ocr_constants.dart';
import '../services/global_ocr_callback_manager.dart';
import '../widgets/ocr/ocr_result_card.dart';
import '../widgets/ocr/ocr_ui_customize_dialog.dart';

class OcrTestPage extends StatefulWidget {
  final String pageId;
  
  const OcrTestPage({super.key, required this.pageId});

  @override
  State<OcrTestPage> createState() => _OcrTestPageState();
}

class _OcrTestPageState extends State<OcrTestPage> {
  String _status = "Ready";
  String? _currentTransactionId;
  OCRDocumentType _selectedDocumentType = OCRDocumentType.idCard;
  OCRCountry? _selectedCountry = OCRCountry.turkey;
  OCRDocumentSide _selectedDocumentSide = OCRDocumentSide.bothSides;
  bool _manualCapture = false;
  bool _u18Enabled = false;
  double _rawPhotoCropRatio = 0.35;
  bool _isProcessing = false;

  OCRResponse? _ocrResponse;
  HologramResponse? _hologramResponse;
  OCRAndDocumentLivenessResponse? _livenessResponse;
  
  // Error state management
  String? _lastError;
  bool _hasError = false;

  // Store captured images from camera
  String? _capturedFrontImage;
  String? _capturedBackImage;

  // Track what type of operation is expected after image capture
  bool _isLivenessOperation = false;
  bool _isDocumentLivenessOnly = false;
  bool _hologramSupportRequested = false;

  // UI Configuration options
  bool _useCustomUI = false;
  String _selectedUIPreset = OCRConstants.uiPresetDefault;

  // UI Configuration parameters
  double _blurCoefficient = OCRConstants.defaultBlurCoefficient;
  int _detectionAccuracy = OCRConstants.defaultDetectionAccuracy;
  bool _reviewScreenEnabled = OCRConstants.defaultReviewScreenEnabled;
  bool _footerViewHidden = OCRConstants.defaultFooterViewHidden;
  String _buttonBackColor = OCRConstants.defaultButtonBackColor;
  String _maskLayerColor = OCRConstants.defaultMaskLayerColor;
  OCRPlaceholderTemplate _placeholderTemplate =
      OCRPlaceholderTemplate.defaultStyle;

  // Global OCR callback manager
  final GlobalOCRCallbackManager _ocrCallbackManager = GlobalOCRCallbackManager();

  @override
  void initState() {
    super.initState();
    _setupOCRCallbacks();
  }

  @override
  void dispose() {
    // Unregister this page from global callback manager
    _ocrCallbackManager.unregisterPage(widget.pageId);
    super.dispose();
  }

  void _setupOCRCallbacks() {
    print('🔧 OCR Test Page: Setting up callbacks for page ${widget.pageId}');
    
    // Register this page's callbacks with the global manager
    final callbacks = OCRCallbackSet(
      onOCRSuccess: (OCRResponse response) {
        if (!mounted) return;
        print('🎉 OCR Test Page: OCR SUCCESS CALLBACK for ${widget.pageId}');
        print('📊 Response Type: ${response.responseType}');
        
        setState(() {
          _ocrResponse = response;
          _status = '✅ OCR completed successfully via camera!';
          _isProcessing = false;
        });
      },
      
      onOCRFailure: (String error) {
        if (!mounted) return;
        print('💥 OCR Test Page: OCR FAILURE CALLBACK for ${widget.pageId}: $error');
        
        setState(() {
          _status = '❌ OCR failed: $error';
          _isProcessing = false;
        });
      },
      
      onDocumentScan: (String documentSide, String? frontPhoto, String? backPhoto) {
        if (!mounted) return;
        print('📸 OCR Test Page: DOCUMENT SCAN CALLBACK for ${widget.pageId}');
        print('   Document Side: $documentSide');
        
        // Handle placeholder for images stored as paths in Swift
        final bool hasFrontImage = frontPhoto != null && frontPhoto.isNotEmpty;
        final bool hasBackImage = backPhoto != null && backPhoto.isNotEmpty;
        final bool isPathStored = frontPhoto == 'IMAGE_PATH_STORED' || backPhoto == 'IMAGE_PATH_STORED';
        
        if (isPathStored) {
          print('   Front Image: ✅ Stored as path in native (will be used in performOCR)');
          print('   Back Image: ✅ Stored as path in native (will be used in performOCR)');
        } else {
          print('   Front Image: ${hasFrontImage ? "✅ Captured (${frontPhoto!.length} chars)" : "❌ Not captured"}');
          print('   Back Image: ${hasBackImage ? "✅ Captured (${backPhoto!.length} chars)" : "❌ Not captured"}');
        }
        
        setState(() {
          // Don't store placeholder strings - native will use stored paths
          _capturedFrontImage = isPathStored ? null : frontPhoto;
          _capturedBackImage = isPathStored ? null : backPhoto;
          _status = '📸 Document captured: $documentSide side(s)';
        });

        // Auto-trigger processing - works for both base64 and path-stored images
        if (hasFrontImage || hasBackImage) {
          if (_isLivenessOperation) {
            print('🚀 Auto-triggering OCR + Liveness processing...');
            _performOCRAndLivenessWithCapturedImages();
          } else if (_isDocumentLivenessOnly) {
            print('🚀 Auto-triggering Document Liveness processing...');
            _performDocumentLivenessWithCapturedImages();
          } else {
            print('🚀 Auto-triggering OCR processing (like React Native)...');
            _performOCRWithCapturedImages();
          }
        }
      },
      
      onBackButtonPressed: () {
        if (!mounted) return;
        print('🔙 OCR Test Page: BACK BUTTON PRESSED CALLBACK for ${widget.pageId}');
        
        setState(() {
          _status = '🔙 User pressed back button in OCR camera';
          _isProcessing = false;
        });
      },
      
      onOCRAndDocumentLivenessResult: (OCRAndDocumentLivenessResponse response) {
        if (!mounted) return;
        print('🎉 OCR Test Page: OCR + LIVENESS SUCCESS CALLBACK for ${widget.pageId}');
        
        setState(() {
          _livenessResponse = response;
          
          // Extract OCR data from liveness response for display
          if (response.ocrData?.ocrResponse != null) {
            _ocrResponse = response.ocrData!.ocrResponse!;
          }
          
          _status = '✅ OCR + Document Liveness completed via camera!';
          _isProcessing = false;
        });
      },
      
      onHologramVideoRecorded: (List<String> videoUrls) {
        if (!mounted) return;
        print('🎬 OCR Test Page: HOLOGRAM VIDEO RECORDED CALLBACK for ${widget.pageId}');
        print('   Video URLs: ${videoUrls.length} videos');
        
        setState(() {
          _status = '🎬 Hologram video recorded successfully!';
          _isProcessing = false;
        });

        // Auto-upload the hologram video
        _uploadHologramVideo(videoUrls);
      },
      
      onHologramFailure: (String error) {
        if (!mounted) return;
        print('💥 OCR Test Page: HOLOGRAM FAILURE CALLBACK for ${widget.pageId}: $error');
        
        setState(() {
          _status = '❌ Hologram failed: $error';
          _isProcessing = false;
        });
      },
      
      onHologramBackButtonPressed: () {
        if (!mounted) return;
        print('🔙 OCR Test Page: HOLOGRAM BACK BUTTON PRESSED CALLBACK for ${widget.pageId}');
        
        setState(() {
          _status = '🔙 User pressed back button in hologram camera';
          _isProcessing = false;
        });
      },
    );
    
    // Register callbacks with global manager
    _ocrCallbackManager.registerPage(widget.pageId, callbacks);

    // Directive listeners
    OcrFlutter.setOnOCRDirectiveChangedCallback((directive, timestamp) {
      debugPrint('OCRTestPage - OCR Directive Changed: $directive at $timestamp');
    });
    OcrFlutter.setOnHologramDirectiveChangedCallback((directive, timestamp) {
      debugPrint('OCRTestPage - Hologram Directive Changed: $directive at $timestamp');
    });
  }

  // Apply UI configuration before starting OCR
  Future<void> _applyUIConfiguration() async {
    if (!_useCustomUI) return;

    try {
      print('OCRTestPage - Applying UI configuration: $_selectedUIPreset');
      final config = _buildUIConfig();
      await OcrFlutter.setOCRUIConfig(config);
      print('OCRTestPage - UI configuration applied successfully');
    } catch (e) {
      print('OCRTestPage - Failed to apply UI configuration: $e');
    }
  }

  // Build UI configuration based on current settings
  OCRUIConfig _buildUIConfig() {
    switch (_selectedUIPreset) {
      case OCRConstants.uiPresetDark:
        return _buildDarkThemeConfig();
      case OCRConstants.uiPresetColorful:
        return _buildColorfulThemeConfig();
      case OCRConstants.uiPresetMinimal:
        return _buildMinimalThemeConfig();
      case OCRConstants.uiPresetAllPink:
        return _buildAllPinkThemeConfig();
      case OCRConstants.uiPresetCustom:
        return _buildCustomConfig();
      default:
        return _buildDefaultConfig();
    }
  }

  OCRUIConfig _buildDefaultConfig() {
    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: _detectionAccuracy,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: _footerViewHidden,
      buttonBackColor: _buttonBackColor,
      maskLayerColor: _maskLayerColor,
      placeholderTemplate: _placeholderTemplate,
      cardMaskViewStrokeColor: '#CCFFFFFF',
      cardMaskViewBackgroundColor: _buttonBackColor,
      maskCardColor: '#00000000',
      maskBorderStrokeColor: '#CCFFFFFF',
      idTurBackgroundColor: '#FFFFFF',
      buttonTextColor: '#333333',
      footerButtonColorSuccess: '#4CAF50',
      footerButtonColorError: '#FF5722',
    );
  }

  OCRUIConfig _buildDarkThemeConfig() {
    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: _detectionAccuracy,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: _footerViewHidden,
      buttonBackColor: '#2D2D2D',
      maskLayerColor: '#CC000000',
      placeholderTemplate: _placeholderTemplate,
      placeholderContainerStyle: OCRViewStyle(
        backgroundColor: '#1E1E1E',
        borderColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 2.0,
      ),
      titleLabelStyle: OCRTextStyle(
        textColor: '#FFFFFF',
        fontSize: 18.0,
        fontBold: true,
      ),
      instructionLabelStyle: OCRTextStyle(
        textColor: '#CCCCCC',
        fontSize: 14.0,
      ),
      footerViewStyle: OCRButtonStyle(
        backgroundColor: '#4A4A4A',
        textColor: '#FFFFFF',
        cornerRadius: 8.0,
        fontBold: true,
      ),
      buttonUseStyle: OCRButtonStyle(
        backgroundColor: '#007AFF',
        textColor: '#FFFFFF',
        cornerRadius: 8.0,
        fontBold: true,
      ),
      buttonRetakeStyle: OCRButtonStyle(
        backgroundColor: '#FF3B30',
        textColor: '#FFFFFF',
        cornerRadius: 8.0,
        fontBold: true,
      ),
      cardMaskViewStrokeColor: '#CCFFFFFF',
      cardMaskViewBackgroundColor: '#2D2D2D',
      maskCardColor: '#00000000',
      maskBorderStrokeColor: '#CCFFFFFF',
      idTurBackgroundColor: '#1E1E1E',
      buttonTextColor: '#FFFFFF',
      footerButtonColorSuccess: '#4CAF50',
      footerButtonColorError: '#FF5722',
    );
  }

  OCRUIConfig _buildColorfulThemeConfig() {
    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: 10,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: _footerViewHidden,
      buttonBackColor: '#00FF00',
      maskLayerColor: '#8000FF00',
      placeholderTemplate: _placeholderTemplate,
      placeholderContainerStyle: OCRViewStyle(
        backgroundColor: '#FFFF00',
        borderColor: '#FFFF00',
        cornerRadius: 12.0,
        borderWidth: 5.0,
      ),
      titleLabelStyle: OCRTextStyle(
        textColor: '#FF6B6B',
        fontSize: 20.0,
        fontBold: true,
      ),
      instructionLabelStyle: OCRTextStyle(
        textColor: '#666666',
        fontSize: 16.0,
      ),
      footerViewStyle: OCRButtonStyle(
        backgroundColor: '#FF00FF',
        borderColor: '#FFFF00',
        textColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      buttonUseStyle: OCRButtonStyle(
        backgroundColor: '#0000FF',
        borderColor: '#FFFF00',
        textColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      buttonRetakeStyle: OCRButtonStyle(
        backgroundColor: '#FF0000',
        borderColor: '#FFFF00',
        textColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      cardMaskViewStrokeColor: '#FFFFFF00',
      cardMaskViewBackgroundColor: '#FFFF00',
      maskCardColor: '#8000FF00',
      maskBorderStrokeColor: '#FFFF0000',
      idTurBackgroundColor: '#FF00FF',
      buttonTextColor: '#FFFFFF',
      footerButtonColorSuccess: '#0000FF',
      footerButtonColorError: '#FF0000',
    );
  }

  OCRUIConfig _buildAllPinkThemeConfig() {
    const pinkColor = '#FF69B4';
    const darkPink = '#FF1493';
    const lightPink = '#FFB6C1';

    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: 10,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: _footerViewHidden,
      buttonBackColor: pinkColor,
      maskLayerColor: '#80FF69B4',
      placeholderTemplate: _placeholderTemplate,
      placeholderContainerStyle: OCRViewStyle(
        backgroundColor: pinkColor,
        borderColor: darkPink,
        cornerRadius: 12.0,
        borderWidth: 5.0,
      ),
      titleLabelStyle: OCRTextStyle(
        textColor: darkPink,
        fontSize: 20.0,
        fontBold: true,
      ),
      instructionLabelStyle: OCRTextStyle(
        textColor: darkPink,
        fontSize: 16.0,
      ),
      footerViewStyle: OCRButtonStyle(
        backgroundColor: pinkColor,
        borderColor: darkPink,
        textColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      buttonUseStyle: OCRButtonStyle(
        backgroundColor: darkPink,
        borderColor: pinkColor,
        textColor: '#FFFFFF',
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      buttonRetakeStyle: OCRButtonStyle(
        backgroundColor: lightPink,
        borderColor: darkPink,
        textColor: darkPink,
        cornerRadius: 12.0,
        borderWidth: 3.0,
        fontBold: true,
      ),
      cardMaskViewStrokeColor: darkPink,
      cardMaskViewBackgroundColor: pinkColor,
      maskCardColor: '#20FF69B4',
      maskBorderStrokeColor: darkPink,
      idTurBackgroundColor: lightPink,
      buttonTextColor: '#FFFFFF',
      footerButtonColorSuccess: pinkColor,
      footerButtonColorError: darkPink,
    );
  }

  OCRUIConfig _buildMinimalThemeConfig() {
    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: _detectionAccuracy,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: true,
      buttonBackColor: '#F8F8F8',
      maskLayerColor: '#40000000',
      placeholderTemplate: OCRPlaceholderTemplate.hidden,
      titleLabelStyle: OCRTextStyle(
        textColor: '#333333',
        fontSize: 16.0,
        fontBold: false,
      ),
      instructionLabelStyle: OCRTextStyle(
        textColor: '#666666',
        fontSize: 12.0,
      ),
      cardMaskViewStrokeColor: '#CCCCCCCC',
      cardMaskViewBackgroundColor: '#F8F8F8',
      maskCardColor: '#20000000',
      maskBorderStrokeColor: '#CCCCCCCC',
      idTurBackgroundColor: '#FFFFFF',
      buttonTextColor: '#333333',
      footerButtonColorSuccess: '#4CAF50',
      footerButtonColorError: '#FF5722',
    );
  }

  OCRUIConfig _buildCustomConfig() {
    return OCRUIConfig(
      blurCoefficient: _blurCoefficient,
      detectionAccuracy: _detectionAccuracy,
      reviewScreenEnabled: _reviewScreenEnabled,
      footerViewHidden: _footerViewHidden,
      buttonBackColor: _buttonBackColor,
      maskLayerColor: _maskLayerColor,
      placeholderTemplate: _placeholderTemplate,
    );
  }

  Future<void> _startOCRCamera() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Getting transaction ID...';
      _ocrResponse = null;
      _isLivenessOperation = false; // This is regular OCR
      _isDocumentLivenessOnly = false;
      _hasError = false;
      _lastError = null;
    });

    try {
      await _applyUIConfiguration();

      // Reset cached transaction properties before starting a new transaction
      await UdentifyCoreFlutter.resetTransactionProperties();

      // Get transaction ID from API - always include hologram support for flexibility
      final transactionId = await ApiUtils.getTransactionId(
        OCRConstants.ocrAndHologramModules,
        transactionProperties: _u18Enabled ? ['U18'] : null,
      );
      if (transactionId == null) {
        setState(() {
          _status = 'Failed to get transaction ID';
          _isProcessing = false;
        });
        return;
      }

      // Populate the SDK cache before opening the camera so U18 handling applies
      final fetchedProperties = await UdentifyCoreFlutter.fetchTransactionProperties(
          ApiUtils.serverUrl, transactionId);
      print('OCRTestPage - Fetched transaction properties: '
          '${fetchedProperties ?? '(not returned on this platform)'} '
          '(U18 enabled: $_u18Enabled)');

      setState(() {
        _currentTransactionId = transactionId;
        _status = 'Starting OCR camera...';
      });

      final params = OCRCameraParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: transactionId,
        userID: ApiUtils.apiKey,
        documentType: _selectedDocumentType,
        country: _selectedCountry,
        documentSide: _selectedDocumentSide,
        manualCapture: _manualCapture,
        rawPhotoCropRatio: _rawPhotoCropRatio,
      );

      final success = await OcrFlutter.startOCRCamera(params);

      setState(() {
        _status = success
            ? 'OCR camera started successfully'
            : 'Failed to start OCR camera';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'OCR camera failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startOCRAndLivenessCamera() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Getting transaction ID...';
      _livenessResponse = null;
      _isLivenessOperation = true; // This is OCR + Liveness
      _isDocumentLivenessOnly = false;
      _hasError = false;
      _lastError = null;
    });

    try {
      // Apply UI configuration first
      await _applyUIConfiguration();

      // Get transaction ID from API for OCR and document liveness - include hologram support
      final transactionId =
          await ApiUtils.getTransactionId(OCRConstants.ocrAndHologramModules);
      if (transactionId == null) {
        setState(() {
          _status = 'Failed to get transaction ID';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _currentTransactionId = transactionId;
        _status = 'Starting OCR + Liveness camera...';
      });

      final params = OCRCameraParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: transactionId,
        userID: ApiUtils.apiKey,
        documentType: _selectedDocumentType,
        country: _selectedCountry,
        documentSide: _selectedDocumentSide,
        manualCapture: _manualCapture,
        livenessMode: true, // NEW: Enable liveness mode for OCR + Liveness
      );

      final success = await OcrFlutter.startOCRCamera(params);

      setState(() {
        _status = success
            ? 'OCR + Liveness camera started successfully'
            : 'Failed to start OCR + Liveness camera';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'OCR + Liveness camera failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startDocumentLivenessCamera() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Getting transaction ID for document liveness...';
      _livenessResponse = null;
      _isLivenessOperation = false;
      _isDocumentLivenessOnly = true; // This is Document Liveness only (no OCR)
      _hasError = false;
      _lastError = null;
    });

    try {
      // Apply UI configuration first
      await _applyUIConfiguration();

      // Get transaction ID from API
      final transactionId =
          await ApiUtils.getTransactionId(OCRConstants.ocrAndHologramModules);
      if (transactionId == null) {
        setState(() {
          _status = 'Failed to get transaction ID';
          _isProcessing = false;
        });
        return;
      }

      setState(() {
        _currentTransactionId = transactionId;
        _status = 'Starting camera for document liveness check...';
      });

      // Start OCR camera to capture the document (without liveness mode)
      final params = OCRCameraParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: transactionId,
        userID: ApiUtils.apiKey,
        documentType: _selectedDocumentType,
        country: _selectedCountry,
        documentSide: _selectedDocumentSide,
        manualCapture: _manualCapture,
        livenessMode: false, // No liveness mode - just capture
      );

      final success = await OcrFlutter.startOCRCamera(params);

      setState(() {
        _status = success
            ? 'Camera started successfully - document will be checked for liveness after capture'
            : 'Failed to start camera';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Document liveness camera failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _startHologramCamera() async {
    if (_isProcessing) return;

    // Check if we have OCR data and captured images from a previous operation
    if (_ocrResponse == null) {
      setState(() {
        _status =
            '⚠️ Please complete OCR first to get document data for hologram verification';
      });
      return;
    }

    if (_currentTransactionId == null) {
      setState(() {
        _status = '⚠️ No transaction ID available from OCR operation';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Uploading OCR data to server before hologram verification...';
      _hologramResponse = null;
    });

    try {
      // First, ensure OCR data is uploaded to server using captured images
      if (_capturedFrontImage != null || _capturedBackImage != null) {
        await _performOCRWithCapturedImages();

        // Wait a moment for the upload to complete
        await Future.delayed(Duration(seconds: 2));
      }

      setState(() {
        _status = 'Starting hologram camera with existing OCR transaction...';
      });

      final params = HologramParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: _currentTransactionId!,
        userID: ApiUtils.apiKey,
        country: _selectedCountry,
        logLevel: 'warning',
      );

      print('🎬 HOLOGRAM PARAMS DEBUG:');
      print('   Transaction ID: ${_currentTransactionId}');
      print('   Server URL: ${params.serverURL}');
      print('   Country: ${params.country}');
      print('   OCR Response Available: ${_ocrResponse != null}');
      print('   Front Image Available: ${_capturedFrontImage != null}');
      print('   Back Image Available: ${_capturedBackImage != null}');

      final success = await OcrFlutter.startHologramCamera(params);

      setState(() {
        _status = success
            ? 'Hologram camera started successfully'
            : 'Failed to start hologram camera';
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Hologram camera failed: $e';
        _isProcessing = false;
      });
      print('💥 HOLOGRAM CAMERA ERROR: $e');
    }
  }

  // TEST-ONLY: verifies the "provided photos" performOCR path (frontSidePhoto/
  // backSidePhoto with real external base64), separate from the camera-capture flow.
  Future<void> _testProvidedPhotoOCR() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Provided-photo OCR: getting transaction ID...';
    });

    try {
      String txId = _currentTransactionId ?? '';
      if (txId.isEmpty) {
        final newTxId =
            await ApiUtils.getTransactionId(OCRConstants.ocrAndHologramModules);
        if (newTxId == null) {
          setState(() {
            _status = 'Failed to get transaction ID';
            _isProcessing = false;
          });
          return;
        }
        txId = newTxId;
        _currentTransactionId = txId;
      }

      setState(() => _status = 'Take a photo of the FRONT side...');
      final frontB64 = await OcrFlutter.takePhoto();
      debugPrint('OCRTestPage - Provided OCR: FRONT base64 length: ${frontB64.length}');

      setState(() => _status = 'Take a photo of the BACK side...');
      final backB64 = await OcrFlutter.takePhoto();
      debugPrint('OCRTestPage - Provided OCR: BACK base64 length: ${backB64.length}');

      setState(() => _status = 'Calling performOCR with provided base64 photos...');
      final response = await OcrFlutter.performOCR(OCRProcessParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: txId,
        documentType: _selectedDocumentType,
        country: _selectedCountry,
        frontSidePhoto: frontB64,
        backSidePhoto: backB64,
      ));

      final id = response.idCardResponse;
      debugPrint('OCRTestPage - Provided OCR response: ${response.responseType}, '
          'name=${id?.firstName} ${id?.lastName}, id=${id?.identityNo}');

      setState(() {
        _status = 'Provided-photo OCR done: ${response.responseType}\n'
            '${id?.firstName ?? ''} ${id?.lastName ?? ''} ${id?.identityNo ?? ''}';
        _isProcessing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Provided-photo OCR Result'),
            content: Text('type: ${response.responseType}\n'
                'name: ${id?.firstName} ${id?.lastName}\n'
                'id: ${id?.identityNo}\n'
                'success: ${response.success}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('OCRTestPage - Provided-photo OCR failed: $e');
      setState(() {
        _status = 'Provided-photo OCR failed: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _testStandaloneIQA() async {
    if (_isProcessing) return;

    // Show side selection dialog
    final side = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Side'),
        content: const Text('Which side do you want to test IQA with?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'FRONT'),
            child: const Text('Front'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'BACK'),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (side == null) return;

    setState(() {
      _isProcessing = true;
      _status = 'Taking photo for $side side IQA...';
    });

    try {
      // Get or create transaction ID
      String txId = _currentTransactionId ?? '';
      if (txId.isEmpty) {
        final newTxId = await ApiUtils.getTransactionId(OCRConstants.ocrAndHologramModules);
        if (newTxId == null) {
          setState(() {
            _status = 'Failed to get transaction ID for IQA';
            _isProcessing = false;
          });
          return;
        }
        txId = newTxId;
        _currentTransactionId = txId;
      }

      // Take photo
      final base64 = await OcrFlutter.takePhoto();
      debugPrint('OCRTestPage - Photo captured, base64 length: ${base64.length}');

      setState(() {
        _status = 'Sending to performIQA for $side side...';
      });

      // Perform IQA
      final result = await OcrFlutter.performIQA(
        serverURL: ApiUtils.serverUrl,
        transactionID: txId,
        imageBase64: base64,
        documentType: _selectedDocumentType.value,
        documentSide: side,
        country: _selectedCountry?.value ?? 'TUR',
      );

      debugPrint('OCRTestPage - IQA Result: $result');

      setState(() {
        _status = 'IQA Result: ${result['qualified'] == true ? 'Qualified' : 'Not Qualified'}\n${result['displayMessage'] ?? ''}';
        _isProcessing = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('IQA Result'),
            content: Text(result.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'IQA Error: $e';
        _isProcessing = false;
      });
      debugPrint('OCRTestPage - IQA Error: $e');
    }
  }

  Future<void> _uploadHologramVideo(List<String> videoUrls) async {
    if (_currentTransactionId == null) {
      setState(() {
        _status = '❌ No transaction ID available for hologram upload';
      });
      return;
    }

    setState(() {
      _status = 'Uploading hologram video...';
      _isProcessing = true;
    });

    try {
      final params = HologramParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: _currentTransactionId!,
        userID: ApiUtils.apiKey,
        country: _selectedCountry, // Use selected country for consistency
        logLevel: 'warning',
      );

      final response = await OcrFlutter.uploadHologramVideo(params, videoUrls);

      setState(() {
        _hologramResponse = response;
        _status = '✅ Hologram upload completed!';
        _isProcessing = false;
      });

      print('🎬 HOLOGRAM UPLOAD SUCCESS:');
      print('   Transaction ID: ${response.transactionID}');
      print('   ID Number: ${response.idNumber}');
      print('   Hologram Exists: ${response.hologramExists}');
      print('   ID Match: ${response.ocrIdAndHologramIdMatch}');
      print('   Face Match: ${response.ocrFaceAndHologramFaceMatch}');
    } catch (e) {
      setState(() {
        _status = '❌ Hologram upload failed: $e';
        _isProcessing = false;
      });
      print('💥 HOLOGRAM UPLOAD FAILED: $e');
    }
  }

  Future<void> _performOCRWithCapturedImages() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing OCR with captured images...';
      _ocrResponse = null;
      _hasError = false;
      _lastError = null;
    });

    try {
      // Use the existing transaction ID from camera session
      if (_currentTransactionId == null) {
        setState(() {
          _status = 'No transaction ID available';
          _isProcessing = false;
        });
        return;
      }

      print('🚀 _performOCRWithCapturedImages - Starting OCR processing...');
      print('📋 Transaction ID: $_currentTransactionId');
      print('🖼️ Front Image: ${_capturedFrontImage != null ? "Available (${_capturedFrontImage!.length} chars)" : "Stored in native"}');
      print('🖼️ Back Image: ${_capturedBackImage != null ? "Available (${_capturedBackImage!.length} chars)" : "Stored in native"}');

      // Send null for images when they're stored as paths in native
      final params = OCRProcessParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: _currentTransactionId!,
        userID: ApiUtils.apiKey,
        frontSidePhoto: _capturedFrontImage,
        backSidePhoto: _capturedBackImage,
        country: _selectedCountry,
        documentType: _selectedDocumentType,
        requestTimeout: 30,
      );

      print('📡 About to call OcrFlutter.performOCR...');
      final response = await OcrFlutter.performOCR(params);
      print('✅ OcrFlutter.performOCR completed successfully!');
      print('📊 Response Type: ${response.responseType}');
      print('🔍 Response Details: ${response.toString()}');

      setState(() {
        _ocrResponse = response;
        _status = '✅ OCR completed with captured images!';
        _isProcessing = false;
      });

      print('🎯 OCR PROCESSING COMPLETED with captured images!');
      print('🎨 UI State updated - _ocrResponse should now be visible in UI');
    } catch (e, stackTrace) {
      print('💥 OCR PROCESSING FAILED: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _status = '❌ OCR failed: ${_getErrorMessage(e)}';
        _lastError = e.toString();
        _hasError = true;
        _isProcessing = false;
      });
    }
  }

  Future<void> _performOCRAndLivenessWithCapturedImages() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing OCR + Liveness with captured images...';
      _livenessResponse = null;
      _hasError = false;
      _lastError = null;
    });

    try {
      // Use the existing transaction ID from camera session
      if (_currentTransactionId == null) {
        setState(() {
          _status = 'No transaction ID available';
          _isProcessing = false;
        });
        return;
      }

      // Send null for images when they're stored as paths in native
      final params = OCRAndDocumentLivenessParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: _currentTransactionId!,
        userID: ApiUtils.apiKey,
        frontSidePhoto: _capturedFrontImage,
        backSidePhoto: _capturedBackImage,
        country: _selectedCountry,
        documentType: _selectedDocumentType,
        requestTimeout: 30,
      );

      final response = await OcrFlutter.performOCRAndDocumentLiveness(params);

      setState(() {
        _livenessResponse = response;
        
        // Extract OCR data from liveness response (works for both Android and iOS)
        if (response.ocrData?.ocrResponse != null) {
          _ocrResponse = response.ocrData!.ocrResponse!;
        }
        
        _status = '✅ OCR + Liveness completed with captured images!';
        _isProcessing = false;
      });

      print('🎯 OCR + LIVENESS PROCESSING COMPLETED with captured images!');
      print('📊 Failed: ${response.isFailed}');
    } catch (e, stackTrace) {
      print('💥 OCR + LIVENESS PROCESSING FAILED: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _status = '❌ OCR + Liveness failed: ${_getErrorMessage(e)}';
        _lastError = e.toString();
        _hasError = true;
        _isProcessing = false;
      });
    }
  }

  Future<void> _performDocumentLivenessWithCapturedImages() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _status = 'Processing Document Liveness with captured images...';
      _livenessResponse = null;
      _hasError = false;
      _lastError = null;
    });

    try {
      // Use the existing transaction ID from camera session
      if (_currentTransactionId == null) {
        setState(() {
          _status = 'No transaction ID available';
          _isProcessing = false;
        });
        return;
      }

      print('🚀 _performDocumentLivenessWithCapturedImages - Starting Document Liveness check...');
      print('📋 Transaction ID: $_currentTransactionId');
      print('🖼️ Front Image: ${_capturedFrontImage != null ? "Available (${_capturedFrontImage!.length} chars)" : "Stored in native"}');
      print('🖼️ Back Image: ${_capturedBackImage != null ? "Available (${_capturedBackImage!.length} chars)" : "Stored in native"}');

      // Send null for images when they're stored as paths in native
      final params = DocumentLivenessParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: _currentTransactionId!,
        userID: ApiUtils.apiKey,
        frontSidePhoto: _capturedFrontImage,
        backSidePhoto: _capturedBackImage,
        requestTimeout: 30,
      );

      print('📡 About to call OcrFlutter.performDocumentLiveness...');
      final response = await OcrFlutter.performDocumentLiveness(params);
      print('✅ OcrFlutter.performDocumentLiveness completed successfully!');
      print('📊 Failed: ${response.isFailed}');

      setState(() {
        _livenessResponse = response;
        _status = '✅ Document Liveness completed with captured images!';
        _isProcessing = false;
      });

      print('🎯 DOCUMENT LIVENESS PROCESSING COMPLETED with captured images!');
    } catch (e, stackTrace) {
      print('💥 DOCUMENT LIVENESS PROCESSING FAILED: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _status = '❌ Document Liveness failed: ${_getErrorMessage(e)}';
        _lastError = e.toString();
        _hasError = true;
        _isProcessing = false;
      });
    }
  }

  // Helper method to extract user-friendly error messages
  String _getErrorMessage(dynamic error) {
    String errorStr = error.toString();
    
    // Handle OCRException specifically
    if (errorStr.contains('OCRException')) {
      if (errorStr.contains('timed out') || errorStr.contains('timeout')) {
        return 'Request timed out - please try again';
      } else if (errorStr.contains('ERR_UNKNOWN')) {
        return 'Unknown error occurred';
      } else if (errorStr.contains('ERR_NETWORK')) {
        return 'Network connection error';
      } else if (errorStr.contains('ERR_SERVER')) {
        return 'Server error occurred';
      } else if (errorStr.contains('ERR_INVALID_PARAMS')) {
        return 'Invalid parameters provided';
      }
    }
    
    // Handle common Flutter/Dart exceptions
    if (errorStr.contains('SocketException')) {
      return 'Network connection failed';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Operation timed out';
    } else if (errorStr.contains('FormatException')) {
      return 'Invalid data format received';
    }
    
    // Extract the main error message if it's in a known format
    if (errorStr.contains(' - ')) {
      List<String> parts = errorStr.split(' - ');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    
    // Fallback to the original error
    return errorStr.length > 100 ? '${errorStr.substring(0, 100)}...' : errorStr;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

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
                    if (_isProcessing) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // UI Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UI Customization',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => OCRUICustomizeDialog(
                            onApply: (config) async {
                              try {
                                await OcrFlutter.setOCRUIConfig(config);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('UI configuration applied successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to apply UI config: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.palette),
                      label: const Text('Open UI Customization'),
                    ),
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
                      'OCR Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<OCRDocumentType>(
                      value: _selectedDocumentType,
                      decoration: const InputDecoration(
                        labelText: 'Document Type',
                        border: OutlineInputBorder(),
                      ),
                      items: OCRDocumentType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDocumentType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<OCRCountry?>(
                      value: _selectedCountry,
                      decoration: const InputDecoration(
                        labelText: 'Country (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<OCRCountry?>(
                          value: null,
                          child: Text('None'),
                        ),
                        ...OCRCountry.values.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Text(country.value),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCountry = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<OCRDocumentSide>(
                      value: _selectedDocumentSide,
                      decoration: const InputDecoration(
                        labelText: 'Document Side',
                        border: OutlineInputBorder(),
                      ),
                      items: OCRDocumentSide.values.map((side) {
                        return DropdownMenuItem(
                          value: side,
                          child: Text(side.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDocumentSide = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text('Manual Capture'),
                      value: _manualCapture,
                      onChanged: (value) {
                        setState(() {
                          _manualCapture = value ?? false;
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('U18 Transaction (Under 18)'),
                      subtitle: const Text(
                          'Skips face detection when the document has no photo'),
                      value: _u18Enabled,
                      onChanged: (value) {
                        setState(() {
                          _u18Enabled = value ?? false;
                        });
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Raw Photo Crop Ratio: ${_rawPhotoCropRatio.toStringAsFixed(2)}'),
                      subtitle: Slider(
                        value: _rawPhotoCropRatio,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        label: _rawPhotoCropRatio.toStringAsFixed(2),
                        onChanged: (value) {
                          setState(() {
                            _rawPhotoCropRatio = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          Text(
                            "📡 Server: ${ApiUtils.serverUrl}",
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade700),
                          ),
                          Text(
                            "🔑 API Key: ${ApiUtils.apiKey.substring(0, 8)}...",
                            style: TextStyle(
                                fontSize: 12, color: Colors.orange.shade700),
                          ),
                          if (_currentTransactionId != null)
                            Text(
                              "🆔 Transaction ID: ${_currentTransactionId!.substring(0, 20)}...",
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade700),
                            ),
                        ],
                      ),
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

                    // Main Action Buttons - Essential Functions
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _startOCRCamera,
                      child: Text(_isProcessing
                          ? 'Processing...'
                          : '📸 Start OCR Camera'),
                    ),
                    const SizedBox(height: 12),
                    /*ElevatedButton(
                      onPressed:
                          _isProcessing ? null : _startDocumentLivenessCamera,
                      child: const Text('🔍 Test Document Liveness'),
                    ),
                    const SizedBox(height: 12),*/
                    ElevatedButton(
                      onPressed:
                          _isProcessing ? null : _startOCRAndLivenessCamera,
                      child: const Text('🔍 Start OCR + Liveness Camera'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _startHologramCamera,
                      child:
                          const Text('Start Hologram Camera (OCR Required)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: _isProcessing ? null : _testStandaloneIQA,
                      child: const Text('Test Standalone IQA (Take Photo)'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: _isProcessing ? null : _testProvidedPhotoOCR,
                      child: const Text('Test Provided-Photo OCR (Take Front+Back)'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Card - Show OCR Response Status
            Card(
              color: _hasError 
                ? Colors.red.shade50 
                : _ocrResponse != null 
                  ? Colors.green.shade50 
                  : Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _hasError 
                            ? Icons.error 
                            : _ocrResponse != null 
                              ? Icons.check_circle 
                              : Icons.info,
                          color: _hasError 
                            ? Colors.red.shade700 
                            : _ocrResponse != null 
                              ? Colors.green.shade700 
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hasError 
                              ? 'OCR Response: Error ❌' 
                              : _ocrResponse != null 
                                ? 'OCR Response: Available ✅' 
                                : 'OCR Response: Waiting for data...',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _hasError 
                                ? Colors.red.shade700 
                                : _ocrResponse != null 
                                  ? Colors.green.shade700 
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasError && _lastError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Error Details:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getErrorMessage(_lastError!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : () {
                                // Clear error state and retry
                                setState(() {
                                  _hasError = false;
                                  _lastError = null;
                                });
                                if (_capturedFrontImage != null || _capturedBackImage != null) {
                                  _performOCRWithCapturedImages();
                                }
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry OCR'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results Cards - Using OCRResultCard widget
            OCRResultCard(
              ocrResponse: _ocrResponse,
              hologramResponse: _hologramResponse,
              livenessResponse: _livenessResponse,
            ),
          ],
        ),
      ),
    );
  }
}
