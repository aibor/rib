# coding: utf-8
#
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rib/version'

Gem::Specification.new do |spec|
  spec.name          = "rib"
  spec.version       = RIB::VERSION
  spec.authors       = ["Tobias Böhm"]
  spec.email         = ["code@aibor.de"]
  spec.summary       = %q{Simple IRC and XMPP bot framework}
  spec.homepage      = "https://www.aibor.de/cgit/rib/about"
  spec.license       = "GPL-2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "yard"

  spec.add_runtime_dependency "xmpp4r"
end

