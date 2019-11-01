#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 13:24:00
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-01 12:00:41
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

require 'yaml'

class RedisBus

  # ########
  # The topology config loads the endpoints and interests for a multi-app/service
  # system from a YAML file. This will perform a bit better

  def load_topology
    if Rails.env == 'test'
      topopath = File.expand_path("../../../spec/#{@topology_cfg}", __FILE__)
    else
      topopath = Rails.root.join('config', @topology_cfg)
    end
    @topology = YAML.load( File.read(topopath)  )
  end

  # ########
  # Endpoints are for direct message requests. Such as "tell the mail-sender to send an email"

  # This returns a list of the endpoint keys
  def registered_endpoints
    @topology.keys
  end

  # ########
  # Interests are for fan-out receipt of things a service may be interested in.
  # For instance "I want to know when something happens to Users"

  # This returns a list of the interests keys
  def registered_interests(channel)
    if channel.nil?
      intlist = @topology[@endpoint]['interests']
    else
      intlist = @topology[channel]['interests']
    end
    return intlist || []
  end

  # ########
  # Gather up all the registered things as a key list for BLPOP
  #
  # Note that the interests create different channels for each endpoint. So if your endpoint is "foo",
  # and you're registering interest in "bar", the channel will be "#foo_bar".

  def subscribe_list(channel=nil)
    ep = channel || @endpoint
    endpoints = [ "@#{ep}"]
    interests = registered_interests(ep).map { |k| interest_hash_tag(ep, k) }

    return(endpoints + interests)
  end

  # ########
  # Build the fan-out list to LPUSH to for an interest
  def fanout_list(interest)
    interests = @topology.keys.delete_if { |k| !(@topology[k]['interests'] || []).include?(interest) }
    return(interests.map { |k| interest_hash_tag(k, interest) })
  end

  # Utility

  def interest_hash_tag(channel, interest)
    "##{interest}_#{channel}"
  end

end
