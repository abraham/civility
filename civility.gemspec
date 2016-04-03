Gem::Specification.new do |s|
  s.name          = 'civility'
  s.version       = '3'
  s.summary       = 'The easiest way to manage your Civ5 hotseat games on GMR'
  s.description   = 'Civility is the easiest way to manage your Civ5 hotseat games hosted on Giant Multiplayer Robot'
  s.authors       = ['Abraham Williams']
  s.email         = 'abraham@abrah.am'
  s.files         = ['lib/civility.rb', 'lib/civility/gmr.rb']
  s.homepage      = 'https://github.com/abraham/civility'
  s.license       = 'MIT'
  s.executables   = ['civility']
  s.require_paths = ['lib']
  s.cert_chain    = ['certs/abraham.pem']
  s.signing_key   = File.expand_path('~/.ssh/gem-private_key.pem') if $0 =~ /gem\z/

  s.add_runtime_dependency('thor', '~> 0')
  s.add_development_dependency('pry', '~> 0')
  s.add_development_dependency('rspec', '~> 3')
  s.add_development_dependency('webmock', '~> 1')
end
