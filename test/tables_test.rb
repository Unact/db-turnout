require File.expand_path '../test_helper.rb', __FILE__

class MyTest < Minitest::Test

  include Rack::Test::Methods
  include ContentHelpers
  
  def app
    App
  end
  
  def test_index
    params = {
      s: :email,
      odrer: :email
    }
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT email FROM spree_users ORDER BY email")
    
    CONTENT_TYPES.each_pair do |content_type, content_type_str|
      set_content_type(content_type_str)
      get '/tables/spree_users', params
      assert last_response.ok?, "#{last_response.inspect}\n#{content_type}"
      
      response_body = last_response.body
      res = send("parse_response_#{content_type}", response_body)
      
      assert res, response_body
      assert res[:columns], res
      assert res[:rows], res
      
      assert_equal real_res.columns.length, res[:columns].length, res[:columns]
      res[:columns].each_index do |i|
        assert_equal real_res.columns[i], res[:columns][i], res[:columns]
      end
      
      res[:rows].each_index do |i|
        res[:rows][i].each_index do |j|
          assert_equal real_res.rows[i][j], res[:rows][i][j]
        end
      end
    end
  end
end