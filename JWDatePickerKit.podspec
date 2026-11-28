#
# Be sure to run `pod lib lint JWDatePickerKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'JWDatePickerKit'
    s.version          = '1.0.0'
    s.summary          = 'JWDatePickerKit.时间选择控件'
    s.homepage         = 'https://gitee.com/jw10126121/JWDatePickerKit'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'jw10126121' => '10126121@qq.com' }
    s.source           = { :git => 'https://gitee.com/jw10126121/JWDatePickerKit.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
    
    s.ios.deployment_target = '15.0'
    
    s.swift_versions = ['5.0', '6.0']
    s.default_subspecs = 'Controller'

    # 与 JWTextPickerManager 对齐的公共子模块命名。
    s.subspec 'Core' do |core|
        core.source_files = 'JWDatePickerKit/Classes/Picker/**/*.swift'
        core.resource_bundles = { 'JWDatePickerKit' => ['JWDatePickerKit/Resources/**/*.strings'] }
    end

    # 旧名称保留为别名，现有 Podfile 无需修改。
    s.subspec 'Picker' do |picker|
        picker.dependency 'JWDatePickerKit/Core'
    end

    s.subspec 'Content' do |content|
        content.source_files = 'JWDatePickerKit/Classes/Content/**/*.swift', 'JWDatePickerKit/Classes/JWDatePickerMenuHeaderView.swift'
        content.dependency 'JWDatePickerKit/Core'
    end

    s.subspec 'SwiftUI' do |swiftui|
        swiftui.source_files = 'JWDatePickerKit/SwiftUI/**/*.swift'
        swiftui.dependency 'JWDatePickerKit/Core'
    end

    s.subspec 'Controller' do |controller|
        controller.source_files = 'JWDatePickerKit/Classes/JWDatePickerViewController.swift'
        controller.dependency 'JWDatePickerKit/Content'
        controller.dependency 'JWDialogManager', '~> 0.1.3'
    end

end
