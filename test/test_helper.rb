ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'nokogiri'
require 'nori'
require 'active_support/testing/autorun'
require 'active_support/test_case'

require './app.rb'

def create_fixtures(*fixture_set_names, &block)
  FixtureSet.create_fixtures(ActiveSupport::TestCase.fixture_path, fixture_set_names, {}, &block)
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
  include ActiveRecord::TestFixtures
  self.fixture_path = "./test/fixtures/"
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  
  fixtures :all
  # Add more helper methods to be used by all tests here...
  
  include Rack::Test::Methods
  
  def app
    App
  end
  
  CONTENT_TYPES = {
    json: 'application/json',
    # html: 'text/html',
    xml: 'application/xml'
  }
  
  def set_content_type(content_type_str, content_type, body_obj = nil)
    header 'Accept', content_type_str
    header 'CONTENT_TYPE', content_type_str
    
    body_obj.send("to_#{content_type}") if body_obj
  end
  
  def parse_response_json(response)
    data = ActiveSupport::JSON.decode(response)
    
    create_result_obj(data)
  end
  
  def parse_response_html(response)
    html_doc = Nokogiri::HTML(response)
    html_columns = html_doc.css('table thead tr th')
    columns = []
    html_columns.each do |html_column|
      columns << html_column.children.first.content.strip
    end
    html_rows = html_doc.css('table tbody tr')
    rows = []
    data = []
    html_rows.each do |html_row|
      j = 0
      row = []
      data_row = {}
      html_row.children.each do |html_cell|
        unless html_cell.text?
          value = html_cell.content.strip
          row << value
          data_row[columns[j]] = value
          j+=1
        end
      end
      rows << row
      data << data_row
    end
    { rows: rows, columns: columns, data: nil }
  end
  
  def parse_response_xml(response)
    parser = Nori.new
    data = parser.parse(response)
    
    data && data.length>0 ? create_result_obj(data.to_a[0][1]) : nil
  end
  
  def create_result_obj(data)
    columns = []
    rows = []
    if data && Array===data && !data.empty?
      data.each do |row|
        row_to_insert = []
        row.each_pair do |column, value|
          columns << column unless columns.include? column
          row_to_insert << value
        end
        rows << row_to_insert
      end
    end
    
    { rows: rows, columns: columns, data: data }
  end
  
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