import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liveness_flutter/liveness_flutter.dart' hide TextStyle;
import 'package:ocr_flutter/ocr_flutter.dart';

// Services
import '../services/liveness_configuration_manager.dart';
import '../services/selfie_manager.dart';
import '../services/user_registration_manager.dart';
import '../services/liveness_callback_manager.dart';
import '../services/global_ocr_callback_manager.dart';

// Utils (for direct OCR calls)
import '../utils/api_utils.dart';
import '../models/app_constants.dart';

// Models
import '../models/liveness_state.dart';

// Widgets
import '../widgets/liveness/status_summary_widget.dart';
import '../widgets/liveness/permission_widget.dart';
import '../widgets/liveness/ocr_prerequisite_widget.dart';
import '../widgets/liveness/user_registration_widget.dart';
import '../widgets/liveness/configuration_widget.dart';
import '../widgets/liveness/testing_widget.dart';
import '../widgets/liveness/selfie_testing_widget.dart';
import '../widgets/liveness/result_display_widget.dart';
import '../widgets/liveness_ui_customize_dialog.dart';

/// Refactored liveness test page with clean separation of concerns
class NewLivenessTestPageRefactored extends StatefulWidget {
  final String pageId;
  
  const NewLivenessTestPageRefactored({super.key, required this.pageId});

  @override
  State<NewLivenessTestPageRefactored> createState() => _NewLivenessTestPageRefactoredState();
}

class _NewLivenessTestPageRefactoredState extends State<NewLivenessTestPageRefactored> {
  // Controllers
  final _userIDController = TextEditingController(
      text: DateTime.now().millisecondsSinceEpoch.toString());

  // Service instances
  late final LivenessConfigurationManager _configManager;
  late final SelfieManager _selfieManager;
  late final UserRegistrationManager _userRegistrationManager;
  late final LivenessCallbackManager _callbackManager;
  
  // Global OCR callback manager
  final GlobalOCRCallbackManager _ocrCallbackManager = GlobalOCRCallbackManager();
  
  // Direct OCR state (like ocr_test_page.dart)
  OCRResponse? _ocrResponse;
  String? _currentTransactionId;
  String? _capturedFrontImage;
  String? _capturedBackImage;
  bool _ocrCompleted = false;
  OCRDocumentType _selectedDocumentType = OCRDocumentType.idCard;
  OCRCountry? _selectedCountry = OCRCountry.turkey;
  OCRDocumentSide _selectedDocumentSide = OCRDocumentSide.bothSides;
  bool _manualCapture = false;

  // State
  late LivenessState _state;
  
