#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 12:44:09
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-30 13:05:02
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

require 'securerandom'
require 'json'
require 'active_support/inflector'

require 'redbus/version'
require 'redbus/support'
require 'redbus/registration'
require 'redbus/lpubsub'
require 'redbus/stats'
require 'redbus/rpc'
require 'redbus/cachethru'

module Redbus

  @@endpoint =      "redbus#{rand(1000...9999)}"
  @@poll_delay =    1     # This throttles how often to ping Redbus when it's empty (fixnum:seconds)
  @@timeout =       5     # This is the timeout for subscribe_once (fixnum:seconds)
  @@topology_cfg =  nil   # If you want to load the topology from a common YAML file

  @@topology = {}

  # Use this to switch between LIST-based and traditional PUBSUB-based
  # Note: for now the PUBSUB code is unsupported
  PUBLISH_MODE = Redbus::Lpubsub
  CACHETHRU_KEY_ROOT = "redbuscache"

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

  def self.topology_cfg
    @@topology_cfg
  end

  def self.topology_cfg=(i)
    @@topology_cfg = i
  end

  def self.topology
    @@topology
  end

  def self.topology=(i)
    @@topology = i
  end

  #### END CONFIG VARIABLES

  def self.channel_is_endpoint?(c)
    '@' == c[0]
  end

  def self.channel_is_interest?(c)
    '#' == c[0]
  end

  #### PUBLIC FUNCTIONS

  def self.publish(channels, data)
    PUBLISH_MODE.publish(channels, data)
  end

  def self.subscribe_once(channel, callback=nil)
    PUBLISH_MODE.subscribe_once(channel, callback)
  end

  def self.subscribe_async(channels, callback=nil)
    PUBLISH_MODE.subscribe_async(channels, callback)
  end

  def self.subscribe_all(callback=nil)
    PUBLISH_MODE.subscribe_all(callback)
  end

  ###

  def self.retrieve(item_class, item_id, channel, expire_at=nil)
    Redbus::Cachethru.retrieve(item_class, item_id, channel, expire_at=nil)
  end

  def self.deposit(item, rpc_token=nil, expire_at=nil)
    Redbus::Cachethru.deposit(item, rpc_token, expire_at=nil)
  end

  def self.cremove(item_class, item_id)
    Redbus::Cachethru.remove(item_class, item_id)
  end

  #### END PUBLIC FUNCTIONS

end
