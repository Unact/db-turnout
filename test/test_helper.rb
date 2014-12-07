ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'
require 'nokogiri'
require 'nori'

require '../app.rb'

CONTENT_TYPES = {
  json: 'application/json',
  html: 'text/html',
  xml: 'application/xml'
}

module ContentHelpers
  def set_content_type(content_type)
    header 'Accept', content_type
    header 'CONTENT_TYPE', content_type
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
    
    create_result_obj(data.to_a[0][1])
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
end