install! 'cocoapods', :warn_for_unused_master_specs_repo => false

source 'https://gitee.com/jw10126121/JWPublicSpecs.git'
source 'https://cdn.cocoapods.org/'

use_frameworks!
platform :ios, '15.0'
project 'JWDatePickerKit.xcodeproj'

target 'JWDatePickerKit_Example' do
  pod 'JWDatePickerKit', :path => './'
  pod 'JWDialogManager', :path => '../JWDialogManager'
  target 'JWDatePickerKit_Tests' do
    inherit! :search_paths

    
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
