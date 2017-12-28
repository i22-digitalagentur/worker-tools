require 'pry'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'worker_tools'

require 'minitest/autorun'
require 'active_record'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

load File.dirname(__FILE__) + '/schema.rb'
require File.dirname(__FILE__) + '/models.rb'

require 'database_cleaner'

DatabaseCleaner.strategy = :transaction

module Minitest
  class Spec
    before :each do
      DatabaseCleaner.start
    end

    after :each do
      DatabaseCleaner.clean
    end
  end
end
