# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'nano_api/version'

Gem::Specification.new do |s|
  s.name        = 'nano_api'
  s.version     = NanoApi::VERSION
  s.authors     = ['Alexander Stanko']
  s.email       = ['astanko@aviasales.ru']
  s.homepage    = ''
  s.summary     = %q{Basic client for nano search API}
  s.description = %q{Provide airtickets search for your Rails app, using aviasales.ru and gocheap.travel API}

  s.rubyforge_project = 'nano_api'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rails', '~> 3.2.2'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'jasmine'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'fabrication'
  s.add_development_dependency 'forgery'

  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'addressable'
end
