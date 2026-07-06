require_relative "test_helper"
local_require "spider"

class TestSpider < Minitest::Test
  def test_should_find_two_pages_without_cycles_using_defaults
    u = []
    with_web_server(LoopingServlet) do
      u = find_pages_with_static_server
    end
    assert_equal static_server_pages, u
  end

  def test_should_find_two_pages_without_cycles_using_memcached
    u = []
    with_web_server(LoopingServlet) do
      with_memcached do
        # Use mock memcached for fast, reliable testing
        memcached_client = MockIncludedInMemcached.new("localhost:11211")

        u = find_pages_with_static_server do |s|
          s.check_already_seen_with memcached_client
        end
      end
    end
    assert_equal static_server_pages, u
  end

  private

  def find_pages_with_static_server(&block)
    pages = []
    Spider.start_at("http://localhost:8888/") do |s|
      block.call(s) unless block.nil?
      s.on(:every) { |u, r, p| pages << u }
    end
    pages
  end
end
