Gem::Specification.new do |spec|
  spec.name          = "rollups"
  spec.version       = "0.1.4"
  spec.summary       = "Rollup time-series data in Rails"
  spec.homepage      = "https://github.com/ankane/rollup"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "activesupport", ">= 5.2"
  spec.add_dependency "groupdate", ">= 5.2"
end
