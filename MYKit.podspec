#
# Be sure to run `pod lib lint MYKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MYKit'
  s.version          = '1.1.3'
  s.summary          = 'A short description of MYKit.'
  
  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  
  s.description      = <<-DESC
  效率工具类 & APP Crash 防护；
  DESC
  
  s.homepage         = 'https://github.com/iOS-Strikers/MYKit.git'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sunjinshuai' => 'sunjinshuai@aikucun.com' }
  s.source           = { :git => 'https://github.com/iOS-Strikers/MYKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.static_framework = true
  s.frameworks = 'UIKit', 'Foundation'
  s.ios.deployment_target = '8.0'
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |core|
    core.source_files = 'MYKit/Classes/Core/MYKit.h', 'MYKit/Classes/Core/MYKitDefinition.h'
    core.dependency 'MYKit/UIKit'
    core.dependency 'MYKit/Foundation'
    core.dependency 'MYKit/SafeKit'
  end
  
  s.subspec 'UIKit' do |kit|
    kit.source_files = 'MYKit/Classes/UIKit/MYUIKit.h', 'MYKit/Classes/UIKit/**/*'
    kit.dependency 'MYKit/Foundation'
  end
  
  s.subspec 'Foundation' do |foundation|
    foundation.source_files = 'MYKit/Classes/Foundation/MYFoundationKit.h', 'MYKit/Classes/Foundation/**/*'
  end
  
  s.subspec 'SafeKit' do |safe|
    safe.source_files = 'MYKit/Classes/SafeKit/SafeKitShield.h', 'MYKit/Classes/SafeKit/MYSafeKit', 'MYKit/Classes/SafeKit/**/*.{h,m}'
    safe.dependency 'MYKit/Foundation'
  end
  
end
