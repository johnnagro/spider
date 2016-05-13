# Use AmazonSQS to track nodes to visit.

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
