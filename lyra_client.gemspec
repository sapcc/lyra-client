# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lyra_client/version'

Gem::Specification.new do |spec|
  spec.name          = "lyra-client"
  spec.version       = LyraClient::VERSION
  spec.authors       = ["Arturo Reuschenbach Puncernau"]
  spec.email         = ["a.reuschenbach.puncernau@sap.com"]

  spec.summary       = %q{Ruby client for Lyra API.}
  spec.description   = %q{Ruby client for Lyra API.}
  spec.homepage      = "https://github.com/sapcc/lyra-client"
  spec.license       = "Apache 2"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.3.13"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "rspec", "~> 3.11.0"
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'excon', '~> 0.92.3'
end
