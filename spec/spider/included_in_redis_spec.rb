require File.dirname(__FILE__)+'/../spec_helper'

def before_specing_redis
  local_require 'spider/included_in_redis'
  system('redis-server 127.0.0.1:6379')
end

def after_specing_redis
  system('kill -KILL `pidof redis-server`')
end

Spec::Runner.configure { |c| c.mock_with :mocha }

describe 'Object to halt cycles' do
  before do
    before_specing_redis
  end

  it 'should understand <<' do
    c = IncludedInRedis.new(host: 'localhost', port: 6379)
    c.should respond_to(:<<)
  end

  it 'should understand included?' do
    c = IncludedInRedis.new(host: 'localhost', port: 6379)
    c.should respond_to(:include?)
  end

  it 'should produce false if the object is not included' do
    c = IncludedInRedis.new(host: 'localhost', port: 6379)
    c.include?('a').should be_false
  end

  it 'should produce true if the object is included' do
    c = IncludedInRedis.new(host: 'localhost', port: 6379)
    c << 'a'
    c.include?('a').should be_true
  end
  
  after do
    after_specing_redis
  end
end
