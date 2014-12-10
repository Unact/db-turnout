class App < Sinatra::Base
  
  get '/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html'] do
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
  
  post '/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html'] do
    insert_manager = Arel::InsertManager.new(ActiveRecord::Base)
    table = Arel::Table.new(params[:table_name])
    primary_key = table.primary_key
    
    insert_list = HashToSql::create_insert_list(table, params[:data])
    
    if primary_key
      
    else
      insert_manager.table(table)
      sql = insert_manager.to_sql
      
      id = ActiveRecord::Base.connection.insert(sql)
      content_type request.accept.first
    end
  end
  
  put '/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html'] do
    body_data_str = request.body.read
    parser = Nori.new
    body_data = parser.parse(body_data_str)
    if body_data.nil? || body_data.length!=1
      raise Exception, "Неверный вид параметров"
    end
    body_data = body_data.first[1]
    
    table = Arel::Table.new(params[:table_name])
    
    condition = HashToSql::create_condition(
      table,
      nil,
      params[:id] ? { id_eq: params[:id] } : (body_data["q"] ? body_data["q"].clone : nil),
      'and') if params[:id] || body_data["q"]
    
    ids = nil
    primary_key = nil
    if params[:id]
      ids = [params[:id]]
      primary_key = "id" 
    else
      primary_key = table.primary_key.name
      select_manager = table
      select_manager = select_manager.where(condition) if condition
      select_manager = select_manager.project(table[primary_key])
      key_res = ActiveRecord::Base.connection.select_all(select_manager.to_sql)
      ids = key_res.rows.map{ |v| v.first }
    end
    
    update_list = HashToSql::create_update_list(table, body_data["data"])
    
    sql = []
    update_list.each do |update_row|
      update_manager = Arel::UpdateManager.new(ActiveRecord::Base)
      update_manager.table(table)
      update_manager.set(update_list)
      update_manager.where(condition) if condition
      sql << update_manager.to_sql
    end
    
    ActiveRecord::Base.connection.update(sql.join(';\n'))
    
    if ids && !ids.empty?
      select_manager = table
      select_manager = select_manager.project(Arel.star)
      select_manager = select_manager.where(table[primary_key].in(ids))
      sql = select_manager.to_sql
      raw_data = ActiveRecord::Base.connection.select_all(sql)
      data, type_str = generate_acceptable_output(raw_data)
      content_type(type_str)
      data
    else
      content_type request.accept.first
    end
  end
  
  delete '/tables/:table_name/?:id?.?:format?', provides: ['json', 'xml', 'html'] do
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
  end
end
