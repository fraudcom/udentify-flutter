import 'package:flutter/material.dart';
import 'pages/nfc_test_page.dart';
import 'pages/ocr_test_page.dart';
import 'pages/mrz_test_page.dart';
import 'pages/video_call_test_page.dart';
import 'pages/new_liveness_test_page.dart';
import 'pages/ssl_pinning_test_page.dart';
import 'pages/remote_language_pack_test_page.dart';
import 'services/global_ocr_callback_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Test App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainTestPage(),
    );
  }
}

class MainTestPage extends StatefulWidget {
  const MainTestPage({super.key});

  @override
  State<MainTestPage> createState() => _MainTestPageState();
}

class _MainTestPageState extends State<MainTestPage>
with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalOCRCallbackManager _ocrCallbackManager = GlobalOCRCallbackManager();

  // Shared MRZ data for NFC integration
  String? _sharedDocumentNumber;
  String? _sharedDateOfBirth;
  String? _sharedDateOfExpiration;

  // Tab page identifiers
  static const String _nfcPageId = 'nfc_page';
  static const String _ocrPageId = 'ocr_page';
  static const String _mrzPageId = 'mrz_page';
  static const String _videoCallPageId = 'video_call_page';
  static const String _livenessPageId = 'liveness_page';
  static const String _sslPinningPageId = 'ssl_pinning_page';
  static const String _remoteLanguagePackPageId = 'remote_language_pack_page';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Listen to tab changes to manage OCR callbacks
    _tabController.addListener(_onTabChanged);
  }

  // Method to update MRZ data from MRZ tab
  void _updateMrzData(
      String? documentNumber, String? dateOfBirth, String? dateOfExpiration) {
    setState(() {
      _sharedDocumentNumber = documentNumber;
      _sharedDateOfBirth = dateOfBirth;
      _sharedDateOfExpiration = dateOfExpiration;
    });
  }

  /// Handle tab changes to switch OCR callback contexts
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    final currentIndex = _tabController.index;
    String? pageId;
    
    switch (currentIndex) {
      case 0:
        pageId = _sslPinningPageId;
        break;
      case 1:
        pageId = _remoteLanguagePackPageId;
        break;
      case 2:
        pageId = _ocrPageId;
        break;
      case 3:
        pageId = _nfcPageId;
        break;
      case 4:
        pageId = _mrzPageId;
        break;
      case 5:
        pageId = _videoCallPageId;
        break;
      case 6:
        pageId = _livenessPageId;
        break;
    }
    
    if (pageId != null) {
      print('MainTestPage - Switching to tab $currentIndex ($pageId)');
      _ocrCallbackManager.switchToPage(pageId);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _ocrCallbackManager.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Test App'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.security),text: 'SSL Pinning'),
            Tab(icon: Icon(Icons.language), text: 'Language Pack'),
            Tab(icon: Icon(Icons.document_scanner), text: 'OCR'),
            Tab(icon: Icon(Icons.nfc), text: 'NFC'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'MRZ'),
            Tab(icon: Icon(Icons.video_call), text: 'Video Call'),
            Tab(icon: Icon(Icons.face), text: 'Liveness')
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const SSLPinningTestPage(),
          const RemoteLanguagePackTestPage(),
          OcrTestPage(pageId: _ocrPageId),
          NfcTestPage(
            pageId: _nfcPageId,
            mrzDocumentNumber: _sharedDocumentNumber,
            mrzDateOfBirth: _sharedDateOfBirth,
            mrzDateOfExpiration: _sharedDateOfExpiration,
          ),
          MrzTestPage(
            pageId: _mrzPageId,
            onMrzDataExtracted: _updateMrzData,
            tabController: _tabController,
          ),
          VideoCallTestPage(pageId: _videoCallPageId),
          NewLivenessTestPageRefactored(pageId: _livenessPageId)
        ],
      ),
    );
  }
}
