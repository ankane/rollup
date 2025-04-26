source "https://rubygems.org"

gemspec

gem "rake"
gem "minitest", ">= 5"
gem "activerecord", "~> 8.0.0"
gem "railties", require: false

platform :ruby do
  gem "pg"
  gem "mysql2"
  gem "trilogy"
  gem "sqlite3"
end

platform :jruby do
  gem "sqlite3-ffi"
end
