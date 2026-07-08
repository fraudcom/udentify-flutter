#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint udentify_core_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'udentify_core_flutter'
  s.version          = '1.0.0'
  s.summary          = 'Core shared components for Udentify Flutter libraries including SSL pinning.'
  s.description      = <<-DESC
Core shared components for Udentify Flutter libraries, providing SSL certificate pinning 
functionality and the shared UdentifyCommons framework required by all Udentify libraries.
                       DESC
  s.homepage         = 'https://github.com/your-repo/udentify-core-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Udentify' => 'support@udentify.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '11.0'

  # Core shared framework
  s.vendored_frameworks = [
    'Frameworks/UdentifyCommons.xcframework'
  ]
  
  # Framework search paths
  s.xcconfig = {
    'FRAMEWORK_SEARCH_PATHS' => '"$(PODS_ROOT)/udentify_core_flutter/Frameworks"',
    'HEADER_SEARCH_PATHS' => '"$(PODS_ROOT)/udentify_core_flutter/Frameworks/UdentifyCommons.xcframework/ios-arm64/UdentifyCommons.framework/Headers"',
    'SWIFT_INCLUDE_PATHS' => '"$(PODS_ROOT)/udentify_core_flutter/Frameworks/UdentifyCommons.xcframework/ios-arm64/UdentifyCommons.framework/Modules"'
  }
  
  # Resources - include all resources
  s.resources = [
    'Resources/**/*.strings'
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

