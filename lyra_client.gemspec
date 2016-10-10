# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lyra_client/version'

Gem::Specification.new do |spec|
  spec.name          = "lyra-client"
  spec.version       = LyraClient::VERSION
  spec.authors       = ["Arturo Reuschenbach Puncernau"]
  spec.email         = ["a.reuschenbach.puncernau@sap.com"]

  spec.summary       = %q{Ruby client for Lyra.}
  spec.description   = %q{Ruby client for Lyra.}
  spec.homepage      = "https://github.com/sapcc/lyra-client"
  spec.license       = "Apache 2"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "***REMOVED***"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency 'pry', '~> 0.10.3'
  spec.add_development_dependency 'excon', '~> 0.52.0'
end
