require 'rubygems'

spec = Gem::Specification.new do |s|
  s.author = 'John Nagro'
  s.email = 'john.nagro@gmail.com'
  s.has_rdoc = true
  s.homepage = 'https://github.com/johnnagro/spider'
  s.name = 'spider'
  s.rubyforge_project = 'spider'
  s.summary = 'A Web spidering library'
  s.files = Dir['**/*'].delete_if { |f| f =~ /(cvs|gem|svn)$/i }
  s.require_path = 'lib'
  s.description = <<-EOF
A Web spidering library: handles robots.txt, scraping, finding more
links, and doing it all over again.
EOF
  s.version = Spider::VERSION
end
