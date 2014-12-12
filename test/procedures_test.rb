require File.expand_path '../test_helper.rb', __FILE__

class ProceduresTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  
  def app
    App
  end
  
  def test_sql_proc_name_filter
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    get '/procedures/test_table;adssa', nil
    assert last_response.not_found?
  end
  
  def test_sql_proc_name_filter
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    params = {
      p: [
        1,
        2,
        { t: 1 }
      ]
    }
    
    get '/procedures/test_table', params
    assert last_response.not_found?
  end
end