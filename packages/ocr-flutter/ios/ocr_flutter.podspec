Pod::Spec.new do |s|
  s.name             = 'ocr_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A comprehensive Flutter plugin for OCR ID verification using Udentify\'s SDK.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for OCR ID verification using Udentify's SDK. 
Supports document scanning, hologram verification, and document liveness detection.
                       DESC
  s.homepage         = 'https://github.com/your-repo/ocr-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '11.0'
  
  # Only include OCR-specific framework (UdentifyCommons provided by udentify_core_flutter)
  frameworks_path = File.join(__dir__, 'Frameworks')
  udentify_ocr_exists = File.exist?(File.join(frameworks_path, 'UdentifyOCR.xcframework'))
  
  if udentify_ocr_exists
    s.vendored_frameworks = [
      'Frameworks/UdentifyOCR.xcframework'
    ]
  else
    puts "⚠️  OCR Flutter: OCR framework not found - plugin will work in placeholder mode"
  end
  
  # Required for OCR functionality
  s.frameworks = ['AVFoundation', 'Photos', 'PhotosUI']
  
  # Resources - include all resources
  s.resources = [
    'Resources/**/*.strings',
    'Resources/PrivacyInfo.xcprivacy'
  ]
  
  # Build settings
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_BITCODE' => 'NO',
    'SKIP_INSTALL' => 'NO'
  }
  
  # NOTE: Only define UDENTIFY_OCR_AVAILABLE when the frameworks above are added.
  # You can do this by uncommenting the following lines and setting the macro:
  # s.user_target_xcconfig = {
  #   'GCC_PREPROCESSOR_DEFINITIONS' => 'UDENTIFY_OCR_AVAILABLE=1'
  # }
  s.swift_version = '6.0'
end