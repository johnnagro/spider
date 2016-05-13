# Use memcached to track cycles.

require 'memcache'

# A specialized class using memcached to track items stored. It supports
# three operations: new, <<, and include? . Together these can be used to
# add items to the memcache, then determine whether the item has been added.
#
# To use it with Spider use the check_already_seen_with method:
#
#  Spider.start_at('http://example.com/') do |s|
#    s.check_already_seen_with IncludedInMemcached.new('localhost:11211')
#  end
class IncludedInMemcached
  # Construct a new IncludedInMemcached instance. All arguments here are
  # passed to MemCache (part of the memcache-client gem).
  def initialize(*a)
    @c = MemCache.new(*a)
  end

  # Add an item to the memcache.
  def <<(v)
    @c.add(v.to_s, v)
  end

  # True if the item is in the memcache.
  def include?(v)
    @c.get(v.to_s) == v
  end
end
