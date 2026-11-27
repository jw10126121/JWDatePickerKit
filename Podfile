install! 'cocoapods', :warn_for_unused_master_specs_repo => false

use_frameworks!
platform :ios, '15.0'
project 'JWDatePickerKit.xcodeproj'

target 'JWDatePickerKit_Example' do
  pod 'JWDatePickerKit', :path => './'
  target 'JWDatePickerKit_Tests' do
    inherit! :search_paths

    
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # XBDialog 1.6.0 is the latest published release and emits two warnings
      # from its legacy Objective-C associated-object key implementation.
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES' if target.name == 'XBDialog'
    end
  end
end
