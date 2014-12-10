require 'sinatra'
require 'sinatra/base'
require 'json/ext'
require 'yaml'
require 'active_record'
require 'active_support'

current_env = ENV["RACK_ENV"] ? ENV["RACK_ENV"] : "development"
database_config = YAML::load_file("config/database.yml")

begin
  config_hash = YAML::load_file("#{__dir__}/../../#{current_env}-http.yml")
  database_config[current_env] = config_hash["database"]
  SECURITY_KEY = config_hash["security"]["key"]
rescue Exception => e
  puts "Файл конфигурации не найден. Будут загружены настройки по-умолчанию."
  SECURITY_KEY = "1"
end

ActiveRecord::Base.configurations = database_config
ActiveRecord::Base.establish_connection(current_env.to_sym)