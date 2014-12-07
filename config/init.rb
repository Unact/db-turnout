require 'sinatra'
require 'sinatra/base'
require 'json/ext'
require 'yaml'
require 'active_record'
require 'active_support'

config_hash = YAML::load_file("#{__dir__}/../../#{ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"}-http.yml")
ActiveRecord::Base.establish_connection(config_hash["database"])

SECURITY_KEY = config_hash["security"]["key"]