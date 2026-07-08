#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint nfc_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'nfc_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A Flutter plugin for NFC passport reading using Udentify SDK.'
  s.description      = <<-DESC
A Flutter plugin for NFC passport reading using Udentify's SDK. 
Provides cross-platform NFC functionality for iOS and Android.
                       DESC
  s.homepage         = 'https://github.com/your-repo/nfc-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '11.0'

  # Only include NFC-specific framework (UdentifyCommons provided by udentify_core_flutter)
  frameworks_path = File.join(__dir__, 'Frameworks')
  udentify_nfc_exists = File.exist?(File.join(frameworks_path, 'UdentifyNFC.xcframework'))
  
  if udentify_nfc_exists
    s.vendored_frameworks = [
      'Frameworks/UdentifyNFC.xcframework'
    ]
  else
    puts "⚠️  NFC Flutter: NFC framework not found - plugin will work in placeholder mode"
  end
  
  # Required for NFC functionality
  s.frameworks = "CoreNFC"
  
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
  
  s.swift_version = '5.0'
end