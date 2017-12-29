require 'simplecov'

SimpleCov.profiles.define 'lib' do
  add_filter '/test/'
  add_filter '/config/'
  add_group 'Libraries', 'lib'
end

SimpleCov.start 'lib'
