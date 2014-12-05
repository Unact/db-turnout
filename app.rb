require_relative "#{__dir__}/config/init.rb"

Dir.glob("#{__dir__}/controllers/*.rb").each { |file| require_relative file }
Dir.glob("#{__dir__}/lib/*.rb").each { |file| require_relative file }

class App < Sinatra::Base
  include Helpers
  
  configure do
    set :root, __dir__
    enable :logging
    
    file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    file.sync = true
    use Rack::CommonLogger, file
  end
  
  run! if __FILE__ == $0
end
