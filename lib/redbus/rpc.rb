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
