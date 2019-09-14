source "https://rubygems.org"

gem 'rack'
gem 'rake'
gem 'slim'
gem 'jwt'
gem 'sequel'
gem 'puma'
gem 'mysql2'
gem 'roda'
gem 'bcrypt'
gem 'rodauth'

# Test requirements
group :test, :development do
  gem 'minitest-reporters'
  gem 'minitest-sequel'
  gem 'rack-test'
  gem 'faker'
  gem 'yard'
  # correct new 1.0 version wasn't marked as release, neither on Github nor on rubygems
  gem 'yard-sinatra', git: 'https://github.com/rkh/yard-sinatra', ref: 'b0d8403'
  gem 'yard-appendix'
  gem 'yard-doctest'
  gem 'prmd'
  gem 'json_schemer'
  gem 'yard-minitest-spec'
end