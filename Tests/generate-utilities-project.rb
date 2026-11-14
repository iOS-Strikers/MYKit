require 'xcodeproj'
require 'pathname'
root = File.expand_path('..', __dir__)
path = File.join(__dir__, 'UtilitiesTests.xcodeproj')
project = Xcodeproj::Project.new(path)
host = project.new_target(:application, 'UtilitiesHost', :ios, '15.0')
tests = project.new_target(:unit_test_bundle, 'UtilitiesTests', :ios, '15.0')
tests.add_dependency(host)
group = project.main_group.new_group('Sources')
(Dir[File.join(root, 'MYKit/Classes/**/*.m')] + [File.join(__dir__, 'Host/main.m')]).each do |file|
  host.source_build_phase.add_file_reference(group.new_file(Pathname.new(file).relative_path_from(Pathname.new(__dir__)).to_s))
end
tests.source_build_phase.add_file_reference(group.new_file('UtilitiesTests.m'))
paths = Dir[File.join(root, 'MYKit/Classes/**/*.h')].map { |p| File.dirname(p) }.uniq
[host, tests].each do |target|
  target.build_configurations.each do |config|
    config.build_settings.merge!({'CLANG_ENABLE_OBJC_ARC'=>'YES', 'CLANG_ENABLE_MODULES'=>'YES', 'GENERATE_INFOPLIST_FILE'=>'YES', 'CODE_SIGNING_ALLOWED'=>'NO', 'PRODUCT_BUNDLE_IDENTIFIER'=>"org.mykit.#{target.name}", 'HEADER_SEARCH_PATHS'=>paths.map { |p| '"$(SRCROOT)/'+Pathname.new(p).relative_path_from(Pathname.new(__dir__)).to_s+'"' }, 'TARGETED_DEVICE_FAMILY'=>'1,2', 'IPHONEOS_DEPLOYMENT_TARGET'=>'15.0', 'OTHER_LDFLAGS'=>'$(inherited) -lz', 'LD_RUNPATH_SEARCH_PATHS'=>'$(inherited) @executable_path/Frameworks @loader_path/Frameworks'})
  end
end
tests.build_configurations.each do |config|
  config.build_settings['TEST_HOST'] = '$(BUILT_PRODUCTS_DIR)/UtilitiesHost.app/UtilitiesHost'
  config.build_settings['BUNDLE_LOADER'] = '$(TEST_HOST)'
end
project.save
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(host)
scheme.add_test_target(tests)
scheme.test_action.build_configuration = 'Debug'
scheme.save_as(path, 'Utilities', true)
