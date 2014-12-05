require File.expand_path '../test_helper.rb', __FILE__

class MyTest < MiniTest::Unit::TestCase

  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get '/tables'
    assert last_response.ok?, last_response.inspect
    assert_equal "Hello, World!", last_response.body
  end
end