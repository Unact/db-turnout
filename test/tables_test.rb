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
    define_method("test_create_#{content_type}".to_sym) do
      create_content_type_test(content_type, content_type_str)
    end
    define_method("test_delete_#{content_type}".to_sym) do
      delete_content_type_with_query_test(content_type, content_type_str)
    end
  end
  
  def test_authorization
    get '/tables/test_table', nil
    assert last_response.forbidden?
  end
  
  def test_sql_table_name_filter
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    get '/tables/test_table;adssa', nil
    assert last_response.not_found?
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
        name: 'admin@test.ru'
      },
      q: {
        name_eq: 'test_1'
      }
    }
    
    body_str = set_content_type(content_type_str, content_type, body_obj)
    put '/tables/test_table', body_str
    assert last_response.ok?, last_response.inspect
    
    response_body = last_response.body
    res = send("parse_response_#{content_type}", response_body)
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT * FROM test_table WHERE name = '#{body_obj[:data][:name]}'")
    puts real_res.inspect
    check_response_data(res, real_res)
  end
  
  def create_content_type_test(content_type, content_type_str)
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    body_obj = {
      data: [
        { name: 'admin@test.ru', val: 5 }
      ]
    }
    
    body_str = set_content_type(content_type_str, content_type, body_obj)
    post '/tables/test_table', body_str
    assert last_response.ok?, last_response.inspect
    
    response_body = last_response.body
    res = send("parse_response_#{content_type}", response_body)
    
    real_res = ActiveRecord::Base.connection.select_all("
    SELECT * FROM test_table WHERE name = '#{body_obj[:data].first[:name]}'")
    puts real_res.inspect
    check_response_data(res, real_res)
  end
  
  def delete_content_type_with_query_test(content_type, content_type_str)
    header 'AUTHORIZATION_KEY', SECURITY_KEY
    
    params = {
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
    
    set_content_type(content_type_str, content_type)
    delete '/tables/test_table', params
    assert last_response.ok?, last_response.inspect
    
    real_res = ActiveRecord::Base.connection.select_all('
    SELECT * FROM test_table
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
      )')
    assert_empty real_res, real_res.inspect
  end
end