require_relative "test_helper"

class TestIncludedInRedis < Minitest::Test
  def setup
    # Use mock Redis for fast, reliable unit tests
    @redis_client = MockIncludedInRedis.new(host: "localhost", port: 6379)
  end

  def test_should_understand_append_operator
    assert_respond_to @redis_client, :<<
  end

  def test_should_understand_include_query
    assert_respond_to @redis_client, :include?
  end

  def test_should_produce_false_if_object_is_not_included
    refute @redis_client.include?("test_key_not_present")
  end

  def test_should_produce_true_if_object_is_included
    test_key = "test_key_present"
    @redis_client << test_key
    assert @redis_client.include?(test_key)
  end
end
