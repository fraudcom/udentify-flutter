import 'package:flutter/material.dart';
import 'package:ocr_flutter/ocr_flutter.dart';

/// Global OCR callback manager to handle OCR callbacks across different pages
/// This prevents callback conflicts when navigating between pages that use OCR
class GlobalOCRCallbackManager {
  static final GlobalOCRCallbackManager _instance = GlobalOCRCallbackManager._internal();
  factory GlobalOCRCallbackManager() => _instance;
  GlobalOCRCallbackManager._internal();

  // Current active page identifier
  String? _activePageId;
  
  // Callback storage for different pages
  final Map<String, OCRCallbackSet> _pageCallbacks = {};
  
  // Flag to prevent recursive callback setup
  bool _isSettingUpCallbacks = false;

  /// Register a page with its OCR callbacks
  void registerPage(String pageId, OCRCallbackSet callbacks) {
    print('🔄 GlobalOCRCallbackManager: Registering page $pageId');
    _pageCallbacks[pageId] = callbacks;
    
    // If this is the first page or we're switching to this page, activate it
    if (_activePageId == null || _activePageId != pageId) {
      _activatePage(pageId);
    }
  }

  /// Unregister a page and its callbacks
  void unregisterPage(String pageId) {
    print('🗑️ GlobalOCRCallbackManager: Unregistering page $pageId');
    _pageCallbacks.remove(pageId);
    
    // If the active page is being unregistered, clear active page
    if (_activePageId == pageId) {
      _activePageId = null;
      _clearNativeCallbacks();
    }
  }

  /// Activate a specific page's callbacks
  void _activatePage(String pageId) {
    if (_isSettingUpCallbacks) {
      print('⚠️ GlobalOCRCallbackManager: Already setting up callbacks, skipping');
      return;
    }

    if (!_pageCallbacks.containsKey(pageId)) {
      print('❌ GlobalOCRCallbackManager: Page $pageId not registered');
      return;
    }

    print('✅ GlobalOCRCallbackManager: Activating page $pageId');
    _isSettingUpCallbacks = true;
    _activePageId = pageId;

    try {
      // Clear existing callbacks first
      _clearNativeCallbacks();
      
      // Wait a frame to ensure cleanup is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setupNativeCallbacks();
        _isSettingUpCallbacks = false;
      });
    } catch (e) {
      print('❌ GlobalOCRCallbackManager: Error activating page $pageId: $e');
      _isSettingUpCallbacks = false;
    }
  }

  /// Setup native OCR callbacks with current active page's handlers
  void _setupNativeCallbacks() {
    if (_activePageId == null || !_pageCallbacks.containsKey(_activePageId!)) {
      print('❌ GlobalOCRCallbackManager: No active page to setup callbacks');
      return;
    }

    final callbacks = _pageCallbacks[_activePageId!]!;
    print('🔧 GlobalOCRCallbackManager: Setting up native callbacks for $_activePageId');

    // Setup OCR success callback
    if (callbacks.onOCRSuccess != null) {
      OcrFlutter.setOnOCRSuccessCallback((OCRResponse response) {
        print('📞 GlobalOCRCallbackManager: OCR Success callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onOCRSuccess?.call(response);
        }
      });
    }

    // Setup OCR failure callback
    if (callbacks.onOCRFailure != null) {
      OcrFlutter.setOnOCRFailureCallback((String error) {
        print('📞 GlobalOCRCallbackManager: OCR Failure callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onOCRFailure?.call(error);
        }
      });
    }

    // Setup document scan callback
    if (callbacks.onDocumentScan != null) {
      OcrFlutter.setOnDocumentScanCallback((String documentSide, String? frontPhoto, String? backPhoto) {
        print('📞 GlobalOCRCallbackManager: Document Scan callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onDocumentScan?.call(documentSide, frontPhoto, backPhoto);
        }
      });
    }

    // Setup back button callback
    if (callbacks.onBackButtonPressed != null) {
      OcrFlutter.setOnBackButtonPressedCallback(() {
        print('📞 GlobalOCRCallbackManager: Back Button callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onBackButtonPressed?.call();
        }
      });
    }

    // Setup OCR and document liveness callback
    if (callbacks.onOCRAndDocumentLivenessResult != null) {
      OcrFlutter.setOnOCRAndDocumentLivenessResultCallback((OCRAndDocumentLivenessResponse response) {
        print('📞 GlobalOCRCallbackManager: OCR+Liveness callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onOCRAndDocumentLivenessResult?.call(response);
        }
      });
    }

    // Setup hologram callbacks
    if (callbacks.onHologramVideoRecorded != null) {
      OcrFlutter.setOnHologramVideoRecordedCallback((List<String> videoUrls) {
        print('📞 GlobalOCRCallbackManager: Hologram Video callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onHologramVideoRecorded?.call(videoUrls);
        }
      });
    }

    if (callbacks.onHologramFailure != null) {
      OcrFlutter.setOnHologramFailureCallback((String error) {
        print('📞 GlobalOCRCallbackManager: Hologram Failure callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onHologramFailure?.call(error);
        }
      });
    }

    if (callbacks.onHologramBackButtonPressed != null) {
      OcrFlutter.setOnHologramBackButtonPressedCallback(() {
        print('📞 GlobalOCRCallbackManager: Hologram Back Button callback for $_activePageId');
        if (_activePageId != null && _pageCallbacks.containsKey(_activePageId!)) {
          _pageCallbacks[_activePageId!]!.onHologramBackButtonPressed?.call();
        }
      });
    }

    print('✅ GlobalOCRCallbackManager: Native callbacks setup completed for $_activePageId');
  }

  /// Clear all native OCR callbacks
  void _clearNativeCallbacks() {
    print('🧹 GlobalOCRCallbackManager: Clearing native callbacks');
    OcrFlutter.clearOCRCallbacks();
  }

  /// Switch to a different page's callbacks
  void switchToPage(String pageId) {
    if (_activePageId == pageId) {
      print('ℹ️ GlobalOCRCallbackManager: Page $pageId is already active');
      return;
    }

    print('🔄 GlobalOCRCallbackManager: Switching from $_activePageId to $pageId');
    _activatePage(pageId);
  }

  /// Get current active page ID
  String? get activePageId => _activePageId;

  /// Check if a page is currently active
  bool isPageActive(String pageId) => _activePageId == pageId;

  /// Clear all callbacks and reset manager
  void reset() {
    print('🔄 GlobalOCRCallbackManager: Resetting all callbacks');
    _clearNativeCallbacks();
    _pageCallbacks.clear();
    _activePageId = null;
    _isSettingUpCallbacks = false;
  }
}

/// Data class to hold all OCR callbacks for a page
class OCRCallbackSet {
  final Function(OCRResponse)? onOCRSuccess;
  final Function(String)? onOCRFailure;
  final Function(String, String?, String?)? onDocumentScan;
  final Function()? onBackButtonPressed;
  final Function(OCRAndDocumentLivenessResponse)? onOCRAndDocumentLivenessResult;
  final Function(List<String>)? onHologramVideoRecorded;
  final Function(String)? onHologramFailure;
  final Function()? onHologramBackButtonPressed;

  const OCRCallbackSet({
    this.onOCRSuccess,
    this.onOCRFailure,
    this.onDocumentScan,
    this.onBackButtonPressed,
    this.onOCRAndDocumentLivenessResult,
    this.onHologramVideoRecorded,
    this.onHologramFailure,
    this.onHologramBackButtonPressed,
  });
}
