class App < Sinatra::Base
  
  before do
    unless SECURITY_KEY==request.env["HTTP_AUTHORIZATION_KEY"]
      halt 403, "Доступ запрещен"
    end
  end
  
  error do
    "Error: #{env['sinatra.error'].message}"
  end
end
