class App < Sinatra::Base
  
  get '/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html'] do
    table = Arel::Table.new(params[:table_name])
    
    condition = HashToSql::create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (params[:q] ? params[:q].clone : nil),
      'and') if params[:id] || params[:q]
    
    select_list = params[:s] ? HashToSql::create_select_list(table, params[:s].clone) : Arel.star
    
    sql = table
    sql = sql.where(condition) if condition
    sql = sql.project(select_list)
    sql = sql.order(HashToSql::create_order_list(params[:order])) if params[:order]
    #sql = sql.limit(params[:limit] || HashToSql::SELECT_LIMIT) if params[:limit] || params[:limitless].nil?
    @sql = sql.to_sql
    raw_data = ActiveRecord::Base.connection.select_all(@sql)
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
