require_relative "test_helper"

class TestIncludedInMemcached < Minitest::Test
  def setup
    # Use mock memcached for fast, reliable unit tests
    @memcached_client = MockIncludedInMemcached.new("localhost:11211")
  end

  def test_should_understand_append_operator
    assert_respond_to @memcached_client, :<<
  end

  def test_should_understand_include_query
    assert_respond_to @memcached_client, :include?
  end

  def test_should_produce_false_if_object_is_not_included
    refute @memcached_client.include?("test_key_not_present")
  end

  def test_should_produce_true_if_object_is_included
    test_key = "test_key_present"
    @memcached_client << test_key
    assert @memcached_client.include?(test_key)
  end
end
