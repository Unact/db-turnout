require 'active_record'
require 'active_support'
require 'controllers'
require 'helpers'
require 'sql'

module DbTurnout
  include Helpers
  include BaseController
  include ProceduresController
  include TablesController
end
