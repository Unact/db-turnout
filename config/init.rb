require 'sinatra'
require 'sinatra/base'
require 'json/ext'
require 'yaml'
require 'active_record'
require 'active_support'

database_hash = YAML::load_file('config/database.yml')[ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"]
puts database_hash.inspect
database_hash = YAML::load_file(database_hash["db_settings_file"]) if database_hash["db_settings_file"]
puts database_hash.inspect
ActiveRecord::Base.establish_connection(database_hash)
