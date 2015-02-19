class ProceduresController < Sinatra::Base
  include Helpers
  
  proc_route_data = ["/:proc_name.?:format?", provides: PROVIDES_ARRAY]
  
  before proc_route_data[0] do
    halt 404 unless params[:proc_name][VALID_SQL_NAME_REGEXP] == params[:proc_name]
    if params[:owner]
      halt 404 unless params[:owner][VALID_SQL_NAME_REGEXP] == params[:owner]
      @proc_name = "#{params[:owner]}.#{params[:proc_name]}"
      params.delete(:owner)
    else
      @proc_name = params[:proc_name]
    end
  end
  
  get *proc_route_data do
    params_list = Sql::get_proc_params_from_object(params[:p])
    generate_output(params_list)
  end
  
  post *proc_route_data do
    params_list = get_proc_params_from_body
    generate_output(params_list)
  end
  
  put *proc_route_data do
    params_list = get_proc_params_from_body
    generate_output(params_list)
  end
  
  delete *proc_route_data do
    params_list = Sql::get_proc_params_from_object(params[:p])
    ActiveRecord::Base.connection.execute("call #{@proc_name}(#{params_list.join(', ')})")
    content_type request.accept.first
    nil
  end
  
  private
  def get_proc_params_from_body
    body_data = get_body_data_from_request
    
    Sql::get_proc_params_from_object(body_data["p"])
  end
  
  def generate_output(params_list)
    raw_data = ActiveRecord::Base.connection.select_all("call #{@proc_name}(#{params_list.join(', ')})")
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
