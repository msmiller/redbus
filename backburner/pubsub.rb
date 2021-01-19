#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-16 13:24:00
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-31 10:43:43
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# This is for pub/sub and wait with specific messages

# NOTE: This was the first incarnation. But it wouldn't work well with a deployment
# where there were multiple instances per process type (i.e. event would get published
# to every instance, not just one per process type). It will later be resurrected for
# cases where people may want a simpler configuration.

module Redbus
  class Pubsub

    # Fire-and-forget publish
    def self.publish(channels, data)
      channels.gsub(/\s+/, "").split(',').each do |c|
        $pubredis.publish c, data.to_json
      end
    end

    # Synchronous subscribe
    def self.subscribe(channels, callback=nil)
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

    # Synchronous psubscribe
    def self.psubscribe(pattern, callback=nil)
      $subredis.psubscribe(pattern) do |on|
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
