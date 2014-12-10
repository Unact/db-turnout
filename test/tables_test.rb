require File.expand_path '../test_helper.rb', __FILE__

class MyTest < Minitest::Test

  include Rack::Test::Methods
  include ContentHelpers
  
  def app
    App
  end
  
  def test_index
    params = {
      s: {email: :mail, login: :login },
      order: {email: :desc },
      q: {
        id_eq: 1,
        or: {
          id_lt: 5,
          id_gt: 8,
          and: {
            id_gt: 0,
            or: { id_lt: 1, id_gt: 2 },
            email_not_eq: 'bt' 
          },
          email_eq: '1'
        }
      }
    }
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT email AS mail, login FROM spree_users ORDER BY email desc")
    
    CONTENT_TYPES.each_pair do |content_type, content_type_str|
      puts content_type_str
      set_content_type(content_type_str, content_type)
      get '/tables/spree_users', params
      assert last_response.ok?, last_response.inspect
      
      response_body = last_response.body
      res = send("parse_response_#{content_type}", response_body)
      
      check_response_data(res, real_res)
      puts "-------------"
    end
  end
  
  def test_update
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    body_obj = {
      data: {
        email: '1@test.ru'
      },
      q: {
        email_eq: 'admin@test.ru'
      }
    }
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT * FROM spree_users WHERE email = '#{body_obj[:data][:email]}'")
    
    CONTENT_TYPES.each_pair do |content_type, content_type_str|
      puts content_type_str
      body_str = set_content_type(content_type_str, content_type, body_obj)
      put '/tables/spree_users', body_str
      assert last_response.ok?, last_response.inspect
      
      response_body = last_response.body
      res = send("parse_response_#{content_type}", response_body)
      puts res.inspect
      check_response_data(res, real_res)
      puts "-------------"
    end
  end
  
  private
  def check_response_data(res, real_res)
    assert res, res
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