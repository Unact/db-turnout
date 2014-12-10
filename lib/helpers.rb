module Helpers
  def generate_acceptable_output(data)
    mime_found = false
    request.accept.each do |type|
      type_str = type.to_s
      case type_str
      when "text/html"
        mime_found = true
        return erb(:index, locals: { res: data }), type_str
      when 'text/json', 'application/json'
        mime_found = true
        return data.to_json, type_str
      when 'text/xml', 'application/xml', "application/xhtml+xml"
        mime_found = true
        return data.to_ary.to_xml(:root => params[:table_name]), type_str
      end
    end
    raise Exception, "Данный тип MIME не поддерживается" unless mime_found
  end
end