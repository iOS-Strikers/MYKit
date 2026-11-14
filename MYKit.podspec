#
# Be sure to run `pod lib lint MYKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MYKit'
  s.version          = '2.0.0'
  s.summary          = 'iOS Foundation、UIKit 扩展与可选的异常防护。'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = <<-DESC
  为 Objective-C 项目提供集合、字符串、日期及 UIKit 辅助功能，支持按需启用
  容器、KVO、通知、定时器、未知方法和 NSNull 防护。保留合法调用语义，
  提供错误上报与独立 XCTest 回归矩阵；未知方法兜底需要显式登记真实签名。
  DESC
  
  s.homepage         = 'https://github.com/iOS-Strikers/MYKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sunjinshuai' => 'sunjinshuai@aikucun.com' }
  s.source           = { :git => 'https://github.com/iOS-Strikers/MYKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.static_framework = true
  s.frameworks = 'UIKit', 'Foundation'
  s.ios.deployment_target = '15.0'
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
    core.source_files = 'MYKit/Classes/Core/MYKit.h', 'MYKit/Classes/Core/MYKitDefinition.h'
    core.dependency 'MYKit/UIKit'
    core.dependency 'MYKit/Foundation'
    core.dependency 'MYKit/SafeKit'
  end
  
  s.subspec 'UIKit' do |kit|
    kit.source_files = 'MYKit/Classes/UIKit/MYUIKit.h', 'MYKit/Classes/UIKit/**/*'
    kit.private_header_files = 'MYKit/Classes/UIKit/UIWindow/MYWindowContextInternal.h'
    kit.dependency 'MYKit/Foundation'
  end
  
  s.subspec 'Foundation' do |foundation|
    foundation.source_files = 'MYKit/Classes/Foundation/MYFoundationKit.h', 'MYKit/Classes/Foundation/**/*'
  end
  
  s.subspec 'SafeKit' do |safe|
    safe.source_files = 'MYKit/Classes/SafeKit/**/*.{h,m}'
    safe.private_header_files = 'MYKit/Classes/SafeKit/FoundationContainer/MYSafeContainerInternal.h'
    safe.dependency 'MYKit/Foundation'
  end
  
end
