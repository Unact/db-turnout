module Helpers
  VALID_SQL_NAME_REGEXP = /^[[:alnum:]_]+/
  
  def get_records_by_ids(table, unquoted_table_name, ids)
    primary_key = ActiveRecord::Base.connection.primary_key unquoted_table_name
    
    select_manager = table
    select_manager = select_manager.project(Arel.star)
    select_manager = select_manager.where(table[primary_key].in(ids))
    sql = select_manager.to_sql
    ActiveRecord::Base.connection.select_all(sql)
  end
  
  def get_content_for_ids(table, unquoted_table_name, ids, postprocess_block)
    raw_data = get_records_by_ids(table, ids)
    raw_data = postprocess_block.call(raw_data, request) if postprocess_block
    data, type_str = generate_acceptable_output(raw_data, unquoted_table_name)
    content_type(type_str)
    data
  end
  
  def generate_proc_output(params_list, proc_name, postprocess_block)
    raw_data = ActiveRecord::Base.connection.select_all(
      "call #{ActiveRecord::Base.connection.quote_table_name proc_name}(#{params_list.join(', ')})")
    raw_data = postprocess_block.call(raw_data, request) if postprocess_block
    data, type_str = generate_acceptable_output(raw_data, proc_name)
    content_type(type_str)
    data
  end
  
  def generate_acceptable_output(data, unquoted_table_name)
    mime_found = false
    
    help_block = Proc.new do |type|
      type_str = type.to_s
      case type_str
      when /json/, '*/*'
        mime_found = true
        return (data ? data.to_json : nil), (type_str=='*/*' ? 'text/json' : type_str)
      when /xml/
        mime_found = true
        return (data ? data.to_ary.to_xml(:root => unquoted_table_name) : nil), type_str
      end
    end
    
    request.accept.each &help_block
    help_block.call request.media_type
    raise Exception, "Данный тип MIME не поддерживается" unless mime_found
  end
  
  def get_acceptable_body(data_str)
    mime_found = false
    
    help_block = Proc.new do |type|
      type_str = type.to_s
      case type_str
      when "text/html"
        mime_found = true
        return data_str
      when /json/
        mime_found = true
        return ActiveSupport::JSON.decode(data_str)
      when /xml/
        mime_found = true
        parser = Nori.new
        body_data = parser.parse(data_str)
        if body_data.nil? || body_data.length!=1
          raise Exception, "Неверный вид параметров"
        end
        return body_data = body_data.first[1]
      end
    end
    
    request.accept.each &help_block
    help_block.call request.media_type
    raise Exception, "Данный тип MIME не поддерживается" unless mime_found
  end
  
  def get_body_data_from_request
    body_data_str = request.body.read
    get_acceptable_body(body_data_str)
  end
  
  def get_proc_params_from_body
    body_data = get_body_data_from_request
    
    Sql::get_proc_params_from_object(body_data["p"])
  end
end