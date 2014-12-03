require_relative './config/init.rb'

Dir.glob('./controllers/*.rb').each { |file| require_relative file }
Dir.glob('./lib/*.rb').each { |file| require_relative file }

class App < Sinatra::Base
  helpers Sinatra::JSON
  include Helpers
  
  configure do
    set :root, File.dirname(__FILE__)
    enable :logging
    file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    file.sync = true
    use Rack::CommonLogger, file
  end
  
  run! if __FILE__ == $0
end
