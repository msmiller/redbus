module Redbus
  class CacheThru

    def self._base_redis_key(item)
      "#{item[:class] || item.class}.#{item.id}"
    end

    def self._redis_key(item)
      "magicache.#{_base_redis_key(item)}"
    end


    # Store an object out in Redis for temporary persistence and respond back if there's an rpc_token
    def self.deposit(item, expire_at, rpc_token)
      base_redis_key = _base_redis_key(item)
      redis_key = _redis_key(item)
      @hash = Redis::HashKey.new(redis_key)
      item.each do |k,v|
        @hash[k] = v
      end
      if expire_at
        $redis.expireat "magicbus:#{redis_key}", expire_at
      end
      # Publish back an acknowledge that it's ready so the requester can get the data
      if rpc_token
        $pubredis.publish rpc_token, { redis_key: base_redis_key }.to_json
      end
    end

    # Pull an object that's being persisted, if it's not there, do an RPC publish to get it
    def self.retrieve(item_class, item_id, channel, expire_at=nil)
      base_redis_key = "#{item_class}.#{item_id}"
      redis_key = "magicache.#{base_redis_key}"

      @hash = Redis::HashKey.new(redis_key)
      # If the object doesn't exist, then request it over RPC
      if @hash.nil? || @hash.value.nil? || @hash.value.empty?
        data = { message: 'deposit', item_class: item_class, item_id: item_id, expire_at: expire_at }
        result = publish_rpc(channel, data)
        # Reload the hash from Redis
        @hash = Redis::HashKey.new(redis_key)
      end

      ap @hash.value
      return @hash.value.to_dot
    end

  end
end