  // Flag to track selfie processing operations
  bool _isProcessingSelfie = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeState();
    _setupInitialConfiguration();
  }

  @override
  void dispose() {
    _userIDController.dispose();
    _ocrCallbackManager.unregisterPage(widget.pageId); // Unregister from global callback manager
    _callbackManager.clearAllCallbacks();
    super.dispose();
  }

  /// Initialize all service instances
  void _initializeServices() {
    _configManager = LivenessConfigurationManager();
    _selfieManager = SelfieManager();
    _userRegistrationManager = UserRegistrationManager();
    _callbackManager = LivenessCallbackManager();
  }

  /// Initialize the state
  void _initializeState() {
    _state = LivenessState();
  }

  /// Setup initial configuration and callbacks
  void _setupInitialConfiguration() {
    _setupCallbacks();
    _setupOCRCallbacks();
    _checkPermissions();
    _configureTransparentBackground();
  }

  /// Setup liveness callbacks
  void _setupCallbacks() {
    _callbackManager.setupCallbacks(
      onResult: _handleLivenessResult,
      onFailure: _handleLivenessFailure,
      onPhotoTaken: _handlePhotoTaken,
      onSelfieTaken: _handleSelfieTaken,
      onActiveLivenessResult: _handleActiveLivenessResult,
      onActiveLivenessFailure: _handleActiveLivenessFailure,
    );
  }

  /// Setup OCR callbacks (using global callback manager)
  void _setupOCRCallbacks() {
    print('🔧 Liveness Test Page: Setting up callbacks for page ${widget.pageId}');
    
    // Register this page's callbacks with the global manager
    final callbacks = OCRCallbackSet(
      onOCRSuccess: (OCRResponse response) {
        if (!mounted) return;
        print('🎉 Liveness Test Page: OCR SUCCESS CALLBACK for ${widget.pageId}');
        print('📊 Response Type: ${response.responseType}');

        setState(() {
          _ocrResponse = response;
          _ocrCompleted = true;
          _state = _state.copyWith(isLoading: false);
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ OCR completed successfully! Liveness operations are now available.'),
            backgroundColor: Colors.green,
          ),
        );
      },
      
      onOCRFailure: (String error) {
        if (!mounted) return;
        print('💥 Liveness Test Page: OCR FAILURE CALLBACK for ${widget.pageId}: $error');
        
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $error')),
        );
      },
      
      onDocumentScan: (String documentSide, String? frontPhoto, String? backPhoto) {
        if (!mounted) return;
        print('📸 Liveness Test Page: DOCUMENT SCAN CALLBACK for ${widget.pageId}');
        print('   Document Side: $documentSide');
        print('   Front Image: ${frontPhoto != null ? "✅ Captured (${frontPhoto.length} chars)" : "❌ Not captured"}');
        print('   Back Image: ${backPhoto != null ? "✅ Captured (${backPhoto.length} chars)" : "❌ Not captured"}');

        setState(() {
          _capturedFrontImage = frontPhoto;
          _capturedBackImage = backPhoto;
          // Keep loading state true - OCR processing is about to start
          // Don't change isLoading here, let it continue until OCR success/failure
        });

        // Auto-trigger OCR processing with captured images
        if (frontPhoto != null || backPhoto != null) {
          print('🚀 Auto-triggering OCR processing...');
          _performOCRWithCapturedImages();
        }
      },
      
      onBackButtonPressed: () {
        if (!mounted) return;
        print('🔙 Liveness Test Page: BACK BUTTON PRESSED CALLBACK for ${widget.pageId}');
        
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
      },
    );
    
    // Register callbacks with global manager
    _ocrCallbackManager.registerPage(widget.pageId, callbacks);
  }

  // ================ CALLBACK HANDLERS ================

  void _handleLivenessResult(FaceRecognitionResult result) {
    // Handle registration tracking
    _trackUserRegistration(result);
    
    setState(() {
      if (_isProcessingSelfie) {
        // Route selfie processing results to selfieResult
        _state = _state.copyWith(
          selfieResult: result,
          isLoading: false,
          isSelfieCapturing: false,
        );
        _isProcessingSelfie = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Selfie processing completed successfully!\n\nOperation: ${_selfieManager.selfieOperation}\nCheck the selfie result section for detailed information.'
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _state = _state.copyWith(
          faceRecognitionResult: result,
          isLoading: false,
          isSelfieCapturing: false,
        );
      }
    });
  }

  void _handleLivenessFailure(FaceRecognitionError error) {
    setState(() {
      if (_isProcessingSelfie) {
        _state = _state.copyWith(
          isLoading: false,
          isSelfieCapturing: false,
        );
        _isProcessingSelfie = false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selfie processing failed: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        _state = _state.copyWith(
          faceRecognitionResult: FaceRecognitionResult.error(error),
          isLoading: false,
          isSelfieCapturing: false,
        );
      }
    });
  }

  void _handlePhotoTaken() {
    // Photo taken during liveness process
    print('📸 Photo taken during liveness process');
  }

  void _handleSelfieTaken(String base64Image) {
    print('Selfie taken - image length: ${base64Image.length}');
    
    _selfieManager.handleSelfieTaken(base64Image);
    setState(() {
      _state = _state.copyWith(
        displaySelfie: base64Image,
        isSelfieCapturing: false, // ✅ FIX: Reset selfie capturing state when selfie is captured
        isLoading: false, // Stop progress bar
      );
    });
    
    // Don't cancel face recognition - let it complete and send response
    
    if (base64Image.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selfie captured! Waiting for response...'
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _handleActiveLivenessResult(FaceRecognitionResult result) {
    // Handle registration tracking
    _trackUserRegistrationForLiveness(result);
    
    setState(() {
      _state = _state.copyWith(
        livenessResult: result,
        isLoading: false,
      );
    });
  }

  void _handleActiveLivenessFailure(FaceRecognitionError error) {
    setState(() {
      _state = _state.copyWith(isLoading: false);
    });
  }


  // ================ BUSINESS LOGIC METHODS ================

  void _trackUserRegistration(FaceRecognitionResult result) {
    if (result.faceIDMessage?.success == true && result.faceIDMessage?.faceIDResult != null) {
      final faceIDResult = result.faceIDMessage!.faceIDResult!;
      
      if (faceIDResult.verified && faceIDResult.userID != null && faceIDResult.transactionID != null) {
        final isRegistration = !_userRegistrationManager.checkUserRegistrationStatus(faceIDResult.userID!) ||
                              faceIDResult.method?.toLowerCase().contains('registration') == true;
        
        if (isRegistration) {
          _userRegistrationManager.markUserAsRegistered(faceIDResult.userID!, faceIDResult.transactionID!, 'face_recognition');
          print('🎉 REGISTRATION SUCCESS: User ${faceIDResult.userID} has been registered!');
        }
      }
    } else if (result.faceIDMessage?.success == true) {
      // Android fallback
      if (result.faceIDMessage?.message?.toLowerCase().contains('registration') == true || 
          result.faceIDMessage?.message?.toLowerCase().contains('completed successfully') == true) {
        
        final userIDToRegister = result.faceIDMessage?.faceIDResult?.userID ?? _userIDController.text;
        final transactionIDToUse = result.faceIDMessage?.faceIDResult?.transactionID ?? _configManager.currentTransactionID;
        
        print('🔧 ANDROID FALLBACK: Registering user $userIDToRegister');
        _userRegistrationManager.markUserAsRegistered(userIDToRegister, transactionIDToUse, 'face_recognition');
      }
    }
  }

  void _trackUserRegistrationForLiveness(FaceRecognitionResult result) {
    if (result.faceIDMessage?.success == true && result.faceIDMessage?.faceIDResult != null) {
      final faceIDResult = result.faceIDMessage!.faceIDResult!;
      
      if (faceIDResult.verified && faceIDResult.userID != null && faceIDResult.transactionID != null) {
        final isRegistration = _state.selectedOperation == 'registration' ||
                             faceIDResult.method?.toLowerCase().contains('registration') == true ||
                             !_userRegistrationManager.checkUserRegistrationStatus(faceIDResult.userID!);
        
        if (isRegistration) {
          final method = result.faceIDMessage?.message?.toLowerCase().contains('hybrid') == true ? 'hybrid_liveness' : 'active_liveness';
          _userRegistrationManager.markUserAsRegistered(faceIDResult.userID!, faceIDResult.transactionID!, method);
          print('🎉 LIVENESS REGISTRATION SUCCESS ($method): User ${faceIDResult.userID} has been registered!');
        }
      }
    }
  }

  // ================ ACTION METHODS ================

  Future<void> _configureTransparentBackground() async {
    try {
      await _configManager.configureTransparentBackground();
      setState(() {
        _state = _state.copyWith(currentUIConfig: _configManager.currentUIConfig);
      });
    } catch (e) {
      print('❌ Failed to configure UI: $e');
    }
  }

  Future<void> _checkPermissions() async {
    final status = await _configManager.checkPermissions();
    setState(() {
      _state = _state.copyWith(permissionStatus: status);
    });
  }

  Future<void> _requestPermissions() async {
    final status = await _configManager.requestPermissions();
    setState(() {
      _state = _state.copyWith(permissionStatus: status);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Permission request completed. Check the status above.')),
    );
  }

  /// Start OCR camera (directly like ocr_test_page.dart)
  Future<void> _performOCRFirst() async {
    if (_state.isLoading) return;

    setState(() {
      _state = _state.copyWith(isLoading: true);
      _ocrResponse = null;
      _ocrCompleted = false; // Reset OCR completion status
    });

    try {
      // Get transaction ID from API
      final transactionId = await ApiUtils.getTransactionId([
        AppConstants.moduleOCR,
        AppConstants.moduleOCRHologram,
        AppConstants.moduleFaceRegistration,
        AppConstants.moduleFaceAuthentication,
        AppConstants.moduleFaceLiveness,
        AppConstants.moduleActiveLiveness,
      ]);
      
      if (transactionId == null) {
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get transaction ID')),
        );
        return;
      }

      setState(() {
        _currentTransactionId = transactionId;
      });

      final params = OCRCameraParams(
        serverURL: ApiUtils.serverUrl,
        transactionID: transactionId,
        userID: ApiUtils.apiKey,
        documentType: _selectedDocumentType,
        country: _selectedCountry,
        documentSide: _selectedDocumentSide,
        manualCapture: _manualCapture,
      );

      final success = await OcrFlutter.startOCRCamera(params);

      if (!success) {
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start OCR camera')),
        );
      }
      // Keep loading state true until OCR success/failure callback
      // Don't set isLoading to false here for successful camera start
    } catch (e) {
      setState(() {
        _state = _state.copyWith(isLoading: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR camera failed: $e')),
      );
    }
  }

  /// Process OCR with captured images (directly like ocr_test_page.dart)
  Future<void> _performOCRWithCapturedImages() async {
    if (_capturedFrontImage == null && _capturedBackImage == null) return;

    // Don't check _state.isLoading here because this method is called from document scan callback
    // when loading is already true. Just ensure we have the loading state set.
    setState(() {
      _state = _state.copyWith(isLoading: true);
      _ocrResponse = null;
      _ocrCompleted = false; // Reset OCR completion status while processing
    });

    try {
      // Use the existing transaction ID from camera session
      if (_currentTransactionId == null) {
        setState(() {
          _state = _state.copyWith(isLoading: false);
        });
        return;
      }

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

      final response = await OcrFlutter.performOCR(params);

      setState(() {
        _ocrResponse = response;
        _ocrCompleted = true;
        _state = _state.copyWith(isLoading: false);
      });

      print('🎯 OCR PROCESSING COMPLETED with captured images!');
      print('📊 Response Type: ${response.responseType}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ OCR completed with captured images!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _state = _state.copyWith(isLoading: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR with captured images failed: $e')),
      );
    }
  }

  // ================ TESTING METHODS ================

  Future<void> _testFaceRecognitionRegistration() async {
    if (!_checkOCRDependency()) return;
    
    await _performFaceRecognitionTest(
      () => LivenessFlutter.startFaceRecognitionRegistration,
      'face recognition registration'
    );
  }

  Future<void> _testFaceRecognitionAuthentication() async {
    if (!_checkOCRDependency()) return;
    if (!_checkUserRegistration()) return;
    
    await _performFaceRecognitionTest(
      () => LivenessFlutter.startFaceRecognitionAuthentication,
      'face recognition authentication'
    );
  }

  Future<void> _testActiveLiveness() async {
    if (!_checkOCRDependency()) return;
    if (!_checkRegistrationForOperation()) return;
    
    await _performFaceRecognitionTest(
      () => (credentials) => LivenessFlutter.startActiveLiveness(
        credentials, 
        isAuthentication: _state.selectedOperation == 'authentication'
      ),
      'active liveness'
    );
  }

  Future<void> _testHybridLiveness() async {
    if (!_checkOCRDependency()) return;
    if (!_checkRegistrationForOperation()) return;
    
    await _performFaceRecognitionTest(
      () => (credentials) => LivenessFlutter.startHybridLiveness(
        credentials, 
        isAuthentication: _state.selectedOperation == 'authentication'
      ),
      'hybrid liveness'
    );
  }

  Future<void> _performFaceRecognitionTest(
    Function() getTestFunction,
    String testName,
  ) async {
    try {
      setState(() {
        _state = _state.copyWith(isLoading: true);
      });
      
      if (!_state.allPermissionsGranted) {
        await _requestPermissions();
        if (!_state.allPermissionsGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Required permissions are not granted')),
          );
          return;
        }
      }
      
      print('🔄 Starting $testName...');
      
      final credentials = await _configManager.buildCredentials(
        _userIDController.text,
        existingTransactionID: _currentTransactionId,
      );
      
      if (credentials == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get transaction ID')),
        );
        return;
      }
      
      final testFunction = getTestFunction();
      final result = await testFunction(credentials);
      print('✅ $testName Result: $result');
      
    } catch (error) {
      print('❌ $testName Error: $error');
    } finally {
      setState(() {
        _state = _state.copyWith(isLoading: false);
      });
    }
  }

  // ================ SELFIE METHODS ================

  Future<void> _testSelfieCapture() async {
    if (!_checkOCRDependency()) return;
    if (!_checkRegistrationForSelfieOperation()) return;

    try {
      setState(() {
        _state = _state.copyWith(isSelfieCapturing: true);
      });
      
      if (!_state.allPermissionsGranted) {
        await _requestPermissions();
        setState(() {
          _state = _state.copyWith(isSelfieCapturing: false);
        });
        return;
      }

      final credentials = await _configManager.buildCredentials(
        _userIDController.text,
        existingTransactionID: _currentTransactionId,
      );
      
      if (credentials == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get transaction ID')),
        );
        setState(() {
          _state = _state.copyWith(isSelfieCapturing: false);
        });
        return;
      }
      
      await _selfieManager.startSelfieCapture(credentials);
      
    } catch (error) {
      setState(() {
        _state = _state.copyWith(isSelfieCapturing: false);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start selfie capture: $error')),
      );
    }
  }

  Future<void> _handleProcessCapturedSelfie() async {
    if (!_selfieManager.isSelfieReadyForProcessing()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No selfie image available. Please capture a selfie first.')),
      );
      return;
    }

    setState(() {
      _state = _state.copyWith(isLoading: true);
      _isProcessingSelfie = true;
    });

    try {
      final credentials = await _configManager.buildCredentials(
        _userIDController.text,
        existingTransactionID: _currentTransactionId,
      );
      
      if (credentials == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get transaction ID')),
        );
        setState(() {
          _state = _state.copyWith(isLoading: false);
          _isProcessingSelfie = false;
        });
        return;
      }

      await _selfieManager.processCapturedSelfie(credentials);

    } catch (error) {
      setState(() {
        _state = _state.copyWith(isLoading: false);
        _isProcessingSelfie = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process selfie: $error')),
      );
    }
  }

  void _clearCapturedSelfie() {
    _selfieManager.clearCapturedSelfie();
    setState(() {
      _state = _state.copyWith(displaySelfie: null);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Captured selfie image has been cleared. You can capture a new one.')),
    );
  }

  Future<void> _cancelFaceRecognition() async {
    try {
      await _configManager.cancelFaceRecognition();
      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          isSelfieCapturing: false,
        );
      });
    } catch (e) {
      print('Error canceling face recognition: $e');
    }
  }

  // ================ HELPER METHODS ================

  bool _checkOCRDependency() {
    if (!_ocrCompleted) {
      _showOCRRequiredDialog();
      return false;
    }
    return true;
  }

  bool _checkUserRegistration() {
    return _userRegistrationManager.checkUserRegistrationStatus(_userIDController.text);
  }

  bool _checkRegistrationForOperation() {
    if (_state.selectedOperation == 'authentication') {
      return _checkUserRegistration();
    }
    return true;
  }

  bool _checkRegistrationForSelfieOperation() {
    if (_selfieManager.selfieOperation == 'authentication') {
      return _checkUserRegistration();
    }
    return true;
  }

  void _showOCRRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OCR Required'),
        content: const Text(
          'Please complete OCR scanning first. OCR is required before liveness operations can proceed.\n\n'
          'This ensures proper transaction handling and integration with the Udentify system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performOCRFirst();
            },
            child: const Text('Start OCR'),
          ),
        ],
      ),
    );
  }

  void _showUICustomizeDialog() {
    // For Android, show XML instructions directly instead of customization modal
    if (Platform.isAndroid) {
      _showAndroidXMLInstructions();
      return;
    }
    
    // For iOS, show the full customization dialog
    showDialog(
      context: context,
      builder: (context) => LivenessUICustomizeDialog(
        currentConfig: _state.currentUIConfig,
        onApply: (uiSettings) {
          setState(() {
            _state = _state.copyWith(currentUIConfig: uiSettings);
          });
          
          // Apply the UI settings to the liveness library
          _configManager.applyUISettings(uiSettings);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ UI settings applied successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showAndroidXMLInstructions() {
    const xmlInstructions = '''
To customize UI on Android, manually update these XML files:

📁 android/app/src/main/res/values/colors.xml:

<!-- UdentifyFACE Button Background Colors -->
<color name="udentifyface_btn_color">#844EE3</color>
<color name="udentifyface_btn_color_success">#4CD964</color>
<color name="udentifyface_btn_color_error">#FFFF00</color>

⚡ After updating XML files:
Run "flutter clean && flutter build android" to rebuild the app
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🤖 Android XML Configuration'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '📋 Copy the XML configuration below and paste it into your Android project files.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF856404),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    xmlInstructions,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Color(0xFF495057),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: xmlInstructions));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📋 XML instructions copied to clipboard!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy XML'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ================ UI BUILD METHODS ================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Status Summary Section
            LivenessStatusSummaryWidget(
              state: _state,
              ocrCompleted: _ocrCompleted,
              userRegistered: _userRegistrationManager.checkUserRegistrationStatus(_userIDController.text),
              capturedSelfieImage: _selfieManager.capturedSelfieImage,
              isOCRInProgress: _state.isLoading && !_ocrCompleted, // Show OCR loading when loading and OCR not completed
              isLivenessInProgress: _state.isLoading && _ocrCompleted, // Show liveness loading when loading and OCR completed
            ),
            const SizedBox(height: 16),

            // Permission Status Section
            LivenessPermissionWidget(
              permissionStatus: _state.permissionStatus,
              onCheckPermissions: _checkPermissions,
              onRequestPermissions: _requestPermissions,
            ),
            const SizedBox(height: 16),

            // OCR Prerequisite Section
            OCRPrerequisiteWidget(
              ocrCompleted: _ocrCompleted,
              ocrStatus: _ocrCompleted ? '✅ OCR completed successfully!' : 'Ready to scan document',
              isLoading: _state.isLoading,
              onPerformOCR: _performOCRFirst,
            ),
            const SizedBox(height: 16),

            // User Registration Status Section
            UserRegistrationWidget(
              userRegistrationStatus: _userRegistrationManager.userRegistrationStatus,
              currentUserID: _userIDController.text,
              currentUserRegistered: _userRegistrationManager.checkUserRegistrationStatus(_userIDController.text),
              onClearAllRegistrationData: () {
                _userRegistrationManager.clearAllRegistrationData();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All registration data cleared')),
                );
              },
            ),
            const SizedBox(height: 16),

            // Configuration Section
            LivenessConfigurationWidget(
              userIDController: _userIDController,
              selectedOperation: _state.selectedOperation,
              onOperationChanged: (operation) {
                setState(() {
                  _state = _state.copyWith(selectedOperation: operation);
                });
              },
              onShowUICustomizeDialog: _showUICustomizeDialog,
            ),
            const SizedBox(height: 16),

            // Testing Section
            LivenessTestingWidget(
              isLoading: _state.isLoading,
              ocrCompleted: _ocrCompleted,
              userRegistered: _userRegistrationManager.checkUserRegistrationStatus(_userIDController.text),
              selectedOperation: _state.selectedOperation,
              onTestFaceRegistration: _testFaceRecognitionRegistration,
              onTestFaceAuthentication: _testFaceRecognitionAuthentication,
              onTestActiveLiveness: _testActiveLiveness,
              onTestHybridLiveness: _testHybridLiveness,
              onCancelRecognition: _cancelFaceRecognition,
            ),
            const SizedBox(height: 16),

            // Selfie Testing Section
            SelfieTestingWidget(
              isLoading: _state.isLoading,
              isSelfieCapturing: _state.isSelfieCapturing,
              ocrCompleted: _ocrCompleted,
              userRegistered: _userRegistrationManager.checkUserRegistrationStatus(_userIDController.text),
              selfieOperation: _selfieManager.selfieOperation,
              selectedUserID: _userIDController.text,
              capturedSelfieImage: _selfieManager.capturedSelfieImage,
              onSelfieOperationChanged: (operation) {
                _selfieManager.selfieOperation = operation;
                setState(() {
                  _state = _state.copyWith(selfieOperation: operation);
                });
              },
              onCaptureSelfie: _testSelfieCapture,
              onProcessSelfie: _handleProcessCapturedSelfie,
              onClearSelfie: _clearCapturedSelfie,
            ),
            const SizedBox(height: 16),

            // Results Display Section
            LivenessResultDisplayWidget(
              currentTransactionID: _currentTransactionId,
              ocrResult: _ocrResponse,
              faceRecognitionResult: _state.faceRecognitionResult,
              livenessResult: _state.livenessResult,
              selfieResult: _state.selfieResult,
              displaySelfie: _state.displaySelfie,
              userID: _userIDController.text,
              selfieOperation: _selfieManager.selfieOperation,
            ),
          ],
        ),
      ),
    );
  }
}
