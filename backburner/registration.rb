#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 13:24:00
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-31 10:43:43
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# NOTE: Old registartion code - this has been since superceded 

require 'yaml'

module Redbus
  class Registration

    # ########
    # The topology config loads the endpoints and interests for a multi-app/service
    # system from a YAML file. This will perform a bit better

    def self.load_topology(topology_yaml)
      Redbus.topology_cfg = topology_yaml
      if Rails.env == 'test'
        topopath = File.expand_path("../../../spec/#{topology_yaml}", __FILE__)
      else
        topopath = Rails.root.join('config', topology_yaml)
      end
      Redbus.topology = YAML.load( File.read(topopath)  )
    end

    # ########
    # Endpoints are for direct message requests. Such as "tell the mail-sender to send an email"

    # The default here is to register the current instance's config'd endpoint - which will be
    # the case most of the time.
    def self.register_endpoint(name = "@#{Redbus.endpoint}")
      $busredis.set("endpoints:#{name}", Time.now)
    end

    # TODO: self.unregister_endpoint(name = "@#{Redbus.endpoint}")

    # This returns a list of the endpoint keys
    def self.registered_endpoints
      $busredis.keys("endpoints:*").map{ |ep| key_to_endpoint(ep) }
    end

    # This is a hash which includes the timestamp the endpoint was registered at
    def self.endpoint_registrations
      result = {}
      $busredis.keys("endpoints:*").map{ |ep| result[key_to_endpoint(ep)] = $busredis.get(ep) }
      return result
    end

    # ########
    # Interests are for fan-out receipt of things a service may be interested in.
    # For instance "I want to know when something happens to Users"

    def self.register_interest(name)
      $busredis.set("interests:#{name}:#{Redbus.endpoint}", Time.now)
    end

    # This returns a list of the interests keys
    def self.registered_interests
      $busredis.keys("interests:*:#{Redbus.endpoint}").map{ |ip| key_to_interest(ip) }
    end

    # This returns a list of the interests keys
    def self.registered_channel_interests(channel)
      $busredis.keys("interests:#{channel}:*").map{ |ip| key_to_interest(ip) }
    end

    # This is a hash which includes the timestamp the interests was registered at
    def self.interest_registrations
      result = {}
      $busredis.keys("interests:*:#{Redbus.endpoint}").map{ |ip| result[key_to_interest(ip)] = $busredis.get(ip) }
      return result
    end

    # ########
    # Gather up all the registered things as a key list for BLPOP
    #
    # Note that the interests create different channels for each endpoint. So if your endpoint is "foo",
    # and you're registering interest in "bar", the channel will be "#foo_bar".

    def self.subscribe_list
      # THIS FIRST LINE IS WHAT IT SHOULD BE IN REAL
      endpoints = [ key_to_endpoint("@#{Redbus.endpoint}")] #registered_endpoints
      endpoints = registered_endpoints
      # interests = registered_interests.map { |k| "#{k}_#{Redbus.endpoint}" }
      interests = registered_interests #.map { |k| "#{k}_#{Redbus.endpoint}" }

      return(endpoints + interests)
    end

    # ########
    # Build the fan-out list to LPUSH to for an interest
    def self.fanout_list(channel)
      interests = registered_channel_interests(channel)
      return(interests)
    end

    # Utils

    def self.clear_registrations
      $busredis.keys("endpoints:*").each{ |k| $busredis.del(k) }
      $busredis.keys("interests:*").each{ |k| $busredis.del(k) }
    end

    # admin function for namespace changes
    def self.remove_endpoint_regs(endpoint_name)
      $busredis.keys("endpoints:#{endpoint_name}").each{ |k| $busredis.del(k) }
      $busredis.keys("interests:*:#{endpoint_name}").each{ |k| $busredis.del(k) }
    end

    def self.key_to_endpoint(k)
      k.to_s.gsub('endpoints:', '')
    end

    def self.key_to_interest(k)
      keyarray = k.split(':')
      "#{keyarray[1]}_#{keyarray[2]}"
      # was:
      # k.to_s.gsub('interests:', '').gsub(":#{Redbus.endpoint}", '')
    end

  end
end
