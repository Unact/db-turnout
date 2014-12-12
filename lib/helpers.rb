module Helpers
  def generate_acceptable_output(data)
    mime_found = false
    request.accept.each do |type|
      type_str = type.to_s
      case type_str
      when 'text/json', 'application/json'
        mime_found = true
        return (data ? data.to_json : nil), type_str
      when 'text/xml', 'application/xml', "application/xhtml+xml"
        mime_found = true
        return (data ? data.to_ary.to_xml(:root => params[:table_name]) : nil), type_str
      end
    end
    raise Exception, "Данный тип MIME не поддерживается" unless mime_found
  end
  
  def get_acceptable_body(data_str)
    mime_found = false
    request.accept.each do |type|
      type_str = type.to_s
      case type_str
      when "text/html"
        mime_found = true
        return data_str
      when 'text/json', 'application/json'
        mime_found = true
        return ActiveSupport::JSON.decode(data_str)
      when 'text/xml', 'application/xml', "application/xhtml+xml"
        mime_found = true
        parser = Nori.new
        body_data = parser.parse(data_str)
        if body_data.nil? || body_data.length!=1
          raise Exception, "Неверный вид параметров"
        end
        return body_data = body_data.first[1]
      end
    end
    raise Exception, "Данный тип MIME не поддерживается" unless mime_found
  end
  
  def get_body_data_from_request
    body_data_str = request.body.read
    get_acceptable_body(body_data_str)
  end
end