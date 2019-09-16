#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-08-23 12:58:57
# @Last Modified by:   msmiller
# @Last Modified time: 2019-09-16 14:21:35
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

module Redbus
  class Rpc

    # Publish a message and wait on a reply
    def self.publish_rpc(channel, data)
      rpc_token = "rpc." + SecureRandom.urlsafe_base64(nil, false)
      $pubredis.publish channel, data.merge( {rpc_token: rpc_token} ).to_json

      # See: https://github.com/redis/redis-rb#timeouts
      rpc_redis = Redis.new
      rpc_redis.subscribe_with_timeout(5, rpc_token) do |on|
        on.message do |channel, msg|
          data = JSON.parse(msg)
          rpc_redis.unsubscribe(rpc_token)
          rpc_redis.close
          return(data)
        end
      end

      rpc_redis.unsubscribe(rpc_token)
      rpc_redis.close
      return nil
    end

  end
end
