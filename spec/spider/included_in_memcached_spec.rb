require File.dirname(__FILE__)+'/../spec_helper'

def before_specing_memcached
  local_require 'spider/included_in_memcached'
  system('memcached -d -P /tmp/spider-memcached.pid')
end

def after_specing_memcached
  system('kill -KILL `cat /tmp/spider-memcached.pid`')
end

Spec::Runner.configure { |c| c.mock_with :mocha }

describe 'Object to halt cycles' do
  before do
    before_specing_memcached
  end

  it 'should understand <<' do
    c = IncludedInMemcached.new('localhost:11211')
    c.should respond_to(:<<)
  end

  it 'should understand included?' do
    c = IncludedInMemcached.new('localhost:11211')
    c.should respond_to(:include?)
  end

  it 'should produce false if the object is not included' do
    c = IncludedInMemcached.new('localhost:11211')
    c.include?('a').should be_false
  end

  it 'should produce true if the object is included' do
    c = IncludedInMemcached.new('localhost:11211')
    c << 'a'
    c.include?('a').should be_true
  end
  
  after do
    after_specing_memcached
  end
end
