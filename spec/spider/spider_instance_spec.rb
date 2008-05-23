require File.dirname(__FILE__)+'/../spec_helper'
require 'webrick'
require 'webrick/https'
local_require 'spider', 'spider/included_in_memcached'

describe 'SpiderInstance' do
  # http://www.rcuk.ac.uk/ redirects to /default.htm, which isn't a complete
  # URL. Bug reported by Henri Cook.
  it 'should construct a complete redirect URL' do
    @response_called = false
    redirected_resp = stub(:redirect? => true,
                          :[] => '/default.htm')
    success_resp = stub(:redirect? => false)
    http_req = stub(:request => true)
    http_mock_redir = stub(:use_ssl= => true)
    http_mock_redir.stubs(:start).yields(http_req).returns(redirected_resp)
    http_mock_success = stub(:use_ssl= => true)
    http_mock_success.stubs(:start).yields(http_req).returns(success_resp)
    Net::HTTP.expects(:new).times(2).returns(http_mock_redir).then.
      returns(http_mock_success)
    si = SpiderInstance.new({nil => ['http://www.rcuk.ac.uk/']})
    si.get_page(URI.parse('http://www.rcuk.ac.uk/')) do |resp|
      @response_called = true
    end
    @response_called.should be_true
  end

  it 'should prevent cycles with an IncludedInMemcached' do
    with_memcached do
      cacher = IncludedInMemcached.new('localhost:11211')
      it_should_prevent_cycles_with(cacher)
    end
  end

  it 'should prevent cycles with an Array' do
    cacher = Array.new
    it_should_prevent_cycles_with(cacher)
  end

  it 'should call the "setup" callback before loading the Web page' do
    mock_successful_http
    @on_called = false
    @before_called = false
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.setup       { |*a| @before_called = Time.now }
    si.on(:every)  { |*a| @on_called = Time.now }
    si.start!
    @on_called.should_not be_false
    @before_called.should_not be_false
    @before_called.should_not be_false
    @before_called.should < @on_called
  end

  it 'should call the "teardown" callback after running all other callbacks' do
    mock_successful_http
    @on_called = false
    @after_called = false
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:every)  { |*a| @on_called = Time.now }
    si.teardown    { |*a| @after_called = Time.now }
    si.start!
    @on_called.should_not be_false
    @after_called.should_not be_false
    @after_called.should_not be_false
    @after_called.should > @on_called
  end

  it 'should pass headers set by a setup handler to the HTTP request' do
    mock_successful_http
    Net::HTTP::Get.expects(:new).with('/foo',{'X-Header-Set' => 'True'})
    si = SpiderInstance.new(nil => ['http://example.com/foo'])
    si.stubs(:allowable_url?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.setup do |a_url|
      si.headers['X-Header-Set'] = 'True'
    end
    si.teardown do |a_url|
      si.clear_headers
    end
    si.start!
  end

  it 'should call the :every callback with the current URL, the response, and the prior URL' do
    mock_successful_http
    callback_arguments_on(:every)
  end

  it 'should call the :success callback with the current URL, the request, and the prior URL' do
    mock_successful_http
    callback_arguments_on(:success)
  end

  it 'should call the :failure callback with the current URL, the request, and the prior URL' do
    mock_failed_http
    callback_arguments_on(:failure)
  end

  it 'should call the HTTP status error code callback with the current URL, the request, and the prior URL' do
    mock_failed_http
    callback_arguments_on(404)
  end

  it 'should call the HTTP status success code callback with the current URL, the request, and the prior URL' do
    mock_successful_http
    callback_arguments_on(200)
  end

  # Bug reported by John Nagro, using the example source http://eons.com/
  # had to change line 192; uses request_uri now instead of path.
  it 'should handle query URLs without a path' do
    u = 'http://localhost:8888?s=1'
    u_p = URI.parse(u)
    @block_called = false
    with_web_server(QueryServlet) do
      si = SpiderInstance.new({nil => [u]})
      si.get_page(u_p) do
        @block_called = true
      end
    end
    @block_called.should be_true
  end

  # This solves a problem reported by John Nagro.
  it 'should handle redirects' do
    u = 'http://example.com/'
    u_p = URI.parse(u)
    @redirect_handled = false
    mock_redirect_http
    si = SpiderInstance.new({nil => [u]})
    si.get_page(u_p) do
      @redirect_handled = true
    end
    @redirect_handled.should be_true
  end

  it 'should handle HTTPS' do
    u = 'https://localhost:10443/'
    u_p = URI.parse(u)
    @page_called = false
    server = WEBrick::HTTPServer.new(:Port => 10443,
                                     :Logger => null_logger,
                                     :AccessLog => [],
                                     :SSLEnable => true,
                                     :SSLCertName => [["O", "ruby-lang.org"], ["OU", "sample"], ["CN", WEBrick::Utils::getservername]],
                                     :SSLComment => 'Comment of some sort')
    server.mount('/', QueryServlet)
    Thread.new {server.start}
    si = SpiderInstance.new({nil => [u]})
    si.get_page(u_p) { @page_called = true }
    server.shutdown
    @page_called.should be_true
  end

  it 'should skip URLs when allowable_url? is false' do
    u = 'http://example.com/'
    u_p = URI.parse(u)
    http_resp = stub(:redirect? => false, :success? => true, :code => 200, :headers => 1, :body => 1)
    Net::HTTP.stubs(:new).returns(stub(:request => http_resp, :finish => nil))
    si = SpiderInstance.new({nil => [u]})
    si.expects(:allowable_url?).with(u, u_p).returns(false)
    si.expects(:get_page).times(0)
    si.start!
  end

  it 'should not skip URLs when allowable_url? is true' do
    u = 'http://example.com/'
    u_p = URI.parse(u)
    http_resp = stub(:redirect? => false, :success? => true, :code => 200, :headers => 1, :body => 1)
    Net::HTTP.stubs(:new).returns(stub(:request => http_resp, :finish => nil))
    si = SpiderInstance.new({nil => [u]})
    si.expects(:allowable_url?).with(u, u_p).returns(true)
    si.expects(:get_page).with(URI.parse(u))
    si.start!
  end

  it 'should disallow URLs when the robots.txt says to' do
    robot_rules = stub
    SpiderInstance.any_instance.expects(:open).
      with('http://example.com:80/robots.txt', 'User-Agent' => 'Ruby Spider',
        'Accept' => 'text/html,text/xml,application/xml,text/plain').
      yields(stub(:read => 'robots.txt content'))
    robot_rules.expects(:parse).with('http://example.com:80/robots.txt',
                                     'robots.txt content')
    robot_rules.expects(:allowed?).with('http://example.com/').returns(false)
    si = SpiderInstance.new({nil => ['http://example.com/']}, [], robot_rules, [])
    allowable = si.allowable_url?('http://example.com/',
                                  URI.parse('http://example.com/'))
    allowable.should be_false
  end

  it 'should disallow URLs when they fail any url_check' do
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.add_url_check { |a_url| false }
    allowable = si.allowable_url?('http://example.com/',
                                  URI.parse('http://example.com/'))
    allowable.should be_false
  end

  it 'should support multiple url_checks' do
    @first_url_check = false
    @second_url_check = false
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.add_url_check do |a_url|
      @first_url_check = true
      true
    end
    si.add_url_check do |a_url|
      @second_url_check = true
      false
    end
    allowable = si.allowable_url?('http://example.com/',
                                  URI.parse('http://example.com/'))
    allowable.should be_false
    @first_url_check.should be_true
    @second_url_check.should be_true
  end

  it 'should avoid cycles' do
    u = 'http://example.com/'
    u_p = URI.parse(u)
    si = SpiderInstance.new({nil => [u]}, [u_p])
    si.stubs(:allowed?).returns(true)
    allowable = si.allowable_url?(u, u_p)
    allowable.should be_false
    u_p.should_not be_nil
  end

  it 'should call the 404 handler for 404s' do
    @proc_called = false
    mock_failed_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(404) {|*a| @proc_called = true}
    si.start!
    @proc_called.should be_true
  end

  it 'should call the :success handler on success' do
    @proc_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:success) {|*a| @proc_called = true}
    si.start!
    @proc_called.should be_true
  end

  it 'should not call the :success handler on failure' do
    @proc_called = false
    mock_failed_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:success) {|*a| @proc_called = true}
    si.start!
    @proc_called.should be_false
  end

  it 'should call the :success handler and the 200 handler on 200' do
    @proc_200_called = false
    @proc_success_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:success) {|*a| @proc_success_called = true}
    si.on(200)      {|*a| @proc_200_called     = true}
    si.start!
    @proc_200_called.should be_true
    @proc_success_called.should be_true
  end

  it 'should not call the :failure handler on success' do
    @proc_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:failure) {|*a| @proc_called = true}
    si.start!
    @proc_called.should be_false
  end

  it 'should call the :failure handler on failure' do
    @proc_called = false
    mock_failed_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:failure) {|*a| @proc_called = true}
    si.start!
    @proc_called.should be_true
  end

  it 'should call the :failure handler and the 404 handler on 404' do
    @proc_404_called = false
    @proc_failure_called = false
    mock_failed_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:failure) {|*a| @proc_failure_called = true}
    si.on(404) {|*a| @proc_404_called = true}
    si.start!
    @proc_404_called.should be_true
    @proc_failure_called.should be_true
  end

  it 'should call the :every handler even when a handler for the error code is defined' do
    @any_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:every) { |*a| @any_called = true }
    si.on(202) {|*a|}
    si.start!
    @any_called.should be_true
  end

  it 'should support a block as a response handler' do
    @proc_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:every) { |*a| @proc_called = true }
    si.start!
    @proc_called.should be_true
  end

  it 'should support a proc as a response handler' do
    @proc_called = false
    mock_successful_http
    si = SpiderInstance.new({nil => ['http://example.com/']})
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(:every, Proc.new { |*a| @proc_called = true })
    si.start!
    @proc_called.should be_true
  end

  def mock_http(http_req)
    http_obj = mock(:use_ssl= => true)
    http_obj.expects(:start).
      yields(mock(:request => http_req)).returns(http_req)
    Net::HTTP.expects(:new).returns(http_obj)
  end

  def mock_successful_http
    http_req = stub(:redirect? => false, :success? => true, :code => 200, :body => 'body')
    mock_http(http_req)
  end

  def mock_failed_http
    http_req = stub(:redirect? => false, :success? => false, :code => 404)
    mock_http(http_req)
  end

  def mock_redirect_http
    http_req = stub(:redirect? => true, :success? => false, :code => 404)
    http_req.expects(:[]).with('Location').returns('http://example.com/')
    http_req2 = stub(:redirect? => false, :success? => true, :code => 200)
    http_obj = mock(:use_ssl= => true)
    http_obj.expects(:start).
      yields(mock(:request => http_req)).returns(http_req)
    http_obj2 = mock(:use_ssl= => true)
    http_obj2.expects(:start).
      yields(mock(:request => http_req2)).returns(http_req2)
    Net::HTTP.expects(:new).times(2).returns(http_obj).then.returns(http_obj2)
  end

  def callback_arguments_on(code)
    si = SpiderInstance.new('http://foo.com/' => ['http://example.com/'])
    si.stubs(:allowed?).returns(true)
    si.stubs(:generate_next_urls).returns([])
    si.on(code) do |a_url, resp, prior_url|
      a_url.should == 'http://example.com/'
      resp.should_not be_nil
      prior_url.should == 'http://foo.com/'
    end
    si.start!
  end

  def it_should_prevent_cycles_with(cacher)
    u = 'http://localhost:8888/'
    u_p = URI.parse(u)
    u2 = 'http://localhost:8888/foo'
    u_p2 = URI.parse(u2)

    with_web_server(LoopingServlet) do
      si = SpiderInstance.new(nil => [u])
      si.check_already_seen_with cacher
      si.start!
    end
  end
end
