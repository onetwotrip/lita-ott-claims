Gem::Specification.new do |spec|
  spec.name          = 'lita-ott-claims'
  spec.version       = '0.0.2'
  spec.authors       = ['Alexey Sychev']
  spec.email         = ['alexey.sychev@onetwotrip.com']
  spec.description   = 'Lita plugin for claiming machines at OneTwoTrip'
  spec.summary       = 'Summary'
  spec.license       = 'OTT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'lita', '>= 4.7'
  spec.add_runtime_dependency 'chef'

  spec.add_development_dependency 'bundler', '~> 1.3'
end
