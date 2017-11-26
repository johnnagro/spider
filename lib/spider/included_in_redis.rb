# Use Redis to track cycles.

require 'redis'
require 'json'

# A specialized class using Redis to track items stored. It supports
# three operations: new, <<, and include? . Together these can be used to
# add items to Redis, then determine whether the item has been added.
#
# To use it with Spider use the check_already_seen_with method:
#
#  Spider.start_at('http://example.com/') do |s|
#    s.check_already_seen_with IncludedInRedis.new(host: '127.0.0.1', port: 6379)
#  end
class IncludedInRedis
  # Construct a new IncludedInRedis instance. All arguments here are
  # passed to Redis (part of the redis gem).
  def initialize(*a)
    @c = Redis.new(*a)
  end

  # Add an item to Redis
  def <<(v)
    @c.set(v.to_s, v.to_json)
  end

  # True if the item is in Redis
  def include?(v)
    @c.get(v.to_s) == v.to_json
  end
end
