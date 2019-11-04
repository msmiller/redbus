#!/usr/bin/ruby
# @Author: msmiller
# @Date:   2019-09-12 13:49:17
# @Last Modified by:   msmiller
# @Last Modified time: 2019-11-04 11:01:57
#
# Copyright (c) Sharp Stone Codewerks / Mark S. Miller

module Redbus

  class RedisBus

    CACHETHRU_DEBUG_ON = true

      def self._base_redis_key(item)
        if item.is_a? Hash
          "#{item[:class]}.#{item[:id]}"
        else
          "#{item.class}.#{item.id}"
        end
      end

      def self._redis_key(item)
        "#{Redbus::CACHETHRU_KEY_ROOT}.#{_base_redis_key(item)}"     
      end

      # Store an object out in Redis for temporary persistence and respond back if there's an rpc_token
      # - This will be called by the responding service!
      # - Skip the rpc_token if you want to pre-load something into the cache
      # - Optional serialized lets you customize what to send, like output from a Serializer
      def deposit(item, rpc_token=nil, expire_at=nil, serialized=nil)
        base_redis_key = RedBus::_base_redis_key(item)
        redis_key = RedBus::_redis_key(item)
        if serialized.is_a?(String) # which also means !nil?
          @json_hash = self.busredis.set(redis_key, serialized)
        else
          @json_hash = self.busredis.set(redis_key, item.to_json)
        end
        if expire_at
          self.busredis.expireat "#{Redbus::CACHETHRU_KEY_ROOT}:#{redis_key}", expire_at
        end
        # Publish back an acknowledge that it's ready so the requester can get the data
        if rpc_token
          self.pubredis.publish rpc_token, { redis_key: base_redis_key }.to_json
        end
      end

      # Pull an object that's being persisted, if it's not there, do an RPC publish to get it
      #
      # This returns an OpenStruct representation of the object, so you can work with it
      # to get attributes more or less as usual, but things like associations will require
      # building an object off of the result.to_h
      def retrieve(item_class, item_id, channel, expire_at=nil)
        return(nil) if !RedBus.channel_is_endpoint?(channel)
        base_redis_key = RedBus::_base_redis_key( {class: item_class, id: item_id} )
        redis_key = RedBus::_redis_key( {class: item_class, id: item_id} )

        @json_hash = self.busredis.get(redis_key)
        # If the object doesn't exist, then request it over RPC
        if @json_hash.nil? || @json_hash.value.nil? || @json_hash.value.empty?
          data = { message: 'deposit', item_class: item_class, item_id: item_id, expire_at: expire_at }
          result = self.publish_rpc(channel, data)
          # Reload the hash from Redis
          @json_hash = self.busredis.get(redis_key)
        end

        # p "retrieve: #{JSON.parse(@json_hash)}"
        return OpenStruct.new(JSON.parse(@json_hash)) #.to_dot
      end

      # Remove something from the cachethru so it can be re-acquired ... or just to clean up
      def cremove(item_class, item_id)
        base_redis_key = RedBus::_base_redis_key( {class: item_class, id: item_id} )
        redis_key = RedBus::_redis_key( {class: item_class, id: item_id} )
        return self.busredis.del(redis_key)
      end

  end

end
