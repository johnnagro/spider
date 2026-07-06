# Mock memcached client for testing - no external dependencies required
class MockMemcached
  def initialize(*args)
    @data = {}
  end

  def add(key, value)
    @data[key] = value unless @data.key?(key)
  end

  def get(key)
    @data[key]
  end

  def flush
    @data.clear
  end

  def set(key, value)
    @data[key] = value
  end

  def delete(key)
    @data.delete(key)
  end
end

# Mock version of IncludedInMemcached that uses MockMemcached
class MockIncludedInMemcached
  def initialize(*args)
    @c = MockMemcached.new(*args)
  end

  def <<(v)
    @c.add(v.to_s, v)
  end

  def include?(v)
    @c.get(v.to_s) == v
  end
end
