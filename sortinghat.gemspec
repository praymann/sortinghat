# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sortinghat/version'

Gem::Specification.new do |spec|
  spec.name          = "sortinghat"
  spec.version       = Sortinghat::VERSION
  spec.authors       = ["D. Pramann"]
  spec.email         = ["daniel@pramann.org"]

  spec.summary       = %q{Have auto-scaling instances name themselves!}
  spec.description   = %q{Ruby gem which when given arguements, allows an instance in an auto-scaling group to name/dns/tag itself.}
  spec.homepage      = "https://github.com/praymann/sortinghat"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "aws-sdk", "~> 2.1.2"
  spec.add_runtime_dependency "json_pure"
end
