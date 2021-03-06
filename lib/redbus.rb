#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 12:44:09
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-04 12:55:41
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
  DEFAULT_POLL_DELAY = 1
  DEFAULT_TIMEOUT = 5

  class RedisBus

    @gather_stats =  false
    @redis_url =     ""
    @endpoint =      "redbus#{rand(1000...9999)}"
    @poll_delay =    Redbus::DEFAULT_POLL_DELAY     # This throttles how often to ping Redbus when it's empty (fixnum:seconds)
    @timeout =       Redbus::DEFAULT_TIMEOUT        # This is the timeout for subscribe_once (fixnum:seconds)
    @topology_cfg =  nil                            # If you want to load the topology from a common YAML file

    @topology = {}

    @busredis = nil
    @pubredis = nil
    @subredis = nil

    attr_accessor :endpoint, :poll_delay, :timeout, :topology_cfg, :topology, :busredis, :pubredis, :subredis, :redis_url, :gather_stats

    def initialize(endpoint, topology_cfg, redis_url=nil)
      @gather_stats = false
      @endpoint = endpoint
      @topology_cfg = topology_cfg
      @poll_delay = Redbus::DEFAULT_POLL_DELAY
      @timeout = Redbus::DEFAULT_TIMEOUT
      @topology = {}
      if redis_url.nil?
        @busredis = Redis.new
        @pubredis = Redis.new
        @subredis = Redis.new
      else
        @redis_url = redis_url
        @busredis = Redis.new(url: redis_url)
        @pubredis = Redis.new(url: redis_url)
        @subredis = Redis.new(url: redis_url)
      end
      self.load_topology unless @topology_cfg.nil?
    end

    def self.channel_is_endpoint?(c)
      '@' == c[0]
    end

    def self.channel_is_interest?(c)
      '#' == c[0]
    end

    def close_redis
      self.busredis.close
      self.pubredis.close
      self.subredis.close
    end

  end

end

class RedBus < Redbus::RedisBus
end
