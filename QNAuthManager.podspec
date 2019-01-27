#
# Be sure to run `pod lib lint QNAuthManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'QNAuthManager'
  s.version          = '1.0.0'
  s.summary          = 'Auth Library'
  s.swift_version    = '4.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Auth via Facebook, Zalo, Google, AccountKit
                       DESC

  s.homepage         = 'https://github.com/quannguyen90/QNAuthManager'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'quannguyen90' => 'quannv.tm@gmail.com' }
  s.source           = { :git => 'https://github.com/quannguyen90/QNAuthManager.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'QNAuthManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'QNAuthManager' => ['QNAuthManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  #s.static_framework = true
  #s.dependency 'AccountKit', '~> 4.35'
end
