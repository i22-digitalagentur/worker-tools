require 'simplecov'
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/minitest'
require 'pry'

Dir[File.join(__dir__, 'support/**/*.rb')].sort.each { |f| require f }

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'worker_tools'
