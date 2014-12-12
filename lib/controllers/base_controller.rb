require 'sinatra/base'
require 'helpers'
require '../helpers'

class BaseController < Sinatra::Base
  include Helpers
  
  VALID_SQL_NAME_REGEXP = /^[[:alnum:]_]+[\.]?[[:alnum:]_]+/
  
  PROVIDES_ARRAY = ['json', 'xml']
  
  before do
    unless SECURITY_KEY==request.env["HTTP_AUTHORIZATION_KEY"]
      halt 403, "Доступ запрещен"
    end
  end
  
  error do
    "Error: #{env['sinatra.error'].message}"
  end
end
