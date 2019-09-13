require 'securerandom'
require 'json'
require 'active_support/inflector'

require 'redbus/version'
require 'redbus/support'
require 'redbus/registration'
require 'redbus/lpubsub'
require 'redbus/stats'

module Redbus

  @@endpoint = "redbus#{rand(1000...9999)}"
  @@poll_delay = 0
  @@timeout = 5

  # Use this to switch between LIST-based and traditional PUBSUB-based
  # Note: for now the PUBSUB code is unsupported
  PUBLISH_MODE = Redbus::Lpubsub

  class Error < StandardError; end

  #### CONFIG VARIABLES

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

  #### END CONFIG VARIABLES

  #### PUBLIC FUNCTIONS

  def self.publish(channels, data)
    PUBLISH_MODE.publish(channels, data)
  end

  def self.subscribe_once(channel, callback=nil)
    PUBLISH_MODE.subscribe_once(channel, callback)
  end

  #### END PUBLIC FUNCTIONS

end
