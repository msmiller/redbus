require 'redbus/version'
require "redis-objects"
require 'securerandom'

require 'redbus/support'

module Redbus

  include Redis::Objects

  class Error < StandardError; end
  # Your code goes here...

end
