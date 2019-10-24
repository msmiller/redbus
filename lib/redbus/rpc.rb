#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-08-23 12:58:57
# @Last Modified by:   msmiller
# @Last Modified time: 2019-10-24 12:54:09
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# Since this is a point-to-point one-shot event, just use basic Redis pubsub

module Redbus
  class Rpc

    # Publish a message and wait on a reply
    def self.publish_rpc(channel, data)
      rpc_token = "rpc." + SecureRandom.urlsafe_base64(nil, false)
      Thread.new do
        sleep(0.1) # Give it a tick to let the subscribe code start running
        # We use the list-based publish here so that it only gets picked up by one worker on the endpoint
        Redbus::Lpubsub.publish channel, data.merge( {rpc_token: rpc_token} )
      end

      # See: https://github.com/redis/redis-rb#timeouts
      rpc_redis = Redis.new
      begin
        # Since we're only expecting one response on a unique key, we can use generic pubsub
        rpc_redis.subscribe_with_timeout(Redbus.timeout, rpc_token) do |on|
          on.message do |channel, msg|
            data = JSON.parse(msg)
            rpc_redis.unsubscribe(rpc_token) # if it times out, no need to unsub elsewhere
            rpc_redis.close
            return(data)
          end
        end
      rescue
        rpc_redis.close
        return {}
      end

      rpc_redis.close
      return {}
    end

  end
end
