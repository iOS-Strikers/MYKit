require 'xcodeproj'
require 'fileutils'
require 'pathname'
root = File.expand_path('..', __dir__)
path = File.join(__dir__, 'SafeKitTests.xcodeproj')
project = Xcodeproj::Project.new(path)
host = project.new_target(:application, 'SafeKitHost', :ios, '15.0')
tests = project.new_target(:unit_test_bundle, 'SafeKitTests', :ios, '15.0')
tests.add_dependency(host)
fixture = project.new_target(:framework, 'SafeKitFixture', :ios, '15.0')
fixture_group = project.main_group.new_group('Fixture')
fixture.source_build_phase.add_file_reference(fixture_group.new_file('Fixture/FrameworkModel.m'))
header = fixture.headers_build_phase.add_file_reference(fixture_group.new_file('Fixture/SafeKitFixture.h'))
header.settings = {'ATTRIBUTES'=>['Public']}
host.add_dependency(fixture)
tests.add_dependency(fixture)
tests.frameworks_build_phase.add_file_reference(fixture.product_reference)
embed = host.new_copy_files_build_phase('Embed Frameworks')
embed.dst_subfolder_spec = '10'
embed.add_file_reference(fixture.product_reference)

sources = Dir[File.join(root, 'MYKit/Classes/SafeKit/**/*.m')] + [File.join(root, 'MYKit/Classes/Foundation/NSObject/NSObject+Swizzle.m'), File.join(__dir__, 'Host/main.m')]
source_group = project.main_group.new_group('Sources')
sources.each { |file| host.source_build_phase.add_file_reference(source_group.new_file(Pathname.new(file).relative_path_from(Pathname.new(__dir__)).to_s)) }
tests.source_build_phase.add_file_reference(source_group.new_file('SafeKitTests.m'))
header_paths = Dir[File.join(root, 'MYKit/Classes/**/*.h')].map { |p| File.dirname(p) }.uniq
[host, tests, fixture].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({'CLANG_ENABLE_OBJC_ARC'=>'YES', 'CLANG_ENABLE_MODULES'=>'YES', 'GENERATE_INFOPLIST_FILE'=>'YES', 'CODE_SIGNING_ALLOWED'=>'NO', 'PRODUCT_BUNDLE_IDENTIFIER'=>"org.mykit.#{target.name}", 'HEADER_SEARCH_PATHS'=>header_paths.map { |p| '"$(SRCROOT)/'+Pathname.new(p).relative_path_from(Pathname.new(__dir__)).to_s+'"' }, 'TARGETED_DEVICE_FAMILY'=>'1,2', 'IPHONEOS_DEPLOYMENT_TARGET'=>'15.0', 'DEFINES_MODULE'=>'YES', 'LD_RUNPATH_SEARCH_PATHS'=>'$(inherited) @executable_path/Frameworks @loader_path/Frameworks'})
  end
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/SafeKitHost.app/SafeKitHost'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
project.save
%w[Native Container KVO Unknown Null Notification Timer Record All Reverse Concurrent].each do |mode|
  scheme = Xcodeproj::XCScheme.new
  scheme.add_build_target(host)
  scheme.add_test_target(tests)
  scheme.test_action.build_configuration = 'Debug'
  scheme.test_action.xml_element.attributes['shouldUseLaunchSchemeArgsEnv'] = 'NO'
  environment = scheme.test_action.xml_element.add_element('EnvironmentVariables')
  environment.add_element('EnvironmentVariable', {'key'=>'MYKIT_TEST_MODE', 'value'=>mode, 'isEnabled'=>'YES'})
  scheme.save_as(path, 'SafeKit-'+mode, true)
end
