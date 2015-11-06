# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'the_lone_dyno/version'

Gem::Specification.new do |spec|
  spec.name          = "the_lone_dyno"
  spec.version       = TheLoneDyno::VERSION
  spec.authors       = ["schneems"]
  spec.email         = ["richard.schneeman@gmail.com"]

  spec.summary       = %q{Isolate code to only run on a certain number of Heroku dynos.}
  spec.description   = %q{Run code on only a certain number of Heroku dynos, isolated}
  spec.homepage      = "https://github.com/schneems/the_lone_dyno"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency             "hey_you", "~> 0.1.1"

  spec.add_development_dependency "pg", ">= 0.15"
  spec.add_development_dependency "activerecord", ">= 2.3"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
