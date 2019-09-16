#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 12:44:09
# @Last Modified by:   msmiller
# @Last Modified time: 2019-09-16 14:15:05
#
# Copyright (c) 2017-2018 Sharp Stone Codewerks / Mark S. Miller

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

  def self.subscribe_async(channels, callback=nil)
    PUBLISH_MODE.subscribe_async(channels, callback)
  end

  def self.subscribe_all(callback=nil)
    PUBLISH_MODE.subscribe_all(callback)
  end

  #### END PUBLIC FUNCTIONS

end
