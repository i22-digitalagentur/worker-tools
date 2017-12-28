require 'active_record'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

require File.join(__dir__, '../schema.rb')
require File.join(__dir__, + '../models.rb')
