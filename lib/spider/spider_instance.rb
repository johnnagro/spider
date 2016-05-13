# Specialized spidering rules.

require File.dirname(__FILE__)+'/robot_rules.rb'
require 'open-uri'
require 'uri'
require 'net/http'
require 'net/https'

module Net #:nodoc:
  class HTTPResponse #:nodoc:
    def success?; false; end
    def redirect?; false; end
  end
  class HTTPSuccess #:nodoc:
    def success?; true; end
  end
  class HTTPRedirection #:nodoc:
    def redirect?; true; end
  end
end

class NilClass #:nodoc:
  def merge(h); h; end
end

class SpiderInstance
  def initialize(next_urls, seen = [], rules = nil, robots_seen = []) #:nodoc:
    @url_checks  = []
    @cache       = :memory
    @callbacks   = {}
    @next_urls   = [next_urls]
    @seen        = seen
    @rules       = rules || RobotRules.new("Ruby Spider #{Spider::VERSION}")
    @robots_seen = robots_seen
    @headers     = {}
    @setup       = nil
    @teardown    = nil
  end

  # Add a predicate that determines whether to continue down this URL's path.
  # All predicates must be true in order for a URL to proceed.
  #
  # Takes a block that takes a string and produces a boolean. For example, this
  # will ensure that the URL starts with 'http://cashcats.biz':
  #
  #  add_url_check { |a_url| a_url =~ %r{^http://cashcats.biz.*}
  def add_url_check(&block)
    @url_checks << block
  end

  # The Web is a graph; to avoid cycles we store the nodes (URLs) already
  # visited. The Web is a really, really, really big graph; as such, this list
  # of visited nodes grows really, really, really big.
  #
  # Change the object used to store these seen nodes with this. The default
  # object is an instance of Array. Available with Spider is a wrapper of
  # memcached.
  #
  # You can implement a custom class for this; any object passed to
  # check_already_seen_with must understand just << and included? .
  #
  #  # default
  #  check_already_seen_with Array.new
  #
  #  # memcached
  #  require 'spider/included_in_memcached'
  #  check_already_seen_with IncludedInMemcached.new('localhost:11211')
  def check_already_seen_with(cacher)
    if cacher.respond_to?(:<<) && cacher.respond_to?(:include?)
      @seen = cacher
    else
      raise ArgumentError, 'expected something that responds to << and included?'
    end
  end

  # The Web is a really, really, really big graph; as such, this list
  # of nodes to visit grows really, really, really big.
  #
  # Change the object used to store nodes we have yet to walk. The default
  # object is an instance of Array. Available with Spider is a wrapper of
  # AmazonSQS.
  #
  # You can implement a custom class for this; any object passed to
  # check_already_seen_with must understand just push and pop .
  #
  #  # default
  #  store_next_urls_with Array.new
  #
  #  # AmazonSQS
  #  require 'spider/next_urls_in_sqs'
  #  store_next_urls_with NextUrlsInSQS.new(AWS_ACCESS_KEY, AWS_SECRET_ACCESS_KEY, queue_name)
  def store_next_urls_with(a_store)
    tmp_next_urls = @next_urls
    @next_urls = a_store
    tmp_next_urls.each do |a_url_hash|
      @next_urls.push a_url_hash
    end
  end

  # Add a response handler. A response handler's trigger can be :every,
  # :success, :failure, or any HTTP status code. The handler itself can be
  # either a Proc or a block.
  #
  # The arguments to the block are: the URL as a string, an instance of
  # Net::HTTPResponse, and the prior URL as a string.
  #
  #
  # For example:
  #
  #  on 404 do |a_url, resp, prior_url|
  #    puts "URL not found: #{a_url}"
  #  end
  #
  #  on :success do |a_url, resp, prior_url|
  #    puts a_url
  #    puts resp.body
  #  end
  #
  #  on :every do |a_url, resp, prior_url|
  #    puts "Given this code: #{resp.code}"
  #  end
  def on(code, p = nil, &block)
    f = p ? p : block
    case code
    when Fixnum
      @callbacks[code] = f
    else
      @callbacks[code.to_sym] = f
    end
  end

  # Run before the HTTP request. Given the URL as a string.
  #  setup do |a_url|
  #    headers['Cookies'] = 'user_id=1;admin=true'
  #  end
  def setup(p = nil, &block)
    @setup = p ? p : block
  end

  # Run last, once for each page. Given the URL as a string.
  def teardown(p = nil, &block)
    @teardown = p ? p : block
  end

  # Use like a hash:
  #  headers['Cookies'] = 'user_id=1;password=btrross3'
  def headers
    HeaderSetter.new(self)
  end

  def raw_headers #:nodoc:
    @headers
  end
  def raw_headers=(v) #:nodoc:
    @headers = v
  end

  # Reset the headers hash.
  def clear_headers
    @headers = {}
  end

  def start! #:nodoc:
    interrupted = false
    trap("SIGINT") { interrupted = true }
    begin
      next_urls = @next_urls.pop
      tmp_n_u = {}
      next_urls.each do |prior_url, urls|
        urls = [urls] unless urls.kind_of?(Array)
        urls.map do |a_url|
          [a_url, (URI.parse(a_url) rescue nil)]
        end.select do |a_url, parsed_url|
          allowable_url?(a_url, parsed_url)
        end.each do |a_url, parsed_url|
          @setup.call(a_url) unless @setup.nil?
          get_page(parsed_url) do |response|
            do_callbacks(a_url, response, prior_url)
            #tmp_n_u[a_url] = generate_next_urls(a_url, response)
            #@next_urls.push tmp_n_u
            generate_next_urls(a_url, response).each do |a_next_url|
              @next_urls.push a_url => a_next_url
            end
            #exit if interrupted
          end
          @teardown.call(a_url) unless @teardown.nil?
          exit if interrupted
        end
      end
    end while !@next_urls.empty?
  end

  def success_or_failure(code) #:nodoc:
    if code > 199 && code < 300
      :success
    else
      :failure
    end
  end

  def allowable_url?(a_url, parsed_url) #:nodoc:
    !parsed_url.nil? && !@seen.include?(parsed_url) && allowed?(a_url, parsed_url) &&
      @url_checks.map{|url_check|url_check.call(a_url)}.all?
  end

  # True if the robots.txt for that URL allows access to it.
  def allowed?(a_url, parsed_url) # :nodoc:
    return false unless ['http','https'].include?(parsed_url.scheme)
    u = "#{parsed_url.scheme}://#{parsed_url.host}:#{parsed_url.port}/robots.txt"
    parsed_u = URI.parse(u)
    return false unless @url_checks.map{|url_check|url_check.call(a_url)}.all?
    begin
      unless @robots_seen.include?(u)
        #open(u, 'User-Agent' => 'Ruby Spider',
        #  'Accept' => 'text/html,text/xml,application/xml,text/plain', :ssl_verify => false) do |url|
        #  @rules.parse(u, url.read)
        #end
        get_page(parsed_u) do |r|
          @rules.parse(u, r.body)
        end
        @robots_seen << u
      end
      @rules.allowed?(a_url)
    rescue OpenURI::HTTPError
      true # No robots.txt
    rescue Exception, Timeout::Error # to keep it from crashing
      false
    end
  end

  def get_page(parsed_url, &block) #:nodoc:
    @seen << parsed_url
    begin
      http = Net::HTTP.new(parsed_url.host, parsed_url.port)
      if parsed_url.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      # Uses start because http.finish cannot be called.
      r = http.start {|h| h.request(Net::HTTP::Get.new(parsed_url.request_uri, @headers))}
      if r.redirect?
        get_page(URI.parse(construct_complete_url(parsed_url,r['Location'])), &block)
      else
        block.call(r)
      end
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError => e
      p e
      nil
    end
  end

  def do_callbacks(a_url, resp, prior_url) #:nodoc:
    cbs = [@callbacks[:every],
      resp.success? ?  @callbacks[:success] : @callbacks[:failure],
      @callbacks[resp.code]]

    cbs.each do |cb|
      cb.call(a_url, resp, prior_url) if cb
    end
  end

  def generate_next_urls(a_url, resp) #:nodoc:
    web_page = resp.body
    base_url = (web_page.scan(/base\s+href="(.*?)"/i).flatten +
                [a_url[0,a_url.rindex('/')]])[0]
    base_url = remove_trailing_slash(base_url)
    web_page.scan(/href="(.*?)"/i).flatten.map do |link|
      begin
        parsed_link = URI.parse(link)
        if parsed_link.fragment == '#'
          nil
        else
          construct_complete_url(base_url, link, parsed_link)
        end
      rescue
        nil
      end
    end.compact
  end

  def construct_complete_url(base_url, additional_url, parsed_additional_url = nil) #:nodoc:
    parsed_additional_url ||= URI.parse(additional_url)
    case parsed_additional_url.scheme
      when nil
        u = base_url.is_a?(URI) ? base_url : URI.parse(base_url)
        if additional_url[0].chr == '/'
          "#{u.scheme}://#{u.host}#{additional_url}"
        elsif u.path.nil? || u.path == ''
          "#{u.scheme}://#{u.host}/#{additional_url}"
        elsif u.path[0].chr == '/'
          "#{u.scheme}://#{u.host}#{u.path}/#{additional_url}"
        else
          "#{u.scheme}://#{u.host}/#{u.path}/#{additional_url}"
        end
    else
      additional_url
    end
  end

  def remove_trailing_slash(s) #:nodoc:
    s.sub(%r{/*$},'')
  end

  class HeaderSetter #:nodoc:
    def initialize(si)
      @si = si
    end
    def []=(k,v)
      @si.raw_headers = @si.raw_headers.merge({k => v})
    end
  end
end
