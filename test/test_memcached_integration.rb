require_relative "test_helper"

# Integration test for real Dalli/memcached - only runs if memcached is available
class TestMemcachedIntegration < Minitest::Test
  def test_real_memcached_integration
    begin
      local_require "spider/included_in_memcached"
    rescue LoadError => e
      skip "Memcached integration tests require 'dalli' gem: #{e.message}"
    end

    # Test with real memcached if available
    with_memcached(use_real: true) do
      begin
        memcached_client = IncludedInMemcached.new("localhost:11211")
        memcached_client.instance_variable_get(:@c).flush

        # Test basic functionality
        refute memcached_client.include?("test_url")
        memcached_client << "test_url"
        assert memcached_client.include?("test_url")

        # Test with Spider
        pages = []
        with_web_server(LoopingServlet) do
          Spider.start_at("http://localhost:8888/") do |s|
            s.check_already_seen_with memcached_client
            s.on(:every) { |u, r, p| pages << u }
          end
        end

        assert_equal static_server_pages, pages

      rescue Dalli::NetworkError, Dalli::RingError => e
        skip "Real memcached not available: #{e.message}"
      end
    end
  end
end
