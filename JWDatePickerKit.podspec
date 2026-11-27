#
# Be sure to run `pod lib lint JWDatePickerKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'JWDatePickerKit'
    s.version          = '0.1.2'
    s.summary          = 'JWDatePickerKit.时间选择控件'
    s.homepage         = 'https://github.com/jw10126121/JWDatePickerKit'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'jw10126121' => '10126121@qq.com' }
    s.source           = { :git => 'https://github.com/jw10126121/JWDatePickerKit.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '15.0'
    
    s.swift_versions = ['6.0']
    s.default_subspecs = 'Controller'

    s.subspec 'Picker' do |picker|
        picker.source_files = 'JWDatePickerKit/Classes/Picker/**/*.swift'
        picker.resource_bundles = { 'JWDatePickerKit' => ['JWDatePickerKit/Resources/**/*.strings'] }
    end

    s.subspec 'Content' do |content|
        content.source_files = 'JWDatePickerKit/Classes/Content/**/*.swift', 'JWDatePickerKit/Classes/JWDatePickerMenuHeaderView.swift'
        content.dependency 'JWDatePickerKit/Picker'
    end

    s.subspec 'Controller' do |controller|
        controller.source_files = 'JWDatePickerKit/Classes/JWDatePickerViewController.swift'
        controller.dependency 'JWDatePickerKit/Content'
        controller.dependency 'XBDialog', '~> 1.6'
    end

end
