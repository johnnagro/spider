
# Spider
_a Web spidering library for Ruby. It handles the robots.txt,
scraping, collecting, and looping so that you can just handle the data._

## Examples

### Crawl the Web, loading each page in turn, until you run out of memory

```ruby
 require 'spider'
 Spider.start_at('http://cashcats.biz/') {}
```

### To handle erroneous responses

```ruby
 require 'spider'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.on :failure do |a_url, resp, prior_url|
     puts "URL failed: #{a_url}"
     puts " linked from #{prior_url}"
   end
 end
```

### Or handle successful responses

```ruby
 require 'spider'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.on :success do |a_url, resp, prior_url|
     puts "#{a_url}: #{resp.code}"
     puts resp.body
     puts
   end
 end
```

### Limit to just one domain

```ruby
 require 'spider'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.add_url_check do |a_url|
     a_url =~ %r{^http://cashcats.biz.*}
   end
 end
```

### Pass headers to some requests

```ruby
 require 'spider'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.setup do |a_url|
     if a_url =~ %r{^http://.*wikipedia.*}
       headers['User-Agent'] = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
     end
   end
 end
```

### Use memcached to track cycles

```ruby
 require 'spider'
 require 'spider/included_in_memcached'
 SERVERS = ['10.0.10.2:11211','10.0.10.3:11211','10.0.10.4:11211']
 Spider.start_at('http://cashcats.biz/') do |s|
   s.check_already_seen_with IncludedInMemcached.new(SERVERS)
 end
```

### Use Redis to track cycles

```ruby
 require 'spider'
 require 'spider/included_in_redis'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.check_already_seen_with IncludedInRedis.new(host: '127.0.0.1', port: 6379)
 end
```

### Use Plain text to track cycles

```ruby
 require 'spider'
 require 'spider/included_in_redis'
 Spider.start_at('http://cashcats.biz/') do |s|
   s.check_already_seen_with IncludedInFile.new('/tmp/cashcats_crawl.txt')
 end
```

### Track cycles with a custom object

```ruby
 require 'spider'
 class ExpireLinks < Hash
   def <<(v)
     self[v] = Time.now
   end
   def include?(v)
     self[v].kind_of?(Time) && (self[v] + 86400) >= Time.now
   end
 end

 Spider.start_at('http://cashcats.biz/') do |s|
   s.check_already_seen_with ExpireLinks.new
 end
```

### Store nodes to visit with Amazon SQS

```ruby
 require 'spider'
 require 'spider/next_urls_in_sqs'
 Spider.start_at('http://cashcats.biz') do |s|
   s.store_next_urls_with NextUrlsInSQS.new(AWS_ACCESS_KEY, AWS_SECRET_ACCESS_KEY)
 end
```

### Store nodes to visit with a custom object

```ruby
 require 'spider'
 class MyArray < Array
   def pop
     super
   end

   def push(a_msg)
     super(a_msg)
   end
 end

 Spider.start_at('http://cashcats.biz') do |s|
   s.store_next_urls_with MyArray.new
 end
```

### Create a URL graph

```ruby
 require 'spider'
 nodes = {}
 Spider.start_at('http://cashcats.biz/') do |s|
   s.add_url_check {|a_url| a_url =~ %r{^http://cashcats.biz.*} }

   s.on(:every) do |a_url, resp, prior_url|
     nodes[prior_url] ||= []
     nodes[prior_url] << a_url
   end
 end
```

### Use a proxy

```ruby
 require 'net/http_configuration'
 require 'spider'
 http_conf = Net::HTTP::Configuration.new(:proxy_host => '7proxies.org',
                                          :proxy_port => 8881)
 http_conf.apply do
   Spider.start_at('http://img.4chan.org/b/') do |s|
     s.on(:success) do |a_url, resp, prior_url|
       File.open(a_url.gsub('/',':'),'w') do |f|
         f.write(resp.body)
       end
     end
   end
 end
```

_Copyright (c) 2007-2016 Spider Team Authors_
