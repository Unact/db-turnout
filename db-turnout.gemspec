Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'db-turnout'
  s.version     = '0.1.0'
  s.licenses    = ['MIT']
  s.summary     = "Turnout your database to http"
  s.description = "Use in your Sinatra applications for http rest access to DB"
  s.authors     = ["sov-87"]
  s.email       = 'afetisov87@gmail.com'
  s.files       = [
    "lib/db-turnout.rb",
    "lib/controllers.rb",
    "lib/controllers/base_controller.rb",
    "lib/controllers/procedures_controller.rb",
    "lib/controllers/tables_controller.rb",
    "lib/helpers.rb",
    "lib/sql.rb"]
  s.homepage    = 'https://github.com/sov-87/db-turnout'
  s.required_ruby_version = '>= 2.1.0'
  s.required_rubygems_version = '>= 1.8.11'
  
  s.add_dependency "rack-test"
  s.add_dependency "sinatra-contrib"
  s.add_dependency "activerecord"
  s.add_dependency "activesupport"
  s.add_dependency "rack"
  s.add_dependency "minitest"
end