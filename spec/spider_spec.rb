require File.dirname(__FILE__)+'/spec_helper'
local_require 'spider', 'spider/included_in_memcached'

describe 'Spider' do
  it 'should find two pages without cycles using defaults' do
    u = []
    with_web_server(LoopingServlet) do
      u = find_pages_with_static_server
    end
    u.should be_static_server_pages
  end

  it 'should find two pages without cycles using memcached' do
    u = []
    with_web_server(LoopingServlet) do
      with_memcached do
        u = find_pages_with_static_server do |s|
          s.check_already_seen_with IncludedInMemcached.new('localhost:11211')
        end
      end
    end
    u.should be_static_server_pages
  end

  def find_pages_with_static_server(&block)
    pages = []
    Spider.start_at('http://localhost:8888/') do |s|
      block.call(s) unless block.nil?
      s.on(:every){ |u,r,p| pages << u }
    end
    pages
  end
end
