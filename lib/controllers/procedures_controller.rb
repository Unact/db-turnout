class ProceduresController < Sinatra::Base
  include Helpers
  
  def initialize(app, options = {})
    @app = app
    
    prefix ||= options[:prefix]
    postprocess_block = options[:postprocess_block]
    
    proc_route_data = ["#{prefix}/:proc_name.?:format?", provides: PROVIDES_ARRAY]
    
    self.class.before proc_route_data[0] do
      @proc_name = ActiveRecord::Base.connection.quote_table_name params[:proc_name]
    end
    
    self.class.get *proc_route_data do
      params_list = Sql::get_proc_params_from_object(params[:p])
      generate_output(params_list)
    end
    
    self.class.post *proc_route_data do
      params_list = get_proc_params_from_body
      generate_output(params_list)
    end
    
    self.class.put *proc_route_data do
      params_list = get_proc_params_from_body
      generate_output(params_list)
    end
    
    self.class.delete *proc_route_data do
      params_list = Sql::get_proc_params_from_object(params[:p])
      ActiveRecord::Base.connection.execute("call #{@proc_name}(#{params_list.join(', ')})")
      content_type request.accept.first
      nil
    end
    
    super @app
  end
  
  private
  def get_proc_params_from_body
    body_data = get_body_data_from_request
    
    Sql::get_proc_params_from_object(body_data["p"])
  end
  
  def generate_output(params_list, postprocess_block)
    raw_data = ActiveRecord::Base.connection.select_all("call #{@proc_name}(#{params_list.join(', ')})")
    raw_data = postprocess_block.call(raw_data, request) if postprocess_block
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
