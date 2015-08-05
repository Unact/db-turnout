class TablesController < Sinatra::Base
  include Helpers
  
  def initialize(app, options = {})
    @app = app
    
    prefix ||= options[:prefix]
    postprocess_block = options[:postprocess_block]
    
    table_route_data = "#{prefix}/:table_name/?:id?.?:format?"
    
    self.class.before table_route_data do
      @table_name = ActiveRecord::Base.connection.quote_table_name params[:table_name]
    end
    
    self.class.get *table_route_data do
      select_manager = Arel::SelectManager.new(ActiveRecord::Base)
      table = Arel::Table.new(@table_name)
      
      condition = Sql::create_condition(
        table,
        nil,
        params[:id] ? { "id_eq" => params[:id] } : (params[:q] ? params[:q].clone : nil),
        'and') if params[:id] || params[:q]
      
      select_list = params[:s] ? Sql::create_select_list(table, params[:s].clone) : Arel.star
      
      select_manager = table
      select_manager = select_manager.where(condition) if condition
      select_manager = select_manager.project(select_list)
      select_manager = select_manager.order(Sql::create_order_list(params[:order])) if params[:order]
      select_manager = select_manager.take(params[:limit].to_i || Sql::SELECT_LIMIT) if params[:limit] || params[:limitless].nil?
      sql = select_manager.to_sql
      
      raw_data = ActiveRecord::Base.connection.select_all(sql)
      raw_data = postprocess_block.call(raw_data, request) if postprocess_block
      data, type_str = generate_acceptable_output(raw_data)
      content_type(type_str)
      data
    end
    
    self.class.post *table_route_data do
      body_data = get_body_data_from_request
      
      if body_data.nil? || body_data.empty?
        content_type request.accept.first
        halt
      else
        body_data
      end
      
      table = Arel::Table.new(@table_name)
      
      primary_key = ActiveRecord::Base.connection.primary_key params[:table_name]
      
      insert_list = Sql::create_insert_list(table, body_data["data"])
      
      if primary_key.nil? || params[:silent]
        sql = []
        insert_list.each do |insert_row|
          insert_manager = Arel::InsertManager.new(ActiveRecord::Base)
          insert_manager.insert(insert_row)
          sql << insert_manager.to_sql
        end
        ActiveRecord::Base.connection.insert(sql.join(';\n'))
        content_type request.accept.first
        nil
      else
        ids = []
        
        insert_list.each do |insert_row|
          insert_manager = Arel::InsertManager.new(ActiveRecord::Base)
          insert_manager.insert(insert_row)
          sql = insert_manager.to_sql
          ids << ActiveRecord::Base.connection.insert(sql)
        end
        
        get_content_for_ids(table, ids, postprocess_block)
      end
    end
    
    self.class.put *table_route_data do
      body_data = get_body_data_from_request
      
      if body_data.nil? || body_data.empty?
        content_type request.accept.first
        halt
      else
        body_data
      end
      
      table = Arel::Table.new(@table_name)
      
      primary_key = ActiveRecord::Base.connection.primary_key params[:table_name]
      
      condition = Sql::create_condition(
        table,
        nil,
        params[:id] ? { "#{primary_key ? primary_key : 'id'}_eq" => params[:id] } : (body_data["q"] ? body_data["q"].clone : nil),
        'and') if params[:id] || body_data["q"]
      
      ids = nil
      
      if params[:id]
        ids = [params[:id]] 
      else
        select_manager = table
        select_manager = select_manager.where(condition) if condition
        select_manager = select_manager.project(table[primary_key])
        key_res = ActiveRecord::Base.connection.select_all(select_manager.to_sql)
        ids = key_res.rows.map{ |v| v.first }
      end
      
      update_list = Sql::create_update_list(table, body_data["data"])
      
      update_manager = Arel::UpdateManager.new(ActiveRecord::Base)
      update_manager.table(table)
      update_manager.set(update_list)
      update_manager.where(condition) if condition
      sql = update_manager.to_sql
      
      ActiveRecord::Base.connection.update(sql)
      if ids && !ids.empty? && !params[:silent]
        get_content_for_ids(table, ids, postprocess_block)
      else
        content_type request.accept.first
        nil
      end
    end
    
    self.class.delete *table_route_data do
      delete_manager = Arel::DeleteManager.new(ActiveRecord::Base)
      table = Arel::Table.new(@table_name)
      
      condition = Sql::create_condition(
        table,
        nil,
        params[:id] ? { "id_eq" => params[:id] } : (params[:q] ? params[:q].clone : nil),
        'and') if params[:id] || params[:q]
      
      delete_manager.from(table)
      delete_manager.where(condition) if condition
      sql = delete_manager.to_sql
      
      ActiveRecord::Base.connection.delete(sql)
      content_type request.accept.first
      nil
    end
    
    super @app
  end
  
  private
  def get_records_by_ids(table, ids)
    p params[:table_name]
    primary_key = ActiveRecord::Base.connection.primary_key params[:table_name]
    p primary_key
    select_manager = table
    select_manager = select_manager.project(Arel.star)
    select_manager = select_manager.where(table[primary_key].in(ids))
    sql = select_manager.to_sql
    ActiveRecord::Base.connection.select_all(sql)
  end
  
  def get_content_for_ids(table, ids, postprocess_block)
    raw_data = get_records_by_ids(table, ids)
    raw_data = postprocess_block.call(raw_data, request) if postprocess_block
    data, type_str = generate_acceptable_output(raw_data)
    content_type(type_str)
    data
  end
end
