class App < Sinatra::Base
  
  get '/procedures/:proc_name.?:format?', provides: ['json', 'xml', 'html'] do
    table = Arel::Table.new(params[:table_name])
    
    condition = create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (params[:q] ? params[:q].clone : nil),
      'and') if params[:id] || params[:q]
    
    select_list = params[:s] ? create_select_list(table, params[:s].clone) : Arel.star
    
    sql = table
    sql = sql.where(condition) if condition
    sql = sql.project(select_list)
    sql = sql.order() if params[:order]
    
    raw_data = ActiveRecord::Base.connection.select_all(sql.to_sql)
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
