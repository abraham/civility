Gem::Specification.new do |s|
  s.name          = 'gmr'
  s.version       = '1'
  s.date          = '2016-02-23'
  s.summary       = 'The easiest way to manage your Civ5 hotseat games'
  s.description   = 'GMR is the easiest way to manage your Civ5 hotseat games'
  s.authors       = ['Abraham Williams']
  s.email         = 'abraham@abrah.am'
  s.files         = ["lib/gmr.rb"]
  s.homepage      =
    'http://rubygems.org/gems/gmr'
  s.license       = 'MIT'
  s.executables   = ['gmr']
  s.require_paths = ['lib']

  s.add_runtime_dependency('thor', '~> 0')
end
