class App < Sinatra::Base
  
  table_route_data = ['/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html']]
  
  before table_route_data[0] do
    halt 404 unless params[:table_name][VALID_SQL_NAME_REGEXP] == params[:proc_name]
  end
  
  get *table_route_data do
    select_manager = Arel::SelectManager.new(ActiveRecord::Base)
    table = Arel::Table.new(params[:table_name])
    
    condition = HashToSql::create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (params[:q] ? params[:q].clone : nil),
      'and') if params[:id] || params[:q]
    
    select_list = params[:s] ? HashToSql::create_select_list(table, params[:s].clone) : Arel.star
    
    select_manager = table
    select_manager = select_manager.where(condition) if condition
    select_manager = select_manager.project(select_list)
    select_manager = select_manager.order(HashToSql::create_order_list(params[:order])) if params[:order]
    select_manager = select_manager.take(params[:limit] || HashToSql::SELECT_LIMIT) if params[:limit] || params[:limitless].nil?
    sql = select_manager.to_sql
    
    raw_data = ActiveRecord::Base.connection.select_all(sql)
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
  
  post '/tables/:table_name.?:format?', provides: ['json', 'xml', 'html'] do
    body_data = get_body_data_from_request
    
    if body_data.nil? || body_data.empty?
      content_type request.accept.first
      halt
    else
      body_data
    end
    
    table = Arel::Table.new(params[:table_name])
    
    primary_key = table.primary_key
    
    insert_list = HashToSql::create_insert_list(table, body_data["data"])
    
    if primary_key
      ids = []
      
      insert_list.each do |insert_row|
        insert_manager = Arel::InsertManager.new(ActiveRecord::Base)
        insert_manager.insert(insert_row)
        sql = insert_manager.to_sql
        ids << ActiveRecord::Base.connection.insert(sql)
      end
      
      get_content_for_ids(table, ids)
    else
      sql = []
      insert_list.each do |insert_row|
        insert_manager = Arel::UpdateManager.new(ActiveRecord::Base)
        insert_manager.insert(insert_row)
        insert_manager.where(condition) if condition
        sql << update_manager.to_sql
      end
      ActiveRecord::Base.connection.insert(sql.join(';\n'))
      content_type request.accept.first
      nil
    end
  end
  
  put *table_route_data do
    body_data = get_body_data_from_request
    
    if body_data.nil? || body_data.empty?
      content_type request.accept.first
      halt
    else
      body_data
    end
    
    table = Arel::Table.new(params[:table_name])
    
    condition = HashToSql::create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (body_data["q"] ? body_data["q"].clone : nil),
      'and') if params[:id] || body_data["q"]
    
    ids = nil
    primary_key = table.primary_key.name
    if params[:id]
      ids = [params[:id]] 
    else
      select_manager = table
      select_manager = select_manager.where(condition) if condition
      select_manager = select_manager.project(table[primary_key])
      key_res = ActiveRecord::Base.connection.select_all(select_manager.to_sql)
      ids = key_res.rows.map{ |v| v.first }
    end
    
    update_list = HashToSql::create_update_list(table, body_data["data"])
    
    update_manager = Arel::UpdateManager.new(ActiveRecord::Base)
    update_manager.table(table)
    update_manager.set(update_list)
    update_manager.where(condition) if condition
    sql = update_manager.to_sql
    
    ActiveRecord::Base.connection.update(sql)
    if ids && !ids.empty?
      get_content_for_ids(table, ids)
    else
      content_type request.accept.first
      nil
    end
  end
  
  delete *table_route_data do
    delete_manager = Arel::DeleteManager.new(ActiveRecord::Base)
    table = Arel::Table.new(params[:table_name])
    
    condition = HashToSql::create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (params[:q] ? params[:q].clone : nil),
      'and') if params[:id] || params[:q]
    
    delete_manager.from(table)
    delete_manager.where(condition) if condition
    sql = delete_manager.to_sql
    
    ActiveRecord::Base.connection.delete(sql)
    content_type request.accept.first
    nil
  end
  
  private
  def get_records_by_ids(table, ids)
    primary_key = table.primary_key.name
    select_manager = table
    select_manager = select_manager.project(Arel.star)
    select_manager = select_manager.where(table[primary_key].in(ids))
    sql = select_manager.to_sql
    ActiveRecord::Base.connection.select_all(sql)
  end
  
  def get_content_for_ids(table, ids)
    raw_data = get_records_by_ids(table, ids)
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
