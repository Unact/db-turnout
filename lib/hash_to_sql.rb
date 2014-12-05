module HashToSql
  SELECT_LIMIT = 500
  
  LOGICAL_OPERATORS = ['or', 'and']
  
  AREL_PREDICATES = Arel::Predications.public_instance_methods.
    collect { |m| m.to_s }.
    sort! { |p1, p2| p2.length<=>p1.length}
    
  def self.create_order_list(order_params)
    order_hash = {}
    case order_params
    when String
      order_hash[order_params] = "asc"
    when Array
      order_params.each do |column|
        if String===column
          order_hash[column] = "asc"
        else
          raise Exception, "Неверный вид параметра #{column} для списка сортировки."
        end
      end
    when Hash
      order_params.each_pair do |column, order_value|
        case order_value
        when String
          order_hash[column] = "asc"
        when Hash
          order_hash[column] = order_value
        else
          raise Exception, "Неверный вид параметра #{column} для списка сортировки. #{order_value.inspect}"
        end
      end
    else
      raise Exception, "Неверный вид параметров для списка сортировки. #{select_params.inspect}"
    end
    puts *order_hash.inspect
    order_hash
  end
  
  def self.create_select_list(table, select_params)
    select_list = []
    case select_params
    when Array
      select_params.each do |p|
        select_list << get_select_list_element(table, p)
      end
    when Hash
      select_params.each_pair do |column, as_value|
        select_list << table[column].as(as_value)
      end
    else
      raise Exception, "Неверный вид параметров для списка выбора. #{select_params.inspect}"
    end
    
    select_list
  end
  
  def self.get_select_list_element(table, element)
    case element
    when Hash
      select_hash = element.first
      table[select_hash[0]].as(select_hash[1])
    when String
      element
    else
      raise Exception, "Неверный вид параметра для списка выбора. #{element.inspect}"
    end
  end
  
  def self.create_condition(table, condition, condition_hash, operation)
    if Hash===condition_hash
      condition_hash = condition_hash.clone
      first_operation = condition_hash.shift
      
      predicate, field = get_predicate_and_field first_operation[0]
      
      condition = table[field].send(predicate, first_operation[1])
      
      condition_hash.each_pair do |k, v|
        str_key = k.to_s
        if LOGICAL_OPERATORS.include? str_key
          if Hash===v
            condition = condition.send(str_key, create_condition(table, condition, v, str_key))
          end
        else
          predicate, field = get_predicate_and_field str_key
          condition = apply_predicate_with_operation(table, condition, predicate, field, operation, v)
        end
      end
      
      condition
    else
      raise Exception, "Неверный вид параметров для условия. #{condition_hash.inspect}"
    end
  end
    
  def self.apply_predicate_with_operation(table, condition, predicate, field, operation, value)
    condition.send(operation, table[field].send(predicate, value))
  end
  
  def self.get_predicate_and_field(str_key)
    predicate_found = false
    i = 0
    predicate_index = 0
    while !predicate_found && i<AREL_PREDICATES.length
      predicate_index = str_key.rindex AREL_PREDICATES[i]
      predicate_found = (predicate_index + AREL_PREDICATES[i].length)==str_key.length if predicate_index
      i+=1
    end
    if predicate_found
      field = str_key[0..predicate_index - 2]
      return AREL_PREDICATES[i-1], field
    else
      raise Exception, "Неправильный формат ключа. Предикат не найден."
    end
  end
end