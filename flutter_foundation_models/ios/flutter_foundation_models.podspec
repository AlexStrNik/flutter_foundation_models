Pod::Spec.new do |s|
  s.name             = 'flutter_foundation_models'
  s.version          = '0.2.0'
  s.summary          = 'Flutter plugin for Apple\'s on-device Foundation Models.'
  s.description      = 'A Flutter plugin for Apple\'s on-device Foundation Models. Generate text, structured output, and use tools with the on-device language model.'
  s.homepage         = 'https://github.com/AlexStrNik/flutter_foundation_models'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'AlexStrNik' => 'alexstrnik@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_foundation_models/Sources/flutter_foundation_models/**/*.swift'
  s.resource_bundles = {'flutter_foundation_models_privacy' => ['flutter_foundation_models/Sources/flutter_foundation_models/PrivacyInfo.xcprivacy']}
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
