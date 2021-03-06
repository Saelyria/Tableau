Pod::Spec.new do |s|
  s.name             = 'Braid'
  s.version          = '1.0.3'
  s.summary          = 'Declarative, type-safe table view binding.'
  s.description      = <<-DESC
  Braid is a table view binding library that makes setup for table views more declarative, more functional, and
  more type-safe.
  DESC

  s.homepage         = 'https://github.com/Saelyria/Braid'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Aaron Bosnjak' => 'aaron.bosnjak707@gmail.com' }
  s.source           = { :git => 'https://github.com/Saelyria/Braid.git', :tag => s.version.to_s }
  s.swift_version    = '5'

  s.ios.deployment_target = '8.0'
  s.default_subspec = "Core"

  s.subspec "Core" do |ss|
    ss.source_files = 'Core/', 'Core/Protocols/', 'Core/TableView/', 'Core/TableView/SingleSection', 'Core/TableView/MultiSection', 'Core/TableView/AnySection', 'Core/Diffing/'
    ss.ios.framework = "UIKit"
  end

  s.subspec "Rx" do |ss|
    ss.source_files = 'Rx/'
    ss.ios.framework = "UIKit"
    ss.dependency 'Braid/Core'
    ss.dependency 'RxSwift', '~> 5'
    ss.dependency 'RxCocoa', '~> 5'
    ss.pod_target_xcconfig = { 'OTHER_SWIFT_FLAGS' => '-DRX_BRAID', }
  end
end
