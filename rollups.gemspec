Gem::Specification.new do |spec|
  spec.name          = "rollups"
  spec.version       = "0.1.1"
  spec.summary       = "Rollup time-series data in Rails"
  spec.homepage      = "https://github.com/ankane/rollup"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@chartkick.com"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.6"

  spec.add_dependency "activesupport", ">= 5.1"
  spec.add_dependency "groupdate", ">= 5.2"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", ">= 5"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "mysql2"
  spec.add_development_dependency "sqlite3"
end
