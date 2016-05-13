# Copyright 2007-2008 Mike Burns & John Nagro
# :include: README

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#      * Neither the name Mike Burns nor the
#      names of his contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY Mike Burns ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Mike Burns BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require File.dirname(__FILE__)+'/spider/spider_instance'

# A spidering library for Ruby. Handles robots.txt, scraping, finding more
# links, and doing it all over again.
class Spider

  VERSION_INFO = [0, 5, 0] unless defined?(self::VERSION_INFO)
  VERSION = VERSION_INFO.map(&:to_s).join('.') unless defined?(self::VERSION)

  def self.version
    VERSION
  end

  # Runs the spider starting at the given URL. Also takes a block that is given
  # the SpiderInstance. Use the block to define the rules and handlers for
  # the discovered Web pages. See SpiderInstance for the possible rules and
  # handlers.
  #
  #  Spider.start_at('http://mike-burns.com/') do |s|
  #    s.add_url_check do |a_url|
  #      a_url =~ %r{^http://mike-burns.com.*}
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
