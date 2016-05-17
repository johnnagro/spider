require File.dirname(__FILE__)+'/spider/spider_instance'

# A spidering library for Ruby. Handles robots.txt, scraping, finding more
# links, and doing it all over again.
class Spider

  VERSION_INFO = [0, 5, 1] unless defined?(self::VERSION_INFO)
  VERSION = VERSION_INFO.map(&:to_s).join('.') unless defined?(self::VERSION)

  def self.version
    VERSION
  end

  # Runs the spider starting at the given URL. Also takes a block that is given
  # the SpiderInstance. Use the block to define the rules and handlers for
  # the discovered Web pages. See SpiderInstance for the possible rules and
  # handlers.
  #
  #  Spider.start_at('http://cashcats.biz/') do |s|
  #    s.add_url_check do |a_url|
  #      a_url =~ %r{^http://cashcats.biz.*}
  #    end
  #
  #    s.on 404 do |a_url, resp, prior_url|
  #      puts "URL not found: #{a_url}"
  #    end
  #
  #    s.on :success do |a_url, resp, prior_url|
  #      puts "body: #{resp.body}"
  #    end
  #
  #    s.on :every do |a_url, resp, prior_url|
  #      puts "URL returned anything: #{a_url} with this code #{resp.code}"
  #    end
  #  end

  def self.start_at(a_url, &block)
    rules    = RobotRules.new("Ruby Spider #{Spider::VERSION}")
    a_spider = SpiderInstance.new({nil => [a_url]}, [], rules, [])
    block.call(a_spider)
    a_spider.start!
  end
end
