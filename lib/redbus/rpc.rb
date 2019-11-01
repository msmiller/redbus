#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-08-23 12:58:57
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-01 13:32:46
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

# Since this is a point-to-point one-shot event, just use basic Redis pubsub

class RedisBus

  RPC_DEBUG_ON = true

  # Publish a message and wait on a reply
  def publish_rpc(channel, data)
    return(nil) if !RedisBus.channel_is_endpoint?(channel)
    rpc_token = "rpc." + SecureRandom.urlsafe_base64(nil, false)
    Thread.new do
      sleep(0.1) # Give it a tick to let the subscribe code start running
      # We use the list-based publish here so that it only gets picked up by one worker on the endpoint
      self.publish channel, data.merge( {rpc_token: rpc_token} )
    end

    # See: https://github.com/redis/redis-rb#timeouts
    if redis_url.nil?
      rpc_redis = Redis.new
    else
      rpc_redis = Redis.new(url: self.redis_url)
    end

    begin
      # Since we're only expecting one response on a unique key, we can use generic pubsub
      rpc_redis.subscribe_with_timeout(self.timeout, rpc_token) do |on|
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
