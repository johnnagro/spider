require 'rubygems'
require 'minitest/autorun'
require 'minitest/mock'
require 'webrick'
require_relative 'mock_memcached'
require_relative 'mock_redis'

def local_require(*files)
  files.each do |file|
    require File.dirname(__FILE__)+'/../lib/'+file
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

def with_memcached(use_real: false)
  if use_real
    # Use real memcached for integration tests
    system('memcached -d -P /tmp/spider-memcached.pid')
    sleep 0.5  # Give memcached time to start
    begin
      yield
    ensure
      system('kill -KILL `cat /tmp/spider-memcached.pid`') if File.exist?('/tmp/spider-memcached.pid')
    end
  else
    # Use mock memcached for fast unit tests
    yield
  end
end

def static_server_pages
  ['http://localhost:8888/', 'http://localhost:8888/foo']
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

class NotFoundServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 404
    res['Content-type'] = 'text/plain'
    res.body = "Not Found"
  end
end

class SuccessServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 200
    res['Content-type'] = 'text/html'
    res.body = "<html><body>Success</body></html>"
  end
end

class JsonServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 200
    res['Content-type'] = 'application/json'
    res.body = '{"data": "<a href=\"/test\">Test Link</a>", "message": "This should not extract links"}'
  end
end

class PlainTextServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 200
    res['Content-type'] = 'text/plain'
    res.body = "Plain text content with <a href=\"/test\">fake link</a> that should not be extracted"
  end
end

class HtmlWithLinksServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 200
    res['Content-type'] = 'text/html'
    res.body = <<-HTML
      <html>
        <head><title>Test Page</title></head>
        <body>
          <a href="/page1">Page 1</a>
          <a href="/page2">Page 2</a>
          <a href="http://external.com/page">External</a>
        </body>
      </html>
    HTML
  end
end

class NoContentTypeServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.status = 200
    # No content-type header set
    res.body = '<html><body><a href="/nocontenttype">Link</a></body></html>'
  end
end

def null_logger
  logger = Object.new
  def logger.method_missing(method, *args, &block)
    case method.to_s
    when /\?\z/
      false
    else
      nil
    end
  end
  def logger.respond_to_missing?(method_name, include_private = false)
    true
  end
  logger
end

# Helper methods for memcached tests
def before_specing_memcached
  begin
    local_require 'spider/included_in_memcached'
    system('memcached -d -P /tmp/spider-memcached.pid')
  rescue LoadError => e
    skip "Memcached tests require 'dalli' gem: #{e.message}"
  end
end

def after_specing_memcached
  system('kill -KILL `cat /tmp/spider-memcached.pid`') if File.exist?('/tmp/spider-memcached.pid')
end

# Helper methods for redis tests
def before_specing_redis
  begin
    local_require 'spider/included_in_redis'
    system('redis-server 127.0.0.1:6379')
  rescue LoadError => e
    skip "Redis tests require 'redis' gem: #{e.message}"
  end
end

def after_specing_redis
  system('kill -KILL `pidof redis-server`')
end
