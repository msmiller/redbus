require 'securerandom'
require 'json'
require 'active_support/inflector'

require "redis-objects"

require 'redbus/version'
require 'redbus/support'
require 'redbus/registration'
require 'redbus/lpubsub'

module Redbus

  include Redis::Objects

  @@endpoint = "redbus#{rand(1000...9999)}"
  @@poll_delay = 0
  @@timeout = 5

  def self.endpoint
    @@endpoint
  end

  def self.endpoint=(s)
    @@endpoint = s
  end

  def self.poll_delay
    @@poll_delay
  end

  def self.poll_delay=(i)
    @@poll_delay = i
  end

  def self.timeout
    @@timeout
  end

  def self.timeout=(i)
    @@timeout = i
  end

  class Error < StandardError; end
  # Your code goes here...

end
