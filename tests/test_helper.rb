
# require 'bundler'
# Bundler.setup(:default, :test)
ENV['RACK_ENV'] = 'test'
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "main"
require "rack/test"
require "minitest/autorun"
require 'minitest/reporters'

include Rack::Test::Methods

def app
  Tacpic
end

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]