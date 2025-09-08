require 'rubygems'

require File.expand_path('../lib/spider', __FILE__)

Gem::Specification.new do |s|
  s.author = 'John Nagro'
  s.email = 'john.nagro@gmail.com'
  s.license = 'MIT'
  s.homepage = 'https://github.com/johnnagro/spider'
  s.required_ruby_version = '>= 2.5'
  s.name = 'spider'
  s.summary = 'A Web spidering library'
  s.files = Dir['lib/**/*'] + ['VERSION']
  s.require_path = 'lib'
  s.description = <<-EOF
A Web spidering library: handles robots.txt, scraping, finding more
links, and doing it all over again.
EOF
  s.metadata["source_code_uri"] = s.homepage
  s.metadata["changelog_uri"] = "#{s.homepage}/blob/main/CHANGELOG.md"
  s.version = Spider::VERSION
end
