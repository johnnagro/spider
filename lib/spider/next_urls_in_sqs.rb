# Use AmazonSQS to track nodes to visit.
#
# Copyright 2008 John Nagro
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

require 'rubygems'
require 'right_aws'
require 'yaml'

# A specialized class using AmazonSQS to track nodes to walk. It supports
# two operations: push and pop . Together these can be used to 
# add items to the queue, then pull items off the queue.
#
# This is useful if you want multiple Spider processes crawling the same
# data set.
#
# To use it with Spider use the store_next_urls_with method:
#
#  Spider.start_at('http://example.com/') do |s|
#    s.store_next_urls_with NextUrlsInSQS.new(AWS_ACCESS_KEY, AWS_SECRET_ACCESS_KEY, queue_name)
#  end
class NextUrlsInSQS
  # Construct a new NextUrlsInSQS instance. All arguments here are
  # passed to RightAWS::SqsGen2 (part of the right_aws gem) or used
  # to set the AmazonSQS queue name (optional).
  def initialize(aws_access_key, aws_secret_access_key, queue_name = 'ruby-spider')
    @sqs = RightAws::SqsGen2.new(aws_access_key, aws_secret_access_key)
    @queue = @sqs.queue(queue_name)
  end
  
  # Pull an item off the queue, loop until data is found. Data is 
  # encoded with YAML.
  def pop
    while true
      message = @queue.pop
      return YAML::load(message.to_s) unless message.nil?
      sleep 5
    end
  end
  
  # Put data on the queue. Data is encoded with YAML.
  def push(a_msg)
    encoded_message = YAML::dump(a_msg)
    @queue.push(a_msg)
  end  
end