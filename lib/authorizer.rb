class Authorizer < Object
  
  # Необходимо переопределить в классе-потомке
  def has_permission?(auth_info)
    return true
  end
  
  def authorize!(auth_info)
    raise Exception, "У вас нет прав для выполнения этого действия" unless has_permission?(auth_info)
  end
  
end