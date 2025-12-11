#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint mrz_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'mrz_flutter'
  s.version          = '1.1.0'
  s.summary          = 'A Flutter plugin for reading MRZ (Machine Readable Zone) from documents using Udentify SDK.'
  s.description      = <<-DESC
A Flutter plugin for reading MRZ (Machine Readable Zone) from documents using Udentify SDK.
                       DESC
  s.homepage         = 'https://fraud.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Fraud.com' => 'support@fraud.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'udentify_core_flutter'  # Shared core framework dependency
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ENABLE_BITCODE' => 'NO',
    'SKIP_INSTALL' => 'NO'
  }
  
  # Resources - include all resources
  s.resources = [
    'Resources/**/*.strings'
  ]
  
  s.swift_version = '5.0'
  
  # Only include MRZ-specific frameworks (UdentifyCommons provided by udentify_core_flutter)
  frameworks_path = File.join(__dir__, 'Frameworks')
  udentify_mrz_exists = File.exist?(File.join(frameworks_path, 'UdentifyMRZ.xcframework'))
  tesseract_exists = File.exist?(File.join(frameworks_path, 'TesseractOCRSDKiOS.xcframework'))
  gpuimage_exists = File.exist?(File.join(frameworks_path, 'GPUImage.xcframework'))
  
  if udentify_mrz_exists && tesseract_exists && gpuimage_exists
    # All frameworks are present - enable full SDK functionality
    s.vendored_frameworks = [
      'Frameworks/UdentifyMRZ.xcframework',
      'Frameworks/TesseractOCRSDKiOS.xcframework',
      'Frameworks/GPUImage.xcframework'
    ]
    
    puts "✅ MRZ Flutter: Udentify MRZ frameworks detected - enabling full SDK functionality"
  else
    # Frameworks missing - plugin will work in placeholder mode
    missing_frameworks = []
    missing_frameworks << 'UdentifyMRZ.xcframework' unless udentify_mrz_exists
    missing_frameworks << 'TesseractOCRSDKiOS.xcframework' unless tesseract_exists
    missing_frameworks << 'GPUImage.xcframework' unless gpuimage_exists
    
    puts "⚠️  MRZ Flutter: Missing frameworks: #{missing_frameworks.join(', ')}"
    puts "ℹ️  MRZ Flutter: Plugin will work in placeholder mode - add frameworks to ios/Frameworks/ for full functionality"
  end
end
