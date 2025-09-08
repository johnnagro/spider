# Use memcached to track cycles.

require 'dalli'

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
  # Construct a new IncludedInMemcached instance. The first argument should be
  # the memcached server address (e.g., 'localhost:11211'). Additional options
  # can be passed as a hash (see Dalli::Client documentation).
  def initialize(server, options = {})
    @c = Dalli::Client.new(server, options)
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
