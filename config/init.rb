require 'sinatra'
require 'sinatra/base'
require 'json/ext'
require 'yaml'
require 'active_record'
require 'active_support'

database_hash = YAML::load_file("#{__dir__}/../../#{ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"}-http.yml")["database"]
ActiveRecord::Base.establish_connection(database_hash)
