#$:.unshift(File.join(File.dirname(__FILE__), 'lib'))

Gem::Specification.new do |s|
  s.name        = 'beanstream'
  s.version     = '1.0.0'
  s.date        = '2015-11-19'
  s.summary     = "Beanstream Ruby SDK"
  s.description = "Accept payments using Beanstream and Ruby"
  s.authors     = ["Brent Owens", "Colin Walker", "Tom Mengda"]
  s.email       = 'bowens@beanstream.com'
  s.homepage    ='http://developer.beanstream.com'
  s.license     = 'MIT'

  s.files = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_dependency('rest-client', '~> 2.0')
  s.add_dependency('json', '>= 1.8.1')

  s.add_development_dependency('shoulda', '~> 3.4.0')
  s.add_development_dependency('test-unit')
  s.add_development_dependency('rake')
end
