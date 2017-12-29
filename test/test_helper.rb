require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/mini_test'
require 'pry'

Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'worker_tools'
