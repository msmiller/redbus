#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 13:24:00
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-31 10:43:43
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# This is the main way to listen to a bus

# NOTE: This goes with the original PUBSUB implimentation

module Redbus
  class Async

    # Asynchronous subscribe
    def self.subscribe_async(channels, callback=nil)
      Thread.new do
        $subredis.subscribe(channels) do |on|
          on.message do |channel, msg|
            data = JSON.parse(msg)
            if callback.nil?
              dump_message(channel, msg)
            else
              eval("#{callback}(channel, msg)")
            end
          end
        end
      end
    end

    # Asynchronous psubscribe
    def self.psubscribe_async(pattern, callback=nil)
      Thread.new do
        tredis = Redis.new
        tredis.psubscribe(pattern) do |on|
          on.pmessage do |pattern, channel, msg|
            data = JSON.parse(msg)
            if callback.nil?
              dump_message(channel, msg)
            else
              eval("#{callback}(channel, msg)")
            end
          end
        end
      end
    end

  end
end
