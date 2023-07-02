Gem::Specification.new do |spec|
  spec.name          = "rollups"
  spec.version       = "0.3.0"
  spec.summary       = "Rollup time-series data in Rails"
  spec.homepage      = "https://github.com/ankane/rollup"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3"

  spec.add_dependency "activesupport", ">= 6.1"
  spec.add_dependency "groupdate", ">= 6.1"
end
