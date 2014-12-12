require 'active_record'
require 'active_support'
require 'controllers'
require 'helpers'
require 'sql'

module DbTurnout
  def self.register_all(procedures_path = '/procedures', tables_path = '/tables')
    map(procedures_path) { run ProceduresController }
    map(tables_path) { run TablesController }
  end
end