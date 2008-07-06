# Use memcached to track cycles.
#
# Copyright 2007 Mike Burns
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#      * Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#      notice, this list of conditions and the following disclaimer in the
#      documentation and/or other materials provided with the distribution.
#      * Neither the name Mike Burns nor the
#      names of his contributors may be used to endorse or promote products
#      derived from this software without specific prior written permission.
#  
# THIS SOFTWARE IS PROVIDED BY Mike Burns ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL Mike Burns BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

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
