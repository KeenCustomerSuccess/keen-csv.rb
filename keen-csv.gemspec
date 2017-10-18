Gem::Specification.new do |s|
  s.name        = 'keen-csv'
  s.version     = '0.0.1'
  s.date        = '2017-10-17'
  s.summary     = "CSV output for Keen IO"
  s.description = "Builds a CSV string from a Keen IO response"
  s.authors     = ["Jevon Wild"]
  s.email       = 'jevon@keenio'
  s.files       = ["lib/keen-csv.rb", "lib/keen/query_wrapper.rb"]
  s.homepage    = 'http://rubygems.org/gems/hola'
  s.license     = 'MIT'

  s.add_runtime_dependency 'keen'
end
