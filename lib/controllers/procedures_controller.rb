class ProceduresController < Sinatra::Base
  def initialize(app, options = {})
    app.include Helpers
    
    prefix = options[:prefix]
    postprocess_block = options[:postprocess_block]
    
    proc_route_data = "#{prefix}/:proc_name.?:format?"
    
    app.get *proc_route_data do
      params_list = Sql::get_proc_params_from_object(params[:p])
      generate_proc_output(params_list, params[:proc_name], postprocess_block)
    end
    
    app.post *proc_route_data do
      params_list = get_proc_params_from_body
      generate_proc_output(params_list, params[:proc_name], postprocess_block)
    end
    
    app.put *proc_route_data do
      params_list = get_proc_params_from_body
      generate_proc_output(params_list, params[:proc_name], postprocess_block)
    end
    
    app.delete *proc_route_data do
      params_list = Sql::get_proc_params_from_object(params[:p])
      ActiveRecord::Base.connection.execute(
        "call #{ActiveRecord::Base.connection.quote_table_name proc_name}(#{params_list.join(', ')})")
      content_type request.accept.first
      nil
    end
  end
end
