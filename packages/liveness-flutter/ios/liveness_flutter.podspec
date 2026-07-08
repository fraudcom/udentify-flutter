Pod::Spec.new do |s|
  s.name             = 'liveness_flutter'
  s.version          = '1.0.0'
  s.summary          = 'A Flutter plugin for Udentify Face Recognition & Liveness detection.'
  s.description      = <<-DESC
A Flutter plugin for Udentify Face Recognition & Liveness detection.
                       DESC
  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '11.0'

  # Only include Liveness-specific frameworks (UdentifyCommons provided by udentify_core_flutter)
  frameworks_path = File.join(__dir__, 'Frameworks')
  udentify_face_exists = File.exist?(File.join(frameworks_path, 'UdentifyFACE.xcframework'))
  lottie_exists = File.exist?(File.join(frameworks_path, 'Lottie.xcframework'))
  
  if udentify_face_exists && lottie_exists
    s.vendored_frameworks = [
      'Frameworks/UdentifyFACE.xcframework',
      'Frameworks/Lottie.xcframework'
    ]
    puts "✅ Liveness Flutter: Including UdentifyFACE and Lottie frameworks"
  else
    puts "⚠️  Liveness Flutter: Liveness frameworks not found - plugin will work in placeholder mode"
  end
  
  # Required frameworks 
  s.frameworks = ['AVFoundation'] if udentify_face_exists
  
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
