module BaseController
  
  VALID_SQL_NAME_REGEXP = /^[[:alnum:]_]+[\.]?[[:alnum:]_]+/
  
  PROVIDES_ARRAY = ['json', 'xml']
  
  PROCEDURES_PATH = '/procedures' unless defined? PROCEDURES_PATH
  TABLES_PATH = '/tables' unless defined? TABLES_PATH
  
  before do
    unless SECURITY_KEY==request.env["HTTP_AUTHORIZATION_KEY"]
      halt 403, "Доступ запрещен"
    end
  end
  
  error do
    "Error: #{env['sinatra.error'].message}"
  end
end
