Pod::Spec.new do |s|
  s.name             = 'video_call_flutter'
  s.version          = '0.1.0'
  s.summary          = 'A comprehensive Flutter plugin for video calling using Udentify\'s SDK.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for video calling using Udentify's SDK. 
Supports real-time video communication, camera/microphone controls, and UI customization.
                       DESC
  s.homepage         = 'https://github.com/your-repo/video-call-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*', 'Frameworks/UdentifyVC/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '12.0'
  
  # Check if frameworks exist and configure accordingly
  frameworks_path = File.join(__dir__, 'Frameworks')
  udentify_vc_exists = File.directory?(File.join(frameworks_path, 'UdentifyVC'))
  
  if udentify_vc_exists
    puts "✅ Video Call Flutter: UdentifyVC source files found (UdentifyCommons provided by udentify_core_flutter)"
  else
    puts "⚠️  Video Call Flutter: UdentifyVC source files not found - plugin will work in placeholder mode"
  end
  
  # LiveKit dependency for video calling (try different versions)
  s.dependency 'LiveKitClient', '~> 2.0'
  
  # Required frameworks for video calling
  s.frameworks = ['AVFoundation', 'VideoToolbox', 'AudioToolbox', 'Network']
  
  # Resources - include all resources
  s.resources = [
    'Resources/**/*.strings',
    'Resources/PrivacyInfo.xcprivacy'
  ]
  
  # Build settings
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'SWIFT_COMPILATION_MODE' => 'wholemodule',
    'PRODUCT_MODULE_NAME' => 'video_call_flutter',
    'ENABLE_BITCODE' => 'NO',
    'SKIP_INSTALL' => 'NO'
  }
  
  s.swift_version = '5.0'
end
