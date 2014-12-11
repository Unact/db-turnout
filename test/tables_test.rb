require File.expand_path '../test_helper.rb', __FILE__

class MyTest < ActiveSupport::TestCase

  include Rack::Test::Methods
  
  def app
    App
  end
  
  CONTENT_TYPES.each_pair do |content_type, content_type_str|
    define_method("test_index_#{content_type}".to_sym) do
      index_content_type_test(content_type, content_type_str)
    end
    define_method("test_update_#{content_type}".to_sym) do
      update_content_type_test(content_type, content_type_str)
    end
  end
  
  def index_content_type_test(content_type, content_type_str)
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    params = {
      s: { name: :test_name, val: :val },
      order: { test_name: :desc },
      q: {
        val_eq: 1,
        or: {
          val_lt: 5,
          val_gt: 8,
          and: {
            val_gt: 0,
            or: { val_lt: 1, val_gt: 2 },
            name_not_eq: 'test_4' 
          },
          name_matches: '%1%'
        }
      }
    }
  
    real_res = ActiveRecord::Base.connection.select_all('
    SELECT
      "test_table"."name" AS "test_name",
      "test_table"."val" AS "val"
    FROM "test_table"
    WHERE
      (
        "test_table"."val" = 1
        OR
        (
          ("test_table"."val" < 5 OR "test_table"."val" > 8)
          AND
          (
            "test_table"."val" > 0
            OR
            ("test_table"."val" < 1 OR "test_table"."val" > 2)
          )
          AND
          "test_table"."name" != \'test_4\' OR "test_table"."name" LIKE \'%1%\'
        )
      )
    ORDER BY "test_name" desc
    LIMIT 500')
    
    set_content_type(content_type_str, content_type)
    get '/tables/test_table', params
    assert last_response.ok?, last_response.inspect
    
    response_body = last_response.body
    res = send("parse_response_#{content_type}", response_body)
    
    check_response_data(res, real_res)
  end
  
  def update_content_type_test(content_type, content_type_str)
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    body_obj = {
      data: {
        name: 'test_1'
      },
      q: {
        name_eq: 'admin@test.ru'
      }
    }
    
    body_str = set_content_type(content_type_str, content_type, body_obj)
    put '/tables/test_table', body_str
    assert last_response.ok?, last_response.inspect
    
    response_body = last_response.body
    puts last_response.inspect
    puts response_body
    res = send("parse_response_#{content_type}", response_body)
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT * FROM test_table WHERE name = '#{body_obj[:data][:name]}'")
    
    puts res.inspect
    check_response_data(res, real_res)
  end
end