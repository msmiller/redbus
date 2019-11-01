#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 12:44:09
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-31 16:29:17
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

require 'securerandom'
require 'json'
require 'active_support/inflector'

require 'redbus/version'
require 'redbus/support'
require 'redbus/topology'
require 'redbus/lpubsub'
require 'redbus/stats'
require 'redbus/rpc'
require 'redbus/cachethru'

module Redbus

  class Error < StandardError; end

  CACHETHRU_KEY_ROOT = "redbuscache"

end

class RedisBus

  @endpoint =      "redbus#{rand(1000...9999)}"
  @poll_delay =    1     # This throttles how often to ping Redbus when it's empty (fixnum:seconds)
  @timeout =       5     # This is the timeout for subscribe_once (fixnum:seconds)
  @topology_cfg =  nil   # If you want to load the topology from a common YAML file

  @topology = {}

  @busredis = nil
  @pubredis = nil
  @subredis = nil

  attr_accessor :endpoint, :poll_delay, :timeout, :topology_cfg, :topology, :busredis, :pubredis, :subredis

  def initialize(endpoint, topology_cfg, redis_url=nil, poll_delay=1, timeout=5)
    @endpoint = endpoint
    @topology_cfg = topology_cfg
    @poll_delay = poll_delay
    @timeout = timeout
    @topology = {}
    if redis_url.nil?
      @busredis = Redis.new
      @pubredis = Redis.new
      @subredis = Redis.new
    else
      @busredis = Redis.new(url: redis_url)
      @pubredis = Redis.new(url: redis_url)
      @subredis = Redis.new(url: redis_url)
    end
    load_topology unless @topology_cfg.nil?
  end

  def self.channel_is_endpoint?(c)
    '@' == c[0]
  end

  def self.channel_is_interest?(c)
    '#' == c[0]
  end

  #### PUBLIC FUNCTIONS

  def self.publish(channels, data)
    Redbus::Lpubsub.publish(channels, data)
  end

  def self.subscribe_once(channel, callback=nil)
    Redbus::Lpubsub.subscribe_once(channel, callback)
  end

  def self.subscribe_async(channels, callback=nil)
    Redbus::Lpubsub.subscribe_async(channels, callback)
  end

  def self.subscribe_all(callback=nil)
    Redbus::Lpubsub.subscribe_all(callback)
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