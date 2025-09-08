# Mock Redis client for testing - no external dependencies required
require 'json'

class MockRedis
  def initialize(*args)
    @data = {}
  end
  
  def set(key, value)
    @data[key] = value
  end
  
  def get(key)
    @data[key]
  end
  
  def flushdb
    @data.clear
  end
  
  def del(key)
    @data.delete(key)
  end
end

# Mock version of IncludedInRedis that uses MockRedis
class MockIncludedInRedis
  def initialize(*args)
    @c = MockRedis.new(*args)
  end
  
  def <<(v)
    @c.set(v.to_s, v.to_json)
  end
  
  def include?(v)
    @c.get(v.to_s) == v.to_json
  end
end
