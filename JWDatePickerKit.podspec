#
# Be sure to run `pod lib lint JWDatePickerKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'JWDatePickerKit'
    s.version          = '0.0.4'
    s.summary          = 'JWDatePickerKit.时间选择控件'
    s.homepage         = 'https://github.com/jw10126121/JWDatePickerKit'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'jw10126121' => '10126121@qq.com' }
    s.source           = { :git => 'https://github.com/jw10126121/JWDatePickerKit.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '9.0'
    
    s.source_files = 'JWDatePickerKit/Classes/**/*'
    s.swift_versions = ['4.2', '5.0'] # 同时支持4.2和5.0
    s.dependency 'XBDialog', '~> 1.5.0'
    s.dependency 'SnapKit', '~> 4.2.0'
    s.dependency 'PGDatePicker', '~> 2.6.9'

    # s.resource_bundles = {
    #   'JWDatePickerKit' => ['JWDatePickerKit/Assets/*.png']
    # }
    
    # s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    # s.dependency 'AFNetworking', '~> 2.3'
    
end
