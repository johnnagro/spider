require 'rubygems'
require 'webrick'
require 'spec'

Spec::Runner.configure { |c| c.mock_with :mocha }

def local_require(*files)
  files.each do |file|
    require File.dirname(__FILE__)+'/../lib/'+file
  end
end

class BeStaticServerPages
  def initialize
    @pages = ['http://localhost:8888/', 'http://localhost:8888/foo']
    @actual = nil
  end

  attr :actual, true

  def matches?(actual)
    @actual = actual
    actual == @pages
  end

  def failure_message
    "expected #{@pages.inspect}, got #{@actual.inspect}"
  end

  def description
    "be the pages returned by the static server (#{@pages.inspect})"
  end
end

def with_web_server(svlt)
  server = WEBrick::HTTPServer.new(:Port => 8888, :Logger => null_logger,
                                   :AccessLog => [])
  server.mount('/', svlt)
  Thread.new {server.start}
  begin
    yield
  ensure
    server.shutdown
  end
end

def with_memcached
  system('memcached -d -P /tmp/spider-memcached.pid')
  cacher = IncludedInMemcached.new('localhost:11211')
  begin
    yield
  ensure
    system('kill -KILL `cat /tmp/spider-memcached.pid`')
  end
end

def be_static_server_pages
  BeStaticServerPages.new
end

class QueryServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-type'] = 'text/plain'
    res.body = "response\n"
  end
end

class LoopingServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-type'] = 'text/html'
    if req.path == '/foo'
      res.body = <<-END
      <a href="/">a</a>
      END
    else
      res.body = <<-END
      <a href="/foo">b</a>
      END
    end
  end
end

def null_logger
  l = stub
  [:log, :fatal, :error, :warn , :info, :debug].each do |k|
    l.stubs(k)
    l.stubs("#{k}?".to_sym)
  end
  l
end
