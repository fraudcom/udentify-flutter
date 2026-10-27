Pod::Spec.new do |s|
  s.name             = 'video_call_flutter'
  s.version          = '26.3.0928'
  s.summary          = 'A comprehensive Flutter plugin for video calling using Udentify\'s SDK.'
  s.description      = <<-DESC
A comprehensive Flutter plugin for video calling using Udentify's SDK. 
Supports real-time video communication, camera/microphone controls, and UI customization.
                       DESC
  s.homepage         = 'https://github.com/your-repo/video-call-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  
  s.source           = { :path => '.' }
  # As of 26.3.0928 UdentifyVC ships as a compiled xcframework, not loose Swift sources.
  # Keep source_files scoped to Classes/ so nothing under Frameworks/ is compiled.
  s.source_files     = 'Classes/**/*'
  # UdentifyLiveKYC is required for the agent-driven LiveKYC steps (OCR / face / NFC repeats); a
  # call started without liveKYCOptions is unaffected by its presence.
  s.vendored_frameworks = [
    'Frameworks/UdentifyVC.xcframework',
    'Frameworks/UdentifyLiveKYC.xcframework'
  ]
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '13.0'
  
  # LiveKitWebRTC ONLY. The LiveKit Swift SDK is compiled into UdentifyVC.xcframework, so
  # depending on LiveKitClient as well causes duplicate-symbol errors. The version is pinned
  # to the WebRTC build UdentifyVC 26.3.0928 was made against; re-pin it on every UdentifyVC
  # upgrade. Resolved from the LiveKit spec repo, which the app's Podfile must declare:
  #   source 'https://github.com/livekit/podspecs.git'
  s.dependency 'LiveKitWebRTC', '144.7559.03'

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
