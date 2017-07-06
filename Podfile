platform :ios, ’11.0’

target 'VisionDemo’ do
    use_frameworks!
    pod 'BNKit', :git => 'https://github.com/beeth0ven/BNKit.git', :branch => 'master'
    pod 'Action'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = ‘3.2’
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
        end
    end
end

#   pod update --no-repo-update
#   The Podfile: http://guides.cocoapods.org/using/the-podfile.html
