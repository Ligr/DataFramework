Pod::Spec.new do |s|
  s.name = "DataFramework"
  s.version = "0.4.6"
  s.license = "MIT"
  s.summary = "Utilities that help to load, parse and display data"
  s.homepage = "https://github.com/Ligr/DataFramework"
  s.authors = { "Aliaksandr Huryn" => "aliaksandr.huryn@gmail.com" }
  s.source = { :git => "https://github.com/Ligr/DataFramework.git", :tag => s.version }

  s.ios.deployment_target = "11.0"
  # s.osx.deployment_target = "10.12"
  # s.tvos.deployment_target = "10.0"
  # s.watchos.deployment_target = "3.0"

  s.swift_versions = ["5.0", "5.1"]

  s.source_files = "DataFramework/Classes/**/*"

  s.dependency "ReactiveCocoa", "~> 10.0"
  s.dependency "ReactiveSwift", "~> 6.0"
  s.dependency "DeepDiff", "~> 2.0"
end
